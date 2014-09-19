//
//  EWStore.m
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

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


#pragma mark - 
#define kServerTransformTypes               @{@"CLLocation": @"PFGeoPoint"} //localType: serverType
#define kServerTransformClasses             @{@"EWPerson": @"_User"} //localClass: serverClass
#define kUserClass                          @"EWPerson"
//#define classSkipped                        @[@"EWPerson"]
#define attributeUploadSkipped              @[kParseObjectID, kUpdatedDateKey, @"score"]

//============ Global shortcut to main context ===========
NSManagedObjectContext *mainContext;
//=======================================================

@interface EWDataStore(){
	NSMutableDictionary *workingChangedRecords;
}
@property NSManagedObjectContext *context; //the main context(private), only expose 'currentContext' as a class method
@property NSMutableDictionary *parseSaveCallbacks;
@property (nonatomic) NSTimer *saveToServerDelayTimer;
@property NSMutableArray *saveToLocalItems;
@property NSMutableArray *deleteToLocalItems;
//@property (nonatomic) NSMutableDictionary *changesDictionary;
@end

@implementation EWDataStore
@synthesize context;
@synthesize model;
@synthesize dispatch_queue, coredata_queue;
@synthesize lastChecked;
@synthesize parseSaveCallbacks;
@synthesize isUploading = _isUploading;

+ (EWDataStore *)sharedInstance{
    
    static EWDataStore *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWDataStore alloc] init];
    });
    return sharedStore_;
}

- (id)init{
    self = [super init];
    if (self) {
        //dispatch queue
        dispatch_queue = dispatch_queue_create("com.wokealarm.datastore.dispatchQueue", DISPATCH_QUEUE_SERIAL);
        coredata_queue = dispatch_queue_create("com.wokealarm.datastore.coreDataQueue", DISPATCH_QUEUE_CONCURRENT);
        
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
			
			[[EWDataStore sharedInstance].saveToServerDelayTimer invalidate];
			[EWDataStore sharedInstance].saveToServerDelayTimer = [NSTimer scheduledTimerWithTimeInterval:kUploadLag target:self selector:@selector(updateToServer) userInfo:nil repeats:NO];
		}];
		
		//Reachability
		self.reachability = [Reachability reachabilityForInternetConnection];
		self.reachability.reachableBlock = ^(Reachability *reachability) {
			NSLog(@"====== Network is reachable. Start upload. ======");
			//in background thread
			[EWDataStore resumeUploadToServer];
			
			//resume refresh MO
			NSSet *MOs = [EWDataStore getObjectFromQueue:kParseQueueRefresh];
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
    return self;
}

#pragma mark - Property accessors

- (NSDate *)lastChecked{
    NSUserDefaults *defalts = [NSUserDefaults standardUserDefaults];
    NSDate *timeStamp = [defalts objectForKey:kLastChecked];
    return timeStamp;
}

- (void)setLastChecked:(NSDate *)time{
    if (time) {
        NSUserDefaults *defalts = [NSUserDefaults standardUserDefaults];
        [defalts setObject:time forKey:kLastChecked];
        [defalts synchronize];
    }
}

#pragma mark - connectivity
+ (BOOL)isReachable{
	return [EWDataStore sharedInstance].reachability.isReachable;
}

#pragma mark - Login Check
- (void)loginDataCheck{
    NSLog(@"=== [%s] Logged in, performing login tasks.===", __func__);
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (![currentInstallation[kParseObjectID] isEqualToString: me.objectId]){
        currentInstallation[kUserID] = me.objectId;
        currentInstallation[kUsername] = me.username;
        [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"Installation %@ saved", currentInstallation.objectId);
            }else{
                NSLog(@"*** Installation %@ failed to save: %@", currentInstallation.objectId, error.description);
            }
        }];
    };
    
    //continue upload to server if any
    NSLog(@"0. Continue uploading to server");
    [EWDataStore resumeUploadToServer];
	
	//fetch everyone
	NSLog(@"1. Getting everyone");
	[[EWPersonStore sharedInstance] getEveryoneInBackgroundWithCompletion:NULL];
    
    //refresh current user
    NSLog(@"2. Register AWS push key");
    [EWServer registerAPNS];
    
    //check alarm, task, and local notif
    NSLog(@"3. Check alarm");
	[[EWAlarmManager sharedInstance] scheduleAlarm];
    
    //check task
    NSLog(@"4. Start task schedule");
	[[EWTaskStore sharedInstance] scheduleTasksInBackgroundWithCompletion:^{
		[EWPersonStore updateMe];
	}];
	
	NSLog(@"5. Check past task activity");
	[[EWTaskStore sharedInstance] checkPastTasksInBackgroundWithCompletion:NULL];
	
    NSLog(@"4. Check my unread media");//media also will be checked with background fetch
    [[EWMediaStore sharedInstance] checkMediaAssetsInBackground];
    
    //updating facebook friends
    NSLog(@"5. Updating facebook friends");
    [EWUserManagement getFacebookFriends];
    
    //update facebook info
    //NSLog(@"6. Updating facebook info");
    //[EWUserManagement updateFacebookInfo];
	NSLog(@"6. Check scheduled local notifications");
	[EWTaskStore.sharedInstance checkScheduledNotifications];
    
    //Update my relations cancelled here because the we should wait for all sync task finished before we can download the rest of the relation
    //NSLog(@"7. Refresh my relation in background");
    //[EWPersonStore updateMe];
	
	//location
	if (!me.lastLocation) {
		NSLog(@"8. Start location recurring update");
		[EWUserManagement registerLocation];
	}
    
    //update data with timely updates
	//first time
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[@"start_date"] = [NSDate date];
	userInfo[@"count"] = @0;
	self.serverUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:kServerUpdateInterval target:self selector:@selector(serverUpdate:) userInfo:userInfo repeats:YES];
	
}

- (void)serverUpdate:(NSTimer *)timer{

	if (timer) {
		NSInteger count;
		NSDate *start = timer.userInfo[@"start_date"];
		count = [(NSNumber *)timer.userInfo[@"count"] integerValue];
		NSLog(@"=== Server update started at %@ is running for the %ld times ===", start.date2detailDateString, (long)count);
		count++;
		timer.userInfo[@"count"] = @(count);
	}
	
    //services that need to run periodically
    if (!me) {
        return;
    }
    //this will run at the beginning and every 600s
    NSLog(@"Start sync service");
	
	//fetch everyone
	NSLog(@"[1] Getting everyone");
	[[EWPersonStore sharedInstance] getEveryoneInBackgroundWithCompletion:NULL];
	
    //location
    NSLog(@"[2] Start location recurring update");
    [EWUserManagement registerLocation];
    
    //check task
    NSLog(@"[3] Start recurring task schedule");
	[[EWTaskStore sharedInstance] scheduleTasksInBackgroundWithCompletion:^{
		[EWPersonStore updateMe];
	}];
    
    //check alarm timer: alarm time check is done by backgrounding process
    //NSLog(@"[4] Start recurring alarm timer check");
    //[EWWakeUpManager alarmTimerCheck];
    
}



