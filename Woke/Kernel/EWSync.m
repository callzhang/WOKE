//
//  EWSync.m
//  Woke
//
//  Created by Lee on 9/24/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWSync.h"
#import "EWDataStore.h"
#import "EWUserManagement.h"
#import "EWPersonStore.h"
#import "EWMediaStore.h"
#import "EWTaskStore.h"
#import "EWAlarmManager.h"
#import "EWWakeUpManager.h"
#import "EWServer.h"
#import "EWTaskItem.h"
#import "EWMediaItem.h"
#import "EWNotification.h"
#import "EWUIUtil.h"
#import "EWStatisticsManager.h"
#import "NSManagedObject+Parse.h"
#import "PFObject+EWSync.h"


#pragma mark -
#define kServerTransformTypes               @{@"CLLocation": @"PFGeoPoint"} //localType: serverType
#define kServerTransformClasses             @{@"EWPerson": @"_User"} //localClass: serverClass
#define kUserClass                          @"EWPerson"
//#define classSkipped                        @[@"EWPerson"]
#define attributeUploadSkipped              @[kParseObjectID, kUpdatedDateKey, @"score"]


//============ Global shortcut to main context ===========
NSManagedObjectContext *mainContext;
//=======================================================

@interface EWSync(){
	NSMutableDictionary *workingChangedRecords;
}
@property NSManagedObjectContext *context; //the main context(private), only expose 'currentContext' as a class method
@property NSMutableDictionary *parseSaveCallbacks;
@property (nonatomic) NSTimer *saveToServerDelayTimer;
@property NSMutableArray *saveToLocalItems;
@property NSMutableArray *deleteToLocalItems;
//@property (nonatomic) NSMutableDictionary *changesDictionary;
@end


@implementation EWSync
@synthesize context;
@synthesize parseSaveCallbacks;
@synthesize isUploading = _isUploading;


- (void)setup{
    
    //server: enable alert when offline
    [Parse errorMessagesEnabled:YES];
    
    //Access Control: enable public read access while disabling public write access.
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    //core data
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Woke"];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelWarn];
    context = [NSManagedObjectContext defaultContext];
    mainContext = context;
    
    //observe context change to update the modifiedData of that MO. (Only observe the main context)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preSaveAction:) name:NSManagedObjectContextWillSaveNotification object:context];
    
    //Observe background context saves so main context can perform upload
    //We don't need to merge child context change to main context
    //It will cause errors when main and child context access same MO
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:context queue:nil usingBlock:^(NSNotification *note) {
        
        [_saveToServerDelayTimer invalidate];
        _saveToServerDelayTimer = [NSTimer scheduledTimerWithTimeInterval:kUploadLag target:self selector:@selector(updateToServer) userInfo:nil repeats:NO];
    }];
    
    //Reachability
    self.reachability = [Reachability reachabilityForInternetConnection];
    self.reachability.reachableBlock = ^(Reachability *reachability) {
        NSLog(@"====== Network is reachable. Start upload. ======");
        //in background thread
        [EWSync resumeUploadToServer];
        
        //resume refresh MO
        NSSet *MOs = [EWSync getObjectFromQueue:kParseQueueRefresh];
        for (NSManagedObject *MO in MOs) {
            [MO refreshInBackgroundWithCompletion:^{
                NSLog(@"%@(%@) refreshed after network resumed.", MO.entity.name, MO.serverID);
            }];
        }
    };
    self.reachability.unreachableBlock = ^(Reachability * reachability){
        NSLog(@"====== Network is unreachable ======");
        [EWUIUtil showHUDWithString:@"Offline"];
    };
    
    //facebook
    [PFFacebookUtils initializeFacebook];
    
    //watch for login event
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDataCheck) name:kPersonLoggedIn object:Nil];
    
    //initial property
    self.parseSaveCallbacks = [NSMutableDictionary dictionary];
    self.saveCallbacks = [NSMutableArray new];
    self.saveToLocalItems = [NSMutableArray new];
    self.deleteToLocalItems = [NSMutableArray new];
    self.serverObjectPool = [NSMutableDictionary new];
    self.changeRecords = [NSMutableDictionary new];
    
}

#pragma mark - Core Data
+ (NSManagedObject *)managedObjectInContext:(NSManagedObjectContext *)context withID:(NSManagedObjectID *)objectID{
    
    if (objectID == nil) {
        NSLog(@"!!! Passed in nil to get current MO");
        return nil;
    }
	
	if (objectID.isTemporaryID) {
		NSLog(@"*** Temporary ID %@ passed in!", objectID);
	}
    
    NSError *error;
    NSManagedObject * obj = [context existingObjectWithID:objectID error:&error];
    if (!obj) {
        NSLog(@"*** Error getting exsiting MO (%@): %@", objectID, error.description);
        return nil;
    }
    return obj;
}

+ (void)save{
	NSAssert([NSThread isMainThread], @"Calling +[EWDataStore save] on background context is not allowed. Use [context saveToPersistantStoreAndSave] instead");
	if (mainContext.hasChanges) {
		[mainContext saveToPersistentStoreAndWait];
	}
}