#pragma mark - Core Data Threading
+ (NSManagedObject *)managedObjectInContext:(NSManagedObjectContext *)context withID:(NSManagedObjectID *)objectID{
    
    if (objectID == nil) {
        NSLog(@"!!! Passed in nil to get current MO");
        return nil;
    }
	
	if (objectID.isTemporaryID) {
		NSLog(@"*** Temporary ID %@ passed in!", objectID);
	}
    
//    //get objectID
//    [context performBlockAndWait:^{
//        if (objectID.isTemporaryID) {
//            
//            //need to save the MO to get the ID
//            if ([obj.managedObjectContext isEqual:[EWDataStore sharedInstance].context]) {
//                [EWDataStore saveToLocal:obj];
//            }else{
//                [obj.managedObjectContext saveToPersistentStoreAndWait];
//            }
//        }
//    }];
//    
//    if (!objectID) {
//        NSLog(@"*** failed to get the ID, return UNSAFE MO %@(%@)", obj.entity.name, [obj valueForKey:kParseObjectID]);
//        return obj;
//    }
    
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
	if (![EWDataStore sharedInstance].context.hasChanges) {
		block();
		return;
	}
    [[EWDataStore sharedInstance].saveCallbacks addObject:block];
    [EWDataStore save];
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
			NSLog(@"*** MO you are trying to modify doesn't exist in the sqlite: %@", MO.objectID);
			continue;
		}
		
		
		//skip if marked save to local
		if ([[EWDataStore sharedInstance].saveToLocalItems containsObject:MO.objectID]) {
			continue;
		}
		
		BOOL mine = [EWDataStore checkAccess:MO];
		if (!mine) {
			NSLog(@"!!! Skip updating other's object %@ with changes %@", MO.objectID, MO.changedKeys);
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
			NSLog(@"*** MO %@(%@) doesn't have updatedAt, check how this object is being updated. Updated keys: %@", MO.entity.name, MO.serverID, MO.changedValues);
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

+ (void)saveToLocal:(NSManagedObject *)mo{
	
    //pre save check
    
	//mark MO as save to local
	if (mo.objectID.isTemporaryID) {
		[mo.managedObjectContext obtainPermanentIDsForObjects:@[mo] error:NULL];
	}
	[[EWDataStore sharedInstance].saveToLocalItems addObject:mo.objectID];

    //save to enqueue the updates
    //[EWDataStore enqueueChangesInContext:mo.managedObjectContext];
	//[[EWDataStore sharedInstance].saveToLocalItems removeObject:mo];
	[mo.managedObjectContext saveToPersistentStoreAndWait];
    
    //remove from the update queue
    [EWDataStore removeObjectFromInsertQueue:mo];
    [EWDataStore removeObjectFromUpdateQueue:mo];
    
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
	[anyMO.managedObjectContext saveToPersistentStoreAndWait];
    
	for (NSManagedObject *mo in MOs) {
		
		//remove from the update queue
		[EWDataStore removeObjectFromInsertQueue:mo];
		[EWDataStore removeObjectFromUpdateQueue:mo];
		
	}
    
}

+ (void)deleteToLocal:(PFObject *)PO{
	[[EWDataStore sharedInstance].deleteToLocalItems addObject:PO.objectId];
	
	//remove from the update queue
	[EWDataStore removeObjectFromDeleteQueue:PO];
}

#pragma mark - Core Data Tools


+ (BOOL)validateMO:(NSManagedObject *)mo{
    //validate MO, only used when uploading MO to PO
	BOOL good = [EWDataStore validateMO:mo andTryToFix:NO];
	
	return good;
}

+ (BOOL)validateMO:(NSManagedObject *)mo andTryToFix:(BOOL)tryFix{
	if (!mo) {
		return NO;
	}
	//validate MO, only used when uploading MO to PO
	BOOL good = YES;
	
	if (![mo valueForKey:kUpdatedDateKey] && mo.serverID) {
		NSLog(@"The %@(%@) you are trying to validate haven't been downloaded fully. Skip validating.", mo.entity.name, mo.serverID);
		return NO;
	}
	
    NSString *type = mo.entity.name;
    if ([type isEqualToString:@"EWTaskItem"]) {
        good = [EWTaskStore validateTask:(EWTaskItem *)mo];
		if (!good) {
			if (!tryFix) {
				return NO;
			}
			[mo refresh];
			good = [EWTaskStore validateTask:(EWTaskItem *)mo];
			
		}
    } else if([type isEqualToString:@"EWMediaItem"]){
        good = [EWMediaStore validateMedia:(EWMediaItem *)mo];
		if (!good) {
			if (!tryFix) {
				return NO;
			}
			[mo refresh];
			good = [EWMediaStore validateMedia:(EWMediaItem *)mo];
		}
    }else if ([type isEqualToString:@"EWPerson"]){
        good = [EWPersonStore validatePerson:(EWPerson *)mo];
		if (!good) {
			if (!tryFix) {
				return NO;
			}
			[mo refresh];
			good = [EWMediaStore validateMedia:(EWMediaItem *)mo];
		}
    }else if ([type isEqualToString:@"EWAlarmItem"]){
		good = [EWAlarmManager validateAlarm:(EWAlarmItem *)mo];
		if (!good) {
			if (!tryFix) {
				return NO;
			}
			[mo refresh];
			good = [EWAlarmManager validateAlarm:(EWAlarmItem *)mo];
		}
	}
	if (!good) {
		NSLog(@"*** %@(%@) failed in validation after trying to fix", mo.entity.name, mo.serverID);
	}
	
	return good;

}



+ (BOOL)checkAccess:(NSManagedObject *)mo{
	if (!mo.serverID) {
		return YES;
	}
	
	//first see if cached PO exist
	PFObject *po = [EWDataStore getCachedParseObjectForID:mo.serverID];
	if (po.ACL != nil) {
		BOOL write = [po.ACL getWriteAccessForUser:[PFUser currentUser]] || [po.ACL getPublicWriteAccess];
		return write;
	}
	
	//if no ACL, use MO to determine
	EWPerson *p;
	if ([mo respondsToSelector:@selector(owner)]) {
		p = [mo valueForKey:@"owner"];
		if (!p && [mo respondsToSelector:@selector(pastOwner)]) {
			p = [mo valueForKey:@"pastOwner"];
		}
	}else if ([mo respondsToSelector:@selector(author)]){
		//check author
		p = [mo valueForKey:@"author"];

	}else if ([mo isKindOfClass:[EWPerson class]]) {
		p = (EWPerson *)mo;
	}else{
		//if not, use PO from server
		return YES;
	}
	
	if (p.isMe){
		return YES;
	}
	return NO;
}

+ (NSManagedObject *)getManagedObjectByStringID:(NSString *)stringID{
	NSParameterAssert([NSThread isMainThread]);
	NSManagedObjectID *ID = [mainContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:stringID]];
	NSError *err;
	NSManagedObject *MO = [mainContext existingObjectWithID:ID error:&err];
	if (!MO && err) {
		NSLog(@"*** Failed to get the MO from store: %@", err.description);
	}
	return MO;
}


#pragma mark - Server Updating Queue methods
//update queue
+ (NSSet *)updateQueue{
    return [EWDataStore getObjectFromQueue:kParseQueueUpdate];
}

+ (void)appendUpdateQueue:(NSManagedObject *)mo{
    //queue
    [EWDataStore appendObject:mo toQueue:kParseQueueUpdate];
}

+ (void)removeObjectFromUpdateQueue:(NSManagedObject *)mo{
    [EWDataStore removeObject:mo fromQueue:kParseQueueUpdate];
}

//insert queue
+ (NSSet *)insertQueue{
    return [EWDataStore getObjectFromQueue:kParseQueueInsert];
}

+ (void)appendInsertQueue:(NSManagedObject *)mo{
    [EWDataStore appendObject:mo toQueue:kParseQueueInsert];
}

+ (void)removeObjectFromInsertQueue:(NSManagedObject *)mo{
    [EWDataStore removeObject:mo fromQueue:kParseQueueInsert];
}

//uploading queue
+ (NSSet *)workingQueue{
    return [EWDataStore getObjectFromQueue:kParseQueueWorking];
}

+ (void)appendObjectToWorkingQueue:(NSManagedObject *)mo{
    [EWDataStore appendObject:mo toQueue:kParseQueueWorking];
}

+ (void)removeObjectFromWorkingQueue:(NSManagedObject *)mo{
    [EWDataStore removeObject:mo fromQueue:kParseQueueWorking];
}

//queue functions
+ (NSSet *)getObjectFromQueue:(NSString *)queue{
	NSParameterAssert([NSThread isMainThread]);
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:queue];
	NSMutableArray *validMOs = [array mutableCopy];
    NSMutableSet *set = [NSMutableSet new];
    for (NSString *str in array) {
        NSURL *url = [NSURL URLWithString:str];
        NSManagedObjectID *ID = [[EWDataStore sharedInstance].context.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
        if (!ID) {
            NSLog(@"@@@ ManagedObjectID not found: %@", url);
			//remove from queue
			[validMOs removeObject:str];
			[[NSUserDefaults standardUserDefaults] setObject:[validMOs copy] forKey:queue];
            continue;
        }
		NSError *error;
        NSManagedObject *MO = [[EWDataStore sharedInstance].context existingObjectWithID:ID error:&error];
		if (!error && MO) {
			[set addObject:MO];
		}else{
			NSLog(@"*** Serious error: trying to fetch MO from queue %@ failed. %@", queue, error.description);
			//remove from the queue
			MO = [[EWDataStore sharedInstance].context objectWithID:ID];
			[self removeObject:MO fromQueue:queue];
		}
        
    }
    return [set copy];
}

+ (void)appendObject:(NSManagedObject *)mo toQueue:(NSString *)queue{
//	//check owner
//	if(![queue isEqualToString:kParseQueueRefresh]/* && ![EWDataStore checkAccess:mo]*/){
//		NSLog(@"*** MO %@(%@) doesn't owned by me, skip adding to %@", mo.entity.name, mo.serverID, queue);
//		return;
//	}
	
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:queue];
    NSMutableSet *set = [[NSMutableSet setWithArray:array] mutableCopy]?:[NSMutableSet new];
    NSManagedObjectID *objectID = mo.objectID;
    if ([objectID isTemporaryID]) {
        [mo.managedObjectContext obtainPermanentIDsForObjects:@[mo] error:NULL];
        objectID = mo.objectID;
    }
    NSString *str = objectID.URIRepresentation.absoluteString;
    if (![set containsObject:str]) {
        [set addObject:str];
        [[NSUserDefaults standardUserDefaults] setObject:[set allObjects] forKey:queue];
		if ([queue isEqualToString:kParseQueueInsert]) {
			NSLog(@"+++> MO %@(%@) added to INSERT queue", mo.entity.name, mo.objectID);
		}else if([queue isEqualToString:kParseQueueUpdate]){
			NSLog(@"===> MO %@(%@) added to UPDATED queue with changes: %@", mo.entity.name, [mo valueForKey:kParseObjectID], mo.changedKeys);
		}
		
    }
    
}

+ (void)removeObject:(NSManagedObject *)mo fromQueue:(NSString *)queue{
    NSMutableArray *array = [[[NSUserDefaults standardUserDefaults] valueForKey:queue] mutableCopy];
    NSManagedObjectID *objectID = mo.objectID;
    NSString *str = objectID.URIRepresentation.absoluteString;
    if ([array containsObject:str]) {
        [array removeObject:str];
        [[NSUserDefaults standardUserDefaults] setValue:[array copy] forKey:queue];
        //NSLog(@"Removed object %@ from insert queue", mo.entity.name);
    }
}

+ (void)clearQueue:(NSString *)queue{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:queue];
}

+ (BOOL)contains:(NSManagedObject *)mo inQueue:(NSString *)queue{
	NSMutableArray *array = [[[NSUserDefaults standardUserDefaults] valueForKey:queue] mutableCopy];
	NSString *str = mo.objectID.URIRepresentation.absoluteString;
	BOOL contain = [array containsObject:str];
	return contain;
}

//DeletedQueue underlying is a dictionary of objectId:className
+ (NSSet *)deleteQueue{
    NSDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy];
    NSParameterAssert(!dic || [dic isKindOfClass:[NSDictionary class]]);
    NSMutableSet *set = [NSMutableSet new];
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *ID, NSString *className, BOOL *stop) {
        [set addObject:[PFObject objectWithoutDataWithClassName:className objectId:ID]];
    }];
    return [set copy];
}

+ (void)appendObjectToDeleteQueue:(PFObject *)object{
    if (!object) return;
    NSMutableDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy]?:[NSMutableDictionary new];;
    [dic setObject:object.parseClassName forKey:object.objectId];
    [[NSUserDefaults standardUserDefaults] setObject:[dic copy] forKey:kParseQueueDelete];
}

+ (void)removeObjectFromDeleteQueue:(PFObject *)object{
    if (!object) return;
    NSMutableDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy];
    [dic removeObjectForKey:object.objectId];
    [[NSUserDefaults standardUserDefaults] setObject:[dic copy] forKey:kParseQueueDelete];
}

#pragma mark - Parse helper methods
+ (PFObject *)getCachedParseObjectForID:(NSString *)objectId{
	PFObject *object = [[EWDataStore sharedInstance].serverObjectPool valueForKey:objectId];
	if (object) {
		return object;
	}else{
		return nil;
	}
	
}

+ (void)setCachedParseObject:(PFObject *)PO{
	[[EWDataStore sharedInstance].serverObjectPool setObject:PO forKey:PO.objectId];
}

+ (PFObject *)getParseObjectWithClass:(NSString *)class WithID:(NSString *)ID withError:(NSError **)error{
	if (ID) {
		//try to find PO in the pool first
		PFObject *object = [EWDataStore getCachedParseObjectForID:ID];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:class inManagedObjectContext:mainContext];
		
		//if not found, then download
		if (!object || !object.isDataAvailable) {
			//fetch from server if not found
			//or if PO doesn't have data avaiable
			//or if PO is older than MO
			PFQuery *q = [PFQuery queryWithClassName:entity.serverClassName];
			[q whereKey:kParseObjectID equalTo:ID];
			q.cachePolicy = kPFCachePolicyCacheElseNetwork;
			
			[entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
				if (obj.isToMany && !obj.inverseRelationship) {
					[q includeKey:key];
				}
			}];
			if (q.hasCachedResult || [EWDataStore isReachable]) {
				object = [q getFirstObject:error];
			}
			
			if (object) {
				//save to queue
				[[EWDataStore sharedInstance].serverObjectPool setObject:object forKey:ID];
			}
			
		}
		
		return object;
	}
	
	NSLog(@"!!! ParseObjectID not exist, upload first!");
	return nil;

}

#pragma mark - ============== Parse Server methods ==============
- (BOOL)isUploading{
	return _isUploading;
}

- (void)setIsUploading:(BOOL)isUploading{
	@synchronized(self){
		_isUploading = isUploading;
	}
}