+ (void)saveWithCompletion:(EWSavingCallback)block{
	if (![EWSync sharedInstance].context.hasChanges) {
		block();
		return;
	}
    [[EWDataStore sharedInstance].saveCallbacks addObject:block];
    [EWSync save];
}

+ (void)enqueueChangesInContext:(NSManagedObjectContext *)context{
	//BOOL hasChange = NO;
	
    NSSet *updatedObjects = context.updatedObjects;
	NSSet *insertedObjects = context.insertedObjects;
	NSSet *deletedObjects = context.deletedObjects;
	NSSet *objects = [updatedObjects setByAddingObjectsFromSet:insertedObjects];
	
    //for updated mo
    for (NSManagedObject *MO in objects) {
		//check if it's our guy
		if (![MO isKindOfClass:[EWServerObject class]]) {
			continue;
		}
		//First test MO exist
		if (![context existingObjectWithID:MO.objectID error:NULL]) {
			DDLogError(@"*** MO you are trying to modify doesn't exist in the sqlite: %@", MO.objectID);
			continue;
		}
		
		
		//skip if marked save to local
		if ([[EWDataStore sharedInstance].saveToLocalItems containsObject:MO.objectID]) {
			[[EWDataStore sharedInstance].saveToLocalItems removeObject:MO.objectID];
			continue;
		}
		
		BOOL mine = [EWDataStore checkAccess:MO];
		if (!mine) {
			DDLogWarn(@"!!! Skip updating other's object %@ with changes %@", MO.objectID, MO.changedKeys);
			continue;
		}
		
		//Pre-save validate
		BOOL good = [EWDataStore validateMO:MO];
		if (!good) {
			continue;
		}
		
		
		//if last updated doesn't exist, skip
		if (![MO valueForKey:kUpdatedDateKey]){
			//this is MY VALID UPDATED MO but doesn't have updatedAt, should check the cause if it.
			DDLogError(@"*** MO %@(%@) doesn't have updatedAt, check how this object is being updated. Updated keys: %@", MO.entity.name, MO.serverID, MO.changedValues);
		}
		
		if ([insertedObjects containsObject:MO]) {
			//enqueue to insertQueue
			[EWDataStore appendInsertQueue:MO];
			
			//*** we should not add updatedAt here. Two Inserts could be possible: downloaded from server or created here. Therefore we need to add createdAt at local creation point.
			//change updatedAt
			//[MO setValue:[NSDate date] forKeyPath:kUpdatedDateKey];
			continue;
		}
		
		//additional check for updated object
		if ([updatedObjects containsObject:MO]) {
			
			//check if updated keys exist
            NSArray *changedKeys = MO.changedKeys;
            if (changedKeys.count > 0) {
				
				//add changed keys to record
				NSSet *changed = [[EWDataStore sharedInstance].changeRecords objectForKey:MO.serverID] ?:[NSSet new];
				changed = [changed setByAddingObjectsFromArray:changedKeys];
				[[EWDataStore sharedInstance].changeRecords setObject:changed forKey:MO.objectID];
				
				//add to queue
				[EWDataStore appendUpdateQueue:MO];
				
				//change updatedAt
				[MO setValue:[NSDate date] forKeyPath:kUpdatedDateKey];
            }
		}
		
		
    }
	
	for (NSManagedObject *MO in deletedObjects) {
		//check if it's our guy
		if (![MO isKindOfClass:[EWServerObject class]]) {
			continue;
		}
		if ([[EWDataStore sharedInstance].deleteToLocalItems containsObject:MO.serverID]) {
			[EWDataStore removeObjectFromDeleteQueue:[PFObject objectWithoutDataWithClassName:MO.entity.serverClassName objectId:MO.serverID]];
			continue;
		}
		if (MO.serverID) {
			NSLog(@"~~~> MO %@(%@) is going to be DELETED, enqueue PO to delete queue.", MO.entity.name, [MO valueForKey:kParseObjectID]);
			
			PFObject *PO = [PFObject objectWithoutDataWithClassName:MO.entity.serverClassName objectId:MO.serverID];
			
			[[EWDataStore sharedInstance].serverObjectPool removeObjectForKey:MO.serverID];
			
			[EWDataStore appendObjectToDeleteQueue:PO];
		}
	}
    
}

+ (void)saveAllToLocal:(NSArray *)MOs{
	if (MOs.count == 0) {
		return;
	}
    
	//mark MO as save to local
	for (NSManagedObject *mo in MOs) {
		if (mo.objectID.isTemporaryID) {
			[mo.managedObjectContext obtainPermanentIDsForObjects:@[mo] error:NULL];
		}
		[[EWDataStore sharedInstance].saveToLocalItems addObject:mo.objectID];
		
	}
	
	//save to enqueue the updates
	NSManagedObject *anyMO = MOs[0];
	[anyMO.managedObjectContext saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		for (NSManagedObject *mo in MOs) {
			//remove from the update queue
			[EWDataStore removeObjectFromInsertQueue:mo];
			[EWDataStore removeObjectFromUpdateQueue:mo];
			
		}
	}];
}


@end