- (void)updateToServer{
    //make sure it is called on main thread
    NSParameterAssert([NSThread isMainThread]);
    if([mainContext hasChanges]){
        NSLog(@"There is still some change, save and do it later");
        [EWDataStore save];
        return;
    }
	
	if (self.isUploading) {
		NSLog(@"Data Store is uploading, delay for 30s");
		static NSTimer *uploadDelay;
		[uploadDelay invalidate];
		uploadDelay = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(updateToServer) userInfo:nil repeats:NO];
		return;
	}
	self.isUploading = YES;
	
	//determin network reachability
	if (!EWDataStore.isReachable) {
		NSLog(@"Network not reachable, skip uploading");
		return;
	}
    
    NSLog(@"Start update to server");
    
    //only ManagedObjectID is thread safe
    NSSet *insertedManagedObjects = [EWDataStore insertQueue];
    NSSet *updatedManagedObjects = [EWDataStore updateQueue];
    NSSet *deletedServerObjects = EWDataStore.deleteQueue;
    NSMutableSet *workingObjects = [NSMutableSet new];
    
    //copy the list to working queue
    [workingObjects unionSet:updatedManagedObjects];
    [workingObjects unionSet:insertedManagedObjects];
    for (NSManagedObject *mo in workingObjects) {
		[EWDataStore appendObject:mo toQueue:kParseQueueWorking];
		//clear save to local items
		[self.saveToLocalItems removeObject:mo.objectID];
    }
	
	//save to local items
	NSArray *saveToLocalItemAlreadyInWorkingQueue = [self.saveToLocalItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF IN %@", workingObjects]];
	for (NSManagedObjectID *ID in saveToLocalItemAlreadyInWorkingQueue) {
		[self.saveToLocalItems removeObject:ID];
	}

	//clear save/delete to local items
	self.saveToLocalItems = [NSMutableArray new];
	self.deleteToLocalItems = [NSMutableArray new];
    
    //clear queues
    [EWDataStore clearQueue:kParseQueueInsert];
    [EWDataStore clearQueue:kParseQueueUpdate];
	workingChangedRecords = _changeRecords;
	_changeRecords = [NSMutableDictionary new];
	
	
    NSLog(@"============ Start updating to server =============== \n Inserts:%@, \n Updates:%@ \n and Deletes:%@ ", [insertedManagedObjects valueForKeyPath:@"entity.name"], [updatedManagedObjects valueForKey:kParseObjectID], deletedServerObjects);
	NSLog(@"Change records:\n%@", workingChangedRecords);
    
    
    NSArray *callbacks = [[EWDataStore sharedInstance].saveCallbacks copy];
    [_saveCallbacks removeAllObjects];

    //start background update
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
		for (NSManagedObject *MO in workingObjects) {
			NSManagedObject *localMO = [MO inContext:localContext];
			if (!localMO) {
				NSLog(@"*** MO %@(%@) to upload haven't saved", MO.entity.name, MO.serverID);
				continue;
			}
            [EWDataStore updateParseObjectFromManagedObject:localMO];
			
			//remove changed record
			NSArray *changes = workingChangedRecords[localMO.objectID];
			[workingChangedRecords removeObjectForKey:localMO.objectID];
			NSLog(@"===> MO %@(%@) uploaded to server with changes applied: %@. %lu to go.", localMO.entity.serverClassName, localMO.serverID, changes, (unsigned long)workingChangedRecords.allKeys.count);
			
			//remove from queue
			[EWDataStore removeObjectFromWorkingQueue:localMO];
        }
        
        for (PFObject *po in deletedServerObjects) {
            [EWDataStore deleteParseObject:po];
        }
		
	} completion:^(BOOL success, NSError *error) {
		
        //completion block
		if (callbacks.count) {
			NSLog(@"=========== Start running completion block (%lu) =============", (unsigned long)callbacks.count);
			for (EWSavingCallback block in callbacks){
				block();
			}
		}
		
		NSLog(@"=========== Finished uploading to saver ===============");
		NSSet *reminningWorkingObjects = [EWDataStore getObjectFromQueue:kParseQueueWorking];
		if (reminningWorkingObjects.count > 0) {
			NSLog(@"*** With failures: (ID)%@(Entity)%@", [reminningWorkingObjects valueForKey:@"objectId"], [reminningWorkingObjects valueForKeyPath: @"entity.name"]);

			[EWDataStore clearQueue:kParseQueueWorking];
		}
		if (workingChangedRecords.count) {
			NSLog(@"*** With remaining changed records: %@", workingChangedRecords);
		}
		
		self.isUploading = NO;
	}];
    
}

+ (void)resumeUploadToServer{
	NSSet *workingMOs = [EWDataStore workingQueue];
	NSSet *deletePOs = [EWDataStore deleteQueue];
	if (workingMOs.count > 0 || deletePOs.count > 0) {
		NSLog(@"There are %lu MOs need to upload or %lu MOs need to delete", (unsigned long)workingMOs.count, (unsigned long)deletePOs.count);
		for (NSManagedObject *MO in workingMOs) {
			if (MO.serverID) {
				NSLog(@"MO %@(%@) resumed to UPDATE queue", MO.entity.name, MO.serverID);
				[EWDataStore appendUpdateQueue:MO];
			}else{
				NSLog(@"MO %@(%@) resumed to INSERT queue", MO.entity.name, MO.objectID);
				[EWDataStore appendInsertQueue:MO];
			}
			
			[EWDataStore removeObjectFromWorkingQueue:MO];
		}
		NSParameterAssert([EWDataStore workingQueue].count == 0);
		
		[[EWDataStore sharedInstance] updateToServer];
	}
}

#pragma mark - Upload worker


+ (void)updateParseObjectFromManagedObject:(NSManagedObject *)managedObject{
	NSError *error;
    
    //validation
    if (![EWDataStore validateMO:managedObject]) {
		NSLog(@"!!! Validation failed for %@(%@), skip upload. Detail: \n%@", managedObject.entity.name, managedObject.serverID, managedObject);
		return;
	}
    
    //skip if updating other PFUser
    //make sure the value is the latest from store
    //[managedObject.managedObjectContext refreshObject:managedObject mergeChanges:NO];
    
    NSString *parseObjectId = managedObject.serverID;
    PFObject *object;
    if (parseObjectId) {
        //download
        object =[managedObject getParseObjectWithError:&error];
        
        if (!object || error) {
            if ([error code] == kPFErrorObjectNotFound) {
                NSLog(@"PO %@ couldn't be found!", managedObject.entity.serverClassName);
				//[managedObject deleteEntityInContext:managedObject.managedObjectContext];
				//return;
				//here we should not return, instead we should create the PO because that's the intention of the process.
            } else if ([error code] == kPFErrorConnectionFailed) {
                NSLog(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                [managedObject updateEventually];
				return;
            } else if (error) {
                NSLog(@"*** Error in getting related parse object from MO (%@). \n Error: %@", managedObject.entity.name, [error userInfo][@"error"]);
                [managedObject updateEventually];
				return;
            }
            object = nil;
            error = nil;
        }
        
    }
	
	if (!object) {
        //insert
        object = [PFObject objectWithClassName:managedObject.entity.serverClassName];
		
        [object save:&error];//need to save before working on PFRelation
        if (!error) {
            NSLog(@"+++> CREATED PO %@(%@)", object.parseClassName, object.objectId);
            [managedObject setValue:object.objectId forKey:kParseObjectID];
            [managedObject setValue:object.updatedAt forKeyPath:kUpdatedDateKey];
        }else{
            [managedObject updateEventually];
            return;
        }
    }
	
    
    //==========set Parse value/relation and callback block===========
    [object updateFromManagedObject:managedObject];
    //================================================================
	
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
		if (error) {
			if (error.code == kPFErrorObjectNotFound){
				NSLog(@"*** PO not found for %@(%@), set to nil.", managedObject.entity.name, managedObject.serverID);
				[managedObject setValue:nil forKey:kParseObjectID];
			}else{
				NSLog(@"*** Failed to save server object: %@", error.description);
			}
			[managedObject updateEventually];
		}else{
			//assign connection between MO and PO
			[EWDataStore performSaveCallbacksWithParseObject:object andManagedObjectID:managedObject.objectID];
		}
		
	}];
    
    
		
	//time stamp for updated date. This is very important, otherwise mo might seems to be outdated
	if (managedObject.hasChanges) {
		[managedObject setValue:[NSDate date] forKey:kUpdatedDateKey];
	}else{
		[managedObject setValue:[NSDate date] forKey:kUpdatedDateKey];
		[EWDataStore saveToLocal:managedObject];
	}
    
}

+ (void)deleteParseObject:(PFObject *)parseObject{
    [parseObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (succeeded) {
            //Good
            NSLog(@"~~~> PO %@(%@) deleted from server", parseObject.parseClassName, parseObject.objectId);
            [EWDataStore removeObjectFromDeleteQueue:parseObject];
            
        }else if (error.code == kPFErrorObjectNotFound){
            //fine
            NSLog(@"~~~> Trying to deleted PO %@(%@) but not found", parseObject.parseClassName, parseObject.objectId);
            [EWDataStore removeObjectFromDeleteQueue:parseObject];
            
        }else{
            //not good
            [EWDataStore removeObjectFromDeleteQueue:parseObject];
        }
    }];
}


+ (void)addSaveCallback:(PFObjectResultBlock)callback forManagedObjectID:(NSManagedObjectID *)objectID{
    //get global save callback
    NSMutableDictionary *saveCallbacks = [EWDataStore sharedInstance].parseSaveCallbacks;
    NSMutableArray *callbacks = [saveCallbacks objectForKey:objectID]?:[NSMutableArray array];
    [callbacks addObject:callback];
    //save
    [saveCallbacks setObject:callbacks forKey:objectID];
}


+ (void)performSaveCallbacksWithParseObject:(PFObject *)parseObject andManagedObjectID:(NSManagedObjectID *)managedObjectID{
    NSArray *saveCallbacks = [[[EWDataStore sharedInstance] parseSaveCallbacks] objectForKey:managedObjectID];
    if (saveCallbacks) {
        for (PFObjectResultBlock callback in saveCallbacks) {
            NSError *err;
            callback(parseObject, err);
        }
        [[EWDataStore sharedInstance].parseSaveCallbacks removeObjectForKey:managedObjectID];
    }
}

#pragma mark - KVO
//observe main context
- (void)preSaveAction:(NSNotification *)notification{
	if (![NSThread isMainThread]) {
		NSLog(@"Skip pre-save check on background thread");
	}
	
	NSManagedObjectContext *localContext = (NSManagedObjectContext *)[notification object];
	
	[EWDataStore enqueueChangesInContext:localContext];
}


@end

#import <objc/runtime.h>

#pragma mark - Core Data ManagedObject extension
@implementation NSManagedObject (PFObject)


- (void)updateValueAndRelationFromParseObject:(PFObject *)parseObject{
    if (!parseObject) {
        NSLog(@"*** PO is nil, please check!");
        return;
    }
    if (!parseObject.isDataAvailable) {
        NSLog(@"*** The PO %@(%@) you passed in doesn't have any data. Deleted from server?", parseObject.parseClassName, parseObject.objectId);
        return;
    }
	
	NSManagedObjectContext *localContext = self.managedObjectContext;
    
    //download data: the fetch here is just a prevention or default state that data is only refreshed when absolutely necessary. If we need check new data, we should refresh PO before passed in here. For example, we fetch PO at app launch for current user update purpose.
    [parseObject fetchIfNeeded];
    
    //Assign attributes
    [self assignValueFromParseObject:parseObject];
    
    //realtion
    NSMutableDictionary *relations = [self.entity.relationshipsByName mutableCopy];
    [relations enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
        
        if ([obj isToMany]) {
            //if no inverse relation, use Array of pointers
            if (!obj.inverseRelationship) {
                NSArray *relatedPOs = parseObject[key];
                NSMutableSet *relatedMOs = [NSMutableSet new];
                for (PFObject *PO in relatedPOs) {
                    if ([PO isKindOfClass:[NSNull class]]) continue;
                    [relatedMOs addObject: [PO managedObjectInContext:localContext]];
                }
                [self setValue:[relatedMOs copy] forKey:key];
                return ;
            }
            
            //Fetch PFRelation for normal relation
            PFRelation *toManyRelation = [parseObject relationForKey:key];
            if (!toManyRelation){
                [self setValue:nil forKey:key];
                return;
            }
            
            //download related PO
            NSError *err;
            NSArray *relatedParseObjects = [[toManyRelation query] findObjects:&err];
            //TODO: handle error
            if ([err code] == kPFErrorObjectNotFound) {
                NSLog(@"*** Uh oh, we couldn't find the related PO!");
                [self setValue:nil forKey:key];
                return;
            } else if ([err code] == kPFErrorConnectionFailed) {
                NSLog(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                [self updateEventually];
            } else if (err) {
                NSLog(@"Error: %@", [err userInfo][@"error"]);
                return;
            }
            
            //found MO's relatedMOs that aren't on server to delete
            NSMutableSet *relatedManagedObjects = [self mutableSetValueForKey:key];
            NSSet *managedObjectToDelete = [relatedManagedObjects filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"NOT %K IN %@", kParseObjectID, [relatedParseObjects valueForKey:kParseObjectID]]];
            
            //substract deletedMOs from original relatedMOs
            [relatedManagedObjects minusSet:managedObjectToDelete];
			
            
            //Union original related MO and MOs referred from PO
            for (PFObject *object in relatedParseObjects) {
                //find corresponding MO
                NSManagedObject *relatedManagedObject = [object managedObjectInContext:localContext];
                [relatedManagedObjects addObject:relatedManagedObject];
            }
            [self setValue:relatedManagedObjects forKey:key];
            
            
        }else{
			//to one
            PFObject *relatedParseObject;
            @try {
                relatedParseObject = [parseObject valueForKey:key];
            }
            @catch (NSException *exception) {
                NSLog(@"Failed to assign value of key: %@ from Parse Object %@ to ManagedObject %@ \n Error: %@", key, parseObject, self, exception.description);
                return;
            }
            if (relatedParseObject) {
                //find corresponding MO
                NSManagedObject *relatedManagedObject = [relatedParseObject managedObjectInContext:localContext];
                [self setValue:relatedManagedObject forKey:key];
            }else{
				
                BOOL inverseRelationExists;
				NSManagedObject *relatedMO;
				PFObject *relatedPO;//related PO get from relatedMO
				
				if (!obj.inverseRelationship) {
					//no inverse relation, skip check
					inverseRelationExists = NO;
				}else{
					//relation empty, check inverse relation first
					relatedMO = [self valueForKey:key];
					if (!relatedMO) return;//no need to do anything
					relatedPO = relatedMO.parseObject;//find relatedPO
					//check if relatedPO's inverse relation contains PO
					if (obj.inverseRelationship.isToMany) {
						PFRelation *reflectRelation = [relatedPO valueForKey:obj.inverseRelationship.name];
						NSArray *reflectPOs = [[reflectRelation query] findObjects];
						inverseRelationExists = [reflectPOs containsObject:parseObject];
					}else{
						PFObject *reflectPO = [relatedPO valueForKey:obj.inverseRelationship.name];
						inverseRelationExists = [reflectPO.objectId isEqualToString:parseObject.objectId] ? YES:NO;
						//it could be that the inversePO is not our PO, in this case, the relation at server side is wrong, but we don't care?
					}
				}
                
                if (!inverseRelationExists) {
					//both side of PO doesn't have
                    [self setValue:nil forKey:key];
                    NSLog(@"~~~> Delete to-one relation on MO %@(%@)->%@(%@)", self.entity.name, parseObject.objectId, obj.name, [relatedMO valueForKey:kParseObjectID]);
                }else{
                    NSLog(@"*** Something wrong, the inverse relation %@(%@) <-> %@(%@) deoesn't agree", self.entity.name, [self valueForKey:kParseObjectID], relatedMO.entity.name, [relatedMO valueForKey:kParseObjectID]);
					if ([relatedPO.updatedAt isEarlierThan:parseObject.updatedAt]) {
						//PO wins
						[self setValue:nil forKey:key];
					}
                }
            }
        }
    }];
    
    //UpdatedDate here only when the relations is updated
    [self setValue:[NSDate date] forKey:kUpdatedDateKey];
    
    //pre save check
    [EWDataStore saveToLocal:self];
}



- (void)assignValueFromParseObject:(PFObject *)object{
	NSError *err;
	[object fetchIfNeeded:&err];
	if (!object.isDataAvailable) {
		NSLog(@"*** The PO %@(%@) you passed in doesn't have any data. Deleted from server?", object.parseClassName, object.objectId);
		if (err.code == kPFErrorObjectNotFound) {
			[self setValue:nil forKeyPath:kParseObjectID];
		}
		return;
	}
	if (self.serverID) {
		NSParameterAssert([[self valueForKey:kParseObjectID] isEqualToString:object.objectId]);
	}else{
		[self setValue:object.objectId forKey:kParseObjectID];
	}
	//attributes
	NSDictionary *managedObjectAttributes = self.entity.attributesByName;
	//NSArray *allKeys = object.allKeys;
	//add or delete some attributes here
	[managedObjectAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *obj, BOOL *stop) {
		key = [NSString stringWithFormat:@"%@", key];
		if (key.skipUpload) {
			//skip the updatedAt
			return;
		}
		id parseValue = [object objectForKey:key];
		
		if ([parseValue isKindOfClass:[PFFile class]]) {
			//PFFile
			PFFile *file = (PFFile *)parseValue;
			
			[self.managedObjectContext saveWithBlock:^(NSManagedObjectContext *localContext) {
				NSError *error;
				NSData *data = [file getData:&error];
				//[file getDataWithBlock:^(NSData *data, NSError *error) {
				if (error || !data) {
					NSLog(@"@@@ Failed to download PFFile: %@", error.description);
					return;
				}
				NSManagedObject *localSelf = [self MR_inContext:localContext];
				NSString *className = [localSelf getPropertyClassByName:key];
				if ([className isEqualToString:@"UIImage"]) {
					UIImage *img = [UIImage imageWithData:data];
					[localSelf setValue:img forKey:key];
				}
				else{
					[localSelf setValue:data forKey:key];
				}
				
			}];
			
		}else if(parseValue && ![parseValue isKindOfClass:[NSNull class]]){
			//contains value
			if ([[self getPropertyClassByName:key] serverType]){
				
				//need to deal with local type
				if ([parseValue isKindOfClass:[PFGeoPoint class]]) {
					PFGeoPoint *point = (PFGeoPoint *)parseValue;
					CLLocation *loc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
					[self setValue:loc forKey:key];
				}else{
					[NSException raise:@"Server class not handled" format:@"Check your code!"];
				}
			}else{
				@try {
					[self setValue:parseValue forKey:key];
				}
				@catch (NSException *exception) {
					NSLog(@"*** Failed to set value for key %@ on MO %@(%@)", key, self.entity.name, self.serverID);
				}
			}
		}else{
			//parse value empty, delete
			if ([self valueForKey:key]) {
				//NSLog(@"~~~> Delete attribute on MO %@(%@)->%@", self.entity.name, [obj valueForKey:kParseObjectID], obj.name);
				[self setValue:nil forKey:key];
			}
		}
	}];
	
	//[EWDataStore saveToLocal:self];
}

#pragma mark -

- (PFObject *)parseObject{
	
	NSError *err;
    PFObject *object = [self getParseObjectWithError:&err];
    if (err) return nil;
	
    //update value
	if (object && object.updatedAt.timeElapsed > kStalelessInterval) {
		[object refresh];
	}
	
    return object;
}

- (PFObject *)getParseObjectWithError:(NSError **)err{
	
	PFObject *PO = [EWDataStore getParseObjectWithClass:self.entity.name WithID:self.serverID withError:err];

	if (!PO.isDataAvailable/* && *err*/) {

		if ((*err).code == kPFErrorObjectNotFound && [EWDataStore isReachable]) {
			NSLog(@"*** PO %@(%@) doesn't exist on server", self.entity.serverClassName, self.serverID);
			[self setValue:nil forKeyPath:kParseObjectID];
		}else{
			NSLog(@"*** Failed to get PO(%@) from server. %@", self.serverID, *err);
		}
		
		return nil;
	}
    return PO;
}

- (void)createParseObjectWithCompletion:(void (^)(void))block {
	NSParameterAssert(!self.serverID);
    PFObject *object = [PFObject objectWithClassName:self.entity.serverClassName];
	
    NSError *error;
    [object save:&error];
    if (!error) {
        NSLog(@"+++> CREATED PO %@(%@)", object.parseClassName, object.objectId);
		[[EWDataStore sharedInstance].serverObjectPool setObject:object forKey:object.objectId];
        [self setValue:object.objectId forKey:kParseObjectID];
        [self setValue:object.updatedAt forKeyPath:kUpdatedDateKey];//update MO's updatedAt
    }else{
        [self updateEventually];
        return;
    }
    if (block) block();
}


- (void)refreshInBackgroundWithCompletion:(void (^)(void))block{
	//network check
	if (![EWDataStore sharedInstance].reachability.isReachable) {
		NSLog(@"Network not reachable, skip refreshing.");
		//refresh later
		[self refreshEventually];
		if (block) {
            block();
        }
		return;
	}
	
    NSString *parseObjectId = [self valueForKey:kParseObjectID];
    if (!parseObjectId) {
        NSLog(@"When refreshing, MO missing serverID %@, prepare to upload", self.entity.name);
        [self updateEventually];
        [EWDataStore save];
        if (block) {
            block();
        }
    }else{
        if ([self changedKeys]) {
            NSLog(@"!!! The MO %@(%@) you are trying to refresh HAS CHANGES, which makes the process UNSAFE!(%@)", self.entity.name, self.serverID, self.changedKeys);
        }
        
		
		[mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
			NSManagedObject *currentMO = [self inContext:localContext];
			if (!currentMO) {
				NSLog(@"*** Failed to obtain object from database: %@", self);
				return;
			}
			//============ Refresh
			[currentMO refresh];
			//=====================
			
		} completion:^(BOOL success, NSError *error) {
			if (block) {
				block();
			}
			
		}];
            
        
    }
}

- (void)refresh{
	//check network
    if (![EWDataStore sharedInstance].reachability.isReachable) {
		NSLog(@"Network not reachable, refresh later.");
		//refresh later
		[self refreshEventually];
		return;
	}
    
    NSString *parseObjectId = self.serverID;
    
    if (!parseObjectId) {
        //NSParameterAssert([self isInserted]);
        NSLog(@"!!! The MO %@(%@) trying to refresh doesn't have servreID, skip! %@", self.entity.name, self.serverID, self);
    }else{
        if ([self changedKeys]) {
            NSLog(@"*** The MO%@ (%@) you are trying to refresh HAS CHANGES, which makes the process UNSAFE!(%@)", self.entity.name, self.serverID, self.changedKeys);
        }
        
        NSLog(@"===>>>> Refreshing MO %@(%@)", self.entity.name, self.serverID);
		//get the PO
        PFObject *object = self.parseObject;
		//Must update the PO
		[object fetch];
		//update MO
        [self updateValueAndRelationFromParseObject:object];
		//save
        [EWDataStore saveToLocal:self];
    }
}

- (void)refreshEventually{
	[EWDataStore appendObject:self toQueue:kParseQueueRefresh];
}

- (void)refreshRelatedWithCompletion:(void (^)(void))block{
	if (![EWDataStore sharedInstance].reachability.isReachable) {
		NSLog(@"Network not reachable, refresh later.");
		//refresh later
		[self refreshEventually];
		return;
	}
	
	if (![self isKindOfClass:[EWPerson class]]) {
		return;
	}
    
    //first try to refresh if needed
    [self refresh];
    
    //then iterate all relations
    NSDictionary *relations = self.entity.relationshipsByName;
    [relations enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *description, BOOL *stop) {
        if ([description.destinationEntity.name isEqualToString:kUserClass]) {
            //return;
        }
        
        
        if ([description isToMany]) {
            
            NSSet *relatedMOs = [self valueForKey:key];
            
            for (NSManagedObject *MO in relatedMOs) {
                if ([MO isKindOfClass:[EWPerson class]]) {
                    return ;
                }
                [MO refresh];
            }
        }else{
            NSManagedObject *MO = [self valueForKey:key];
            [MO refresh];
        }
    }];
	
	if (block) {
		block();
	}
}

- (void)refreshShallowWithCompletion:(void (^)(void))block{
    if (![EWDataStore isReachable]) {
		NSLog(@"Network not reachable, refresh later.");
		//refresh later
		[self refreshEventually];
		return;
	}
	
    if (!self.isOutDated) {
        return;
    }
    
    NSManagedObjectID *ID = self.objectID;
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSError *err;
        NSManagedObject *backMO = [localContext existingObjectWithID:ID error:&err];
        if (err) {
            NSLog(@"*** Failed to get back MO: %@", err.description);
            return ;
        }
        
        //Get PO from server, also add inlcude key for pointer
        PFObject *PO = self.parseObject;
		
		//update properties
		[self assignValueFromParseObject:PO];
        
        //get related object parsimoniously, if
        [backMO.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
            if (obj.isToMany) {
                if (obj.inverseRelationship) {
                    //PFRelation, skip
                }else{
                    //Pointer
                    NSArray *relatedPOs = PO[key];
					if (relatedPOs.count == 0) {
						return;
					}
                    NSMutableSet *relatedMOs = [backMO mutableSetValueForKey:key];
                    for (PFObject *p in relatedPOs) {
						if ([p isKindOfClass:[NSNull class]]) {
							[relatedMOs removeObject:p];
							PO[key] = relatedPOs;
							if ([PO isEqual:[PFUser currentUser]]) {
								[PO saveInBackground];
							}
							continue ;
						}
                        NSManagedObject *relatedMO = [p managedObjectInContext:localContext];
                        if (![relatedMOs containsObject:relatedMO]) {
                            [relatedMOs addObject:relatedMO];
                        }
                    }
                    [backMO setValue:relatedMOs forKey:key];
                }
            }
        }];
        
        NSLog(@"Shallow refreshed MO %@(%@) in backgound", PO.parseClassName, PO.objectId);
        
    }completion:^(BOOL success, NSError *error) {
		if (block) {
			block();
		}
		
        
    }];
    
}

- (void)updateEventually{
	
    if (self.serverID) {
        //update
        NSLog(@"%s: updated %@ eventually", __func__, self.entity.name);
        [EWDataStore appendUpdateQueue:self];
    }else{
        //insert
        NSLog(@"%s: insert %@ eventually", __func__, self.entity.name);
        [EWDataStore appendInsertQueue:self];
    }
}

- (void)deleteEventually{
    PFObject *po = [PFObject objectWithoutDataWithClassName:self.entity.name objectId:self.serverID];
    NSLog(@"%s: delete %@ eventually", __func__, self.entity.name);
    [EWDataStore appendObjectToDeleteQueue:po];

    //delete
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext deleteObject:self];
    }];
}


- (NSArray *)changedKeys{
	NSMutableArray *changes = self.changedValues.allKeys.mutableCopy;
	[changes removeObjectsInArray:attributeUploadSkipped];
	if (changes.count > 0) {
		return changes;
	}
	return nil;
}

- (void)saveToLocal{
	//mark MO as save to local
	if (self.objectID.isTemporaryID) {
		[self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:NULL];
	}
	[[EWDataStore sharedInstance].saveToLocalItems addObject:self.objectID];
	
	//save to enqueue the updates
	[self.managedObjectContext MR_saveToPersistentStoreWithCompletion:NULL];
	
	//remove from the update queue
	[EWDataStore removeObjectFromInsertQueue:self];
	[EWDataStore removeObjectFromUpdateQueue:self];
}

- (void)saveToServer{
	if (self.objectID.isTemporaryID) {
		[self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:NULL];
	}
	[[EWDataStore sharedInstance].saveToLocalItems removeObject:self.objectID];
	//[self.managedObjectContext MR_saveToPersistentStoreWithCompletion:NULL];
	[EWDataStore appendUpdateQueue:self];
}


#pragma mark - Helper methods
- (NSString *)getPropertyClassByName:(NSString *)name{
    objc_property_t property = class_getProperty([self class], [name UTF8String]);
    const char * type = property_getAttributes(property);
    NSString * typeString = [NSString stringWithUTF8String:type];
    NSArray * attributes = [typeString componentsSeparatedByString:@","];
    NSString * typeAttribute = [attributes objectAtIndex:0];
    if ([typeAttribute hasPrefix:@"T@"]) {
        NSString * typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];  //turns @"NSDate" into NSDate
        return typeClassName;
    }
    return @"";
}

- (BOOL)isOutDated{
    NSDate *date = (NSDate *)[self valueForKey:kUpdatedDateKey];
    if (!date) {
        return YES;
    }
    BOOL outdated = !date.isUpToDated;
    return outdated;
}

- (NSString *)serverID{
    return [self valueForKey:kParseObjectID];
}

@end

#pragma mark - Parse Object extension
@implementation PFObject (NSManagedObject)
- (void)updateFromManagedObject:(NSManagedObject *)managedObject{
	NSManagedObjectContext *localContext = managedObject.managedObjectContext;
	NSError *err;
	[self fetchIfNeeded:&err];
	if (err && self.objectId) {
		if (err.code == kPFErrorObjectNotFound) {
			NSLog(@"PO %@(%@) not found on server!", self.parseClassName, self.objectId);
			[managedObject setValue:nil forKeyPath:kParseObjectID];
		}else{
			NSLog(@"Trying to upload but PO error fetching: %@. Skip!", err.description);
		}
		
		[managedObject updateEventually];
		return;
	}
	
//If PO just created, the PO is newer than MO, this is not reliable. Also, it is against the intention. Therefore, the intention of upload should overload the fact that PO is newer.
//    if (self.isNewerThanMO) {
//        NSLog(@"@@@ Trying to update MO %@, but PO is newer! Please check the code.(%@ -> %@)", managedObject.entity.name, [managedObject valueForKey:kUpdatedDateKey], self.updatedAt);
//        return;
//    }

	
    NSArray *changeValues = [[EWDataStore sharedInstance].changeRecords objectForKey:managedObject.objectID];
//    if (!changeValues) {
//        changeValues = attributeDescriptions.allKeys;
//    }
    [managedObject.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *obj, BOOL *stop) {
		//for now, we just use changed value as a mean to exam our theory
		BOOL expectChange = NO;
        if ([changeValues containsObject:key]){
            expectChange = YES;
        }
        
        //check if changed
        if (key.skipUpload) {
            return;
        }
        
		//=============== ATTRIBUTES ===============
        id value = [managedObject valueForKey:key];
		id POValue = [self valueForKey:key];
        
        //there could have some optimization that checks if value equals to PFFile value, and thus save some network calls. But in order to compare there will be another network call to fetch, the the comparison is redundant.
        if ([value isKindOfClass:[NSData class]]) {
            //data
			if (!expectChange && POValue) {
				NSLog(@"MO attribute %@(%@)->%@ no change", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], key);
			}
			//TODO: video file
			EWPerson *localMe = (EWPerson *)[localContext objectWithID:me.objectID];
			NSString *fileName = [NSString stringWithFormat:@"%@.m4a", localMe.name];
            PFFile *dataFile = [PFFile fileWithName:fileName data:value];
            [self setObject:dataFile forKey:key];
        }else if ([value isKindOfClass:[UIImage class]]){
            //image
			if (!expectChange && POValue) {
				NSLog(@"MO attribute %@(%@)->%@ no change", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], key);
			}
            PFFile *dataFile = [PFFile fileWithName:@"Image.png" data:UIImagePNGRepresentation((UIImage *)value)];
            //[dataFile saveInBackground];//TODO: handle file upload exception
            [self setObject:dataFile forKey:key];
        }else if ([value isKindOfClass:[CLLocation class]]){
            //location
			if (!expectChange && POValue) {
				NSLog(@"MO attribute %@(%@)->%@ no change", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], key);
			}
            PFGeoPoint *point = [PFGeoPoint geoPointWithLocation:(CLLocation *)value];
            [self setObject:point forKey:key];
        }else if(value != nil){
			[self setObject:value forKey:key];
            
        }else{
            //value is nil, delete PO value
			
			if ([self.allKeys containsObject:key]) {
				NSLog(@"!!! Data %@ empty on MO %@(%@), please check!", key, managedObject.entity.name, managedObject.serverID);
				[self removeObjectForKey:key];
			}
        }
        
    }];
    
    //=============== relation ===============
    NSMutableDictionary *mutableRelationships = [managedObject.entity.relationshipsByName mutableCopy];
    [mutableRelationships enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
        id relatedManagedObjects = [managedObject valueForKey:key];
        if (relatedManagedObjects){
            if ([obj isToMany]) {
                //To-Many relation
                //First detect if has inverse relation, if not, we use Array to represent the relation
				//Exceptin: if the relation is linked to a user, we still use PFRelation as the size of PFObject will be too large for Array to store PFUser
				//TODO: in the next release we need to use Array for all relation except relation to EWPerson
                if (!obj.inverseRelationship/* && ![key isEqualToString:kUserClass]*/) {
                    //No inverse relation, use array of pointer
                    
                    NSSet *relatedMOs = [managedObject valueForKey:key];
                    NSMutableArray *relatedPOs = [NSMutableArray new];
                    for (NSManagedObject *MO in relatedMOs) {
                        //PFObject *PO = [EWDataStore getCachedParseObjectForID:MO.serverID];
						//if (!PO) {
						PFObject *PO = [PFObject objectWithoutDataWithClassName:MO.entity.serverClassName objectId:[MO valueForKey:kParseObjectID]];
						//}
                        [relatedPOs addObject:PO];
                    }
                    [self setObject:[relatedPOs copy] forKey:key];
                    return;
                }
				
				//========================== relation ==========================
                PFRelation *parseRelation = [self relationForKey:key];
				//==============================================================
				
                //Find related PO to delete async
                NSMutableArray *relatedParseObjects = [[[parseRelation query] findObjects] mutableCopy];
				if (relatedParseObjects.count) {
					NSArray *relatedParseObjectsToDelete = [relatedParseObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT %K IN %@", kParseObjectID, [relatedManagedObjects valueForKey:@"objectId"]]];
					for (PFObject *PO in relatedParseObjectsToDelete) {
						[parseRelation removeObject:PO];
						//We don't update the inverse PFRelation as they should be updated from that MO
						NSLog(@"~~~> To-many relation on PO %@(%@)->%@(%@) deleted when updating from MO", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], obj.name, PO.objectId);
					}

				}
                
                //related managedObject that needs to add
                for (NSManagedObject *relatedManagedObject in relatedManagedObjects) {
                    NSString *parseID = relatedManagedObject.serverID;
                    if (parseID) {
                        //the pfobject already exists, need to inspect PFRelation to determin add or remove
                        
                        //PFObject *relatedParseObject = [EWDataStore getCachedParseObjectForID:parseID];
						PFObject *relatedParseObject = [PFObject objectWithoutDataWithClassName:relatedManagedObject.entity.serverClassName objectId:parseID];
                        //[relatedParseObject fetchIfNeeded];
                        [parseRelation addObject:relatedParseObject];
						//NSLog(@"+++> To-many relation on PO %@(%@)->%@(%@) added when updating from MO", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], obj.name, relatedParseObject.objectId);
                        
                    } else {
                        __block PFObject *blockObject = self;
                        __block PFRelation *blockParseRelation = parseRelation;
                        //set up a saving block
                        //NSLog(@"Relation %@ -> %@ save block setup", blockObject.parseClassName, relatedManagedObject.entity.serverClassName);
                        PFObjectResultBlock connectRelationship = ^(PFObject *object, NSError *error) {
                            //the relation can only be additive, which is not a problem for new relation
                            [blockParseRelation addObject:object];
                            [blockObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                NSLog(@"PO Relation %@(%@) -> %@ (%@) established in PO save callback", blockObject.parseClassName, blockObject.objectId, object.parseClassName, object.objectId);
                                if (error) {
                                    NSLog(@"Failed to save: %@", error.description);
                                    @try {
                                        [blockObject saveEventually];
                                    }
                                    @catch (NSException *exception) {
                                        [managedObject updateEventually];
                                    }
                                }
                            }];
                        };
                        
                        //add to global save callback distionary
                        [EWDataStore addSaveCallback:connectRelationship forManagedObjectID:relatedManagedObject.objectID];

                        //add relatedMO to insertQueue
						if (![EWDataStore contains:relatedManagedObject inQueue:kParseQueueWorking]) {
							[EWDataStore appendInsertQueue:relatedManagedObject];
						}
                    }
                }
            }else {
                //TO-One relation
                NSManagedObject *relatedMO = [managedObject valueForKey:key];
                NSString *parseID = relatedMO.serverID;
                if (parseID) {
                    PFObject *relatedPO = [relatedMO getParseObjectWithError:NULL];//TODO: test if we can use empty PO
                    [self setObject:relatedPO forKey:key];
					//NSLog(@"+++> To-one relation on PO %@(%@)->%@(%@) added when updating from MO", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], obj.name, relatedPO.objectId);
                }else{
                    //MO doesn't have parse id, save to parse
                    __block PFObject *blockObject = self;
                    //set up a saving block
                    PFObjectResultBlock connectRelationship = ^(PFObject *object, NSError *error) {
                        [blockObject setObject:object forKey:key];
                        [blockObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            //relationship can be saved regardless of network condition.
                            if (error) {
                                NSLog(@"Failed to save: %@", error.description);
                                @try {
                                    [blockObject saveEventually];
                                }
                                @catch (NSException *exception) {
                                    [managedObject updateEventually];
                                }
                                
                            }
                        }];
                    };
                    //add to global save callback distionary
                    [EWDataStore addSaveCallback:connectRelationship forManagedObjectID:relatedMO.objectID];
                }
            }
        }else{
			
			//relation cannot be to-many, as it's always has value
            //empty related object, delete PO relationship
			//I doubt if we really need to delete inverse relation
            if ([self valueForKey:key]) {
				

				NSLog(@"Empty relationship on MO %@(%@) -> %@, delete PO relation.", managedObject.entity.name, self.objectId, obj.name);
//                NSRelationshipDescription *inverseRelation = obj.inverseRelationship;
//                PFObject *inversePO = self[key];
//				if (inversePO.ACL != nil) {
//					BOOL write = [inversePO.ACL getWriteAccessForUser:[PFUser currentUser]] || [inversePO.ACL getPublicWriteAccess];
//				}
//                if (inverseRelation.isToMany) {
//                    //inverse to-many relation need to be updated
//                    [inversePO fetchIfNeeded];
//                    PFRelation *inversePFRelation = [inversePO relationForKey:inverseRelation.name];
//                    [inversePFRelation removeObject:self];
//                    [inversePO save:nil];
//                    NSLog(@"~~~> Removed inverse to-many relation: %@ -> %@", self.parseClassName, inversePO.parseClassName);
//                }else{
//                    //to-one
//                    [inversePO removeObjectForKey:inverseRelation.name];
//                }
//				[inversePO save];
				
                [self removeObjectForKey:key];
				
            }
        }
        
    }];
    //Only save when network is available so that MO can link with PO
    //[self saveEventually];
	
}

- (NSManagedObject *)managedObjectInContext:(NSManagedObjectContext *)context{
	
	if (!self.objectId) {
		return nil;
	}
	
	if (!context) {
		context = mainContext;
	}
	NSMutableArray *MOs = [[NSClassFromString(self.localClassName) findByAttribute:kParseObjectID withValue:self.objectId inContext:context] mutableCopy];
    //NSManagedObject *mo = [NSClassFromString(self.localClassName) MR_findFirstByAttribute:kParseObjectID withValue:self.objectId inContext:context];
	while (MOs.count > 1) {
		NSLog(@"Find duplicated MO for ID %@", self.objectId);
		NSManagedObject *mo_ = MOs.lastObject;
		[MOs removeLastObject];
		[mo_ deleteEntityInContext:context];
		[EWDataStore deleteToLocal:self];
	}
	NSManagedObject *mo = MOs.firstObject;
    
    if (!mo) {
        //if managedObject not exist, create it locally
        mo = [NSClassFromString(self.localClassName) MR_createInContext:context];
        [mo assignValueFromParseObject:self];
		//[EWDataStore saveToLocal:mo];//save to local first
        NSLog(@"+++> MO created: %@ (%@)", self.localClassName, self.objectId);
    }else{
		
        if (mo.isOutDated || self.isNewerThanMO) {
            
            [mo assignValueFromParseObject:self];
            //[EWDataStore saveToLocal:mo];//mo will be saved later
        }
    }
    
    return mo;
}

- (BOOL)isNewerThanMO{
	NSDate *updatedPO = [self valueForKey:kUpdatedDateKey];
	NSManagedObject *mo = [NSClassFromString(self.localClassName) findFirstByAttribute:kParseObjectID withValue:self.objectId];
	NSDate *updatedMO = [mo valueForKey:kUpdatedDateKey];
	if (updatedPO && updatedMO) {
		if ([updatedPO isEarlierThan:updatedMO]) {
			return NO;
		}else{
			return YES;
		}
	}else if (updatedMO){
		return NO;
	}else if (updatedPO){
		return YES;
	}
	return NO;
}

- (NSString *)localClassName{
    NSDictionary *map = kServerTransformClasses;
    NSString *localClass = [[map allKeysForObject:self.parseClassName] firstObject];
    return localClass ?: self.parseClassName;
}
@end


@implementation NSEntityDescription (Parse)

- (NSString *)serverClassName{
    NSDictionary *map = kServerTransformClasses;
    NSString *serverClass = [map objectForKey:self.name];
    return serverClass ?: self.name;
}

@end

@implementation NSString (Parse)

- (NSString *)serverType{
    NSDictionary *typeDic = kServerTransformTypes;
    NSString *serverType = typeDic[self];
    return serverType;
}

- (BOOL)skipUpload{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", attributeUploadSkipped];
    BOOL result = [predicate evaluateWithObject:self];
    return result;
}

@end
