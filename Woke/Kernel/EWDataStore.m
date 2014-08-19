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

#define MR_LOGGING_ENABLED 0
#import <MagicalRecord/CoreData+MagicalRecord.h>


#pragma mark - 
#define kServerTransformTypes               @{@"CLLocation": @"PFGeoPoint"} //localType: serverType
#define kServerTransformClasses             @{@"EWPerson": @"_User"} //localClass: serverClass
#define kUserClass                          @"EWPerson"
#define classSkipped                        @[@"EWPerson"]
#define attributeUploadSkipped              @[kParseObjectID, kUpdatedDateKey, @"score"]

@interface EWDataStore()
@property NSManagedObjectContext *context; //the main context(private), only expose 'currentContext' as a class method
@property NSMutableDictionary *parseSaveCallbacks;
@property (nonatomic) NSTimer *saveToServerDelayTimer;
@property NSMutableArray *saveToLocalItems;
//@property (nonatomic) NSMutableDictionary *changesDictionary;
@end

@implementation EWDataStore
@synthesize context;
@synthesize model;
@synthesize dispatch_queue, coredata_queue;
@synthesize lastChecked;
//@synthesize snsClient;
@synthesize parseSaveCallbacks;

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
        //[MagicalRecord setLoggingMask:MagicalRecordLoggingMaskError];
        [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Woke"];
        context = [NSManagedObjectContext defaultContext];
		
        //observe context change to update the modifiedData of that MO. (Only observe the main context)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preSaveAction:) name:NSManagedObjectContextWillSaveNotification object:context];

        //Observe background context saves so main context can perform upload
        //We don't need to merge child context change to main context
		//It will cause errors when main and child context access same MO
		[[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:context queue:nil usingBlock:^(NSNotification *note) {
			
			[[EWDataStore sharedInstance].saveToServerDelayTimer invalidate];
			[EWDataStore sharedInstance].saveToServerDelayTimer = [NSTimer scheduledTimerWithTimeInterval:kUploadLag target:[EWDataStore class] selector:@selector(updateToServer) userInfo:nil repeats:NO];
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
        
        //facebook
        [PFFacebookUtils initializeFacebook];

        //watch for login event
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDataCheck) name:kPersonLoggedIn object:Nil];
        
        //initial property
        self.parseSaveCallbacks = [NSMutableDictionary dictionary];
        self.saveCallbacks = [NSMutableArray new];
		self.saveToLocalItems = [NSMutableArray new];
		self.serverObjectPool = [NSMutableDictionary new];
    }
    return self;
}

- (NSManagedObjectModel *)model
{
    if (model) {
        return model;
    }
    //Returns a model created by merging all the models found in given bundles. If you specify nil, then the main bundle is searched.
    //managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"EarlyWorm" withExtension:@"momd"];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return model;
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
    
    //refresh current user
    NSLog(@"1. Register AWS push key");
    [EWServer registerAPNS];
    
    //check alarm, task, and local notif
    NSLog(@"2. Check alarm");
	[[EWAlarmManager sharedInstance] scheduleAlarm];
	
    NSLog(@"3. Check task");
	[[EWTaskStore sharedInstance] scheduleTasksInBackground];
	[EWTaskStore.sharedInstance checkScheduledNotifications];
	
    NSLog(@"4. Check my unread media");
    [[EWMediaStore sharedInstance] checkMediaAssetsInBackground];
    
    //updating facebook friends
    NSLog(@"5. Updating facebook friends");
    [EWUserManagement getFacebookFriends];
    
    //update facebook info
    NSLog(@"6. Updating facebook info");
    [EWUserManagement updateFacebookInfo];
    
    //Update my relations
    NSLog(@"7. Refresh my relation in background");
    [EWPersonStore updateMe];
    
    //update data with timely updates
    [self registerServerUpdateService];
}


#pragma mark - Timely sync
- (void)registerServerUpdateService{
    self.serverUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:kServerUpdateInterval target:self selector:@selector(serverUpdate:) userInfo:nil repeats:0];
    [self serverUpdate:nil];
}

- (void)serverUpdate:(NSTimer *)timer{
    //services that need to run periodically
    if (!me) {
        return;
    }
    //this will run at the beginning and every 600s
    NSLog(@"Start sync service");
    
    //dispatch_async(dispatch_queue, ^{
    
    //lsat seen
    NSLog(@"[1] Start last seen recurring updates");
    //[EWUserManagement updateLastSeen];
    
    //location
    NSLog(@"[2] Start location recurring update");
    [EWUserManagement registerLocation];
    
    //check task
    NSLog(@"[3] Start recurring task schedule");
	[[EWTaskStore sharedInstance] scheduleTasksInBackground];
    
    //check alarm timer
    NSLog(@"[4] Start recurring alarm timer check");
    [EWWakeUpManager alarmTimerCheck];
    
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

+ (NSManagedObjectContext *)mainContext{
	NSParameterAssert([NSThread isMainThread]);
	return [EWDataStore sharedInstance].context;
}


+ (void)save{
	NSParameterAssert([NSThread isMainThread]);
    //BOOL hasChanges = [EWDataStore saveAndEnqueueInContext:[EWDataStore mainContext]];
	if ([EWDataStore mainContext].hasChanges) {
		[[EWDataStore mainContext] saveToPersistentStoreAndWait];
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

+ (BOOL)enqueueChangesInContext:(NSManagedObjectContext *)context{
	BOOL hasChange = NO;
	
    NSSet *inserts = [context insertedObjects];
    NSSet *updates = [context updatedObjects];
    NSSet *deletes = [context deletedObjects];
    
    if (inserts.count || updates.count || deletes.count) {
		
        for (NSManagedObject *MO in inserts) {
			//skip if marked as save to local
			if ([[EWDataStore sharedInstance].saveToLocalItems containsObject:MO]) {
				continue;
			}
			
            NSString *serverID = [MO valueForKey:kParseObjectID];
            if (serverID) {
                NSLog(@"MO %@(%@) has serverID, meaning it is fetched from server, please check!", MO.entity.name, [MO valueForKey:kParseObjectID]);
                //continue;
            }
            NSLog(@"+++> MO %@ inserted to queue", MO.entity.name);
            [EWDataStore appendInsertQueue:MO];
			hasChange = YES;
        }
		
		
        for (NSManagedObject *MO in updates) {
			//skip if marked as save to local
			if ([[EWDataStore sharedInstance].saveToLocalItems containsObject:MO]) {
				continue;
			}
			
            //skip if updatedMO contained in insertedMOs
            if ([inserts containsObject:MO]) {
                continue;
            }
			
			//move to inserts if no serverID
			if (!MO.serverID) {
				[EWDataStore appendInsertQueue:MO];
				continue;
			}
			
			//skip if MO doesn't have updatedAt
			if (![MO valueForKey:kUpdatedDateKey]) {
				NSLog(@"!!! MO %@(%@) doesn't have updatedAt, skip enqueue.", MO.entity.name, MO.serverID);
				continue;
			}
            
            //check if class is skipped
            if ([classSkipped containsObject:MO.entity.name] && MO.serverID != me.serverID) {
                NSLog(@"MO %@(%@) skipped uploading to server by definition", MO.entity.name, MO.serverID);
                continue;
            }
            //check if updated keys are valid
            NSArray *changedKeys = MO.valueToUpload;
            if (changedKeys.count > 0) {
                NSLog(@"===> MO %@(%@) updated to queue with changes: %@", MO.entity.name, [MO valueForKey:kParseObjectID], changedKeys);
                [EWDataStore appendUpdateQueue:MO];
				hasChange = YES;
            }
            
        }
		
        for (NSManagedObject *MO in deletes) {
            NSLog(@"~~~> MO %@(%@) deleted from context", MO.entity.name, [MO valueForKey:kParseObjectID]);
            PFObject *PO = [MO getParseObjectWithError:nil];
            [EWDataStore appendDeleteQueue:PO];
			hasChange = YES;
        }
    }
	

	//[context saveToPersistentStoreAndWait];
	return hasChange;
}

+ (void)saveToLocal:(NSManagedObject *)mo{
	
    //pre save check
	if (![mo.serverID isEqualToString:me.serverID]) {
		NSArray *updates  = [[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueUpdate];
		NSArray *inserts  = [[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueUpdate];
		NSString *ID = mo.objectID.URIRepresentation.absoluteString;
		NSArray *u = [updates filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@", ID]];
		NSArray *i = [inserts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@", ID]];
		if (u.count) {
			NSLog(@"!!! %@(%@) save to local is already in the UPDATE queue. Check your code! ", mo.entity.name, ID);
		}
		if (i.count) {
			NSLog(@"!!! %@(%@) save to local is already in the INSERT queue. Check your code!", mo.entity.name, ID);
		}
	}
    
	//mark MO as save to local
	[[EWDataStore sharedInstance].saveToLocalItems addObject:mo];

    //save to enqueue the updates
    [EWDataStore enqueueChangesInContext:mo.managedObjectContext];
	[[EWDataStore sharedInstance].saveToLocalItems removeObject:mo];
    
    //remove from the update queue
    [EWDataStore removeObjectFromInsertQueue:mo];
    [EWDataStore removeObjectFromUpdateQueue:mo];

    
}

#pragma mark - Core Data Tools


+ (BOOL)validateMO:(NSManagedObject *)mo{
    //validate MO, only used when uploading MO to PO
	BOOL good = YES;
	
	if (![mo valueForKey:kUpdatedDateKey] && mo.serverID) {
		NSLog(@"The %@(%@) you are trying to validate haven't been downloaded fully. Skip validating.", mo.entity.name, mo.serverID);
		return YES;
	}
	
    NSString *type = mo.entity.name;
    if ([type isEqualToString:@"EWTaskItem"]) {
        good = [EWTaskStore validateTask:(EWTaskItem *)mo];
		if (!good) {
			[mo refresh];
			good = [EWTaskStore validateTask:(EWTaskItem *)mo];
			
			if (!good) {
				NSLog(@"*** %@(%@) failed in validation => delete!", mo.entity.name, mo.serverID);
				[mo deleteEntity];
			}
			
		}
    } else if([type isEqualToString:@"EWMediaItem"]){
        good = [EWMediaStore validateMedia:(EWMediaItem *)mo];
		if (!good) {
			[mo refresh];
			good = [EWMediaStore validateMedia:(EWMediaItem *)mo];
		
			if (!good) {
				NSLog(@"*** %@(%@) failed in validation => delete!", mo.entity.name, mo.serverID);
				[mo deleteEntity];
			}
		}
    }else if ([type isEqualToString:@"EWPerson"]){
        good = [EWPersonStore validatePerson:(EWPerson *)mo];
		if (!good) {
			[mo refresh];
			good = [EWMediaStore validateMedia:(EWMediaItem *)mo];
		}
    }
	
	return good;
}



+ (BOOL)checkAccess:(NSManagedObject *)mo{
	if (!mo.serverID) {
		return YES;
	}
	
	//if ACL not exist, use class by class method to determine
	EWPerson *p;
	if ([mo respondsToSelector:@selector(owner)]) {
		p = [mo valueForKey:@"owner"];
	}else{
		if ([mo isKindOfClass:[EWPerson class]]) {
			p = (EWPerson *)mo;
		}else if ([mo isKindOfClass:[EWMediaItem class]]){
			//only media has special acl
			PFObject *po = mo.parseObject;
			if (po.ACL != nil) {
				BOOL write = [po.ACL getWriteAccessForUser:[PFUser currentUser]];
				return write;
			}
			//TODO: need update ACL check
			return YES;
		}else{
			return YES;
		}
	}
	
	if (p.isMe){
		return YES;
	}
	return NO;
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
	//check owner
	if(![queue isEqualToString:kParseQueueRefresh] && ![EWDataStore checkAccess:mo]){
		NSLog(@"*** MO %@(%@) doesn't owned by me, skip adding to %@", mo.entity.name, mo.serverID, queue);
		return;
	}
	
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
        NSLog(@"MO %@(%@) added to %@", mo.entity.name, mo.serverID, queue);
		if (!mo.serverID && ![queue isEqualToString:kParseQueueInsert]) {
			NSLog(@"*** unkonwn mo updated: %@", mo);
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

+ (void)appendDeleteQueue:(PFObject *)object{
    if (!object) return;
    NSMutableDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy]?:[NSMutableDictionary new];;
    [dic setObject:object.parseClassName forKey:object.objectId];
    [[NSUserDefaults standardUserDefaults] setObject:[dic copy] forKey:kParseQueueDelete];
}

+ (void)removeDeleteQueue:(PFObject *)object{
    if (!object) return;
    NSMutableDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy];
    [dic removeObjectForKey:object.objectId];
    [[NSUserDefaults standardUserDefaults] setObject:[dic copy] forKey:kParseQueueDelete];
}



#pragma mark - ============== Parse Server methods ==============
+(void)updateToServer{
    //make sure it is called on main thread
    NSParameterAssert([NSThread isMainThread]);
    if([[EWDataStore mainContext] hasChanges]){
        NSLog(@"There is still some change when updating to server, save and do it later");
        [EWDataStore save];
        return;
    }
	
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
    }
    NSSet *workingObjectIDs = [workingObjects valueForKey:@"objectID"];
    
    //clear queues
    [EWDataStore clearQueue:kParseQueueInsert];
    [EWDataStore clearQueue:kParseQueueUpdate];
    
    
    NSLog(@"============ Start updating to server =============== \n Inserts:%@, \n Updates:%@ \n and Deletes:%@ ", [insertedManagedObjects valueForKeyPath:@"entity.name"], [updatedManagedObjects valueForKey:kParseObjectID], deletedServerObjects);
    
    
    NSArray *callbacks = [[EWDataStore sharedInstance].saveCallbacks copy];
    [[EWDataStore sharedInstance].saveCallbacks removeAllObjects];

    //start background update
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		for (NSManagedObjectID *ID in workingObjectIDs) {
			NSError *error;
			NSManagedObject *localMO = [localContext existingObjectWithID:ID error:&error];
            [EWDataStore updateParseObjectFromManagedObject:localMO];
        }
        
        for (PFObject *po in deletedServerObjects) {
            [EWDataStore deleteParseObject:po];
        }
		
	} completion:^(BOOL success, NSError *error) {
		
        //completion block
        dispatch_async(dispatch_get_main_queue(), ^{
			if (callbacks.count) {
				NSLog(@"=========== Start upload completion block (%d) =============", callbacks.count);
				for (EWSavingCallback block in callbacks){
					block();
				}
				
				//clean
				[EWDataStore sharedInstance].saveCallbacks = [NSMutableArray new];
			}
        });
		
		NSLog(@"=========== Finished uploading to saver ===============");
	}];
    
}

+ (void)resumeUploadToServer{
	NSSet *workingMOs = [EWDataStore workingQueue];
	NSSet *deletePOs = [EWDataStore deleteQueue];
	if (workingMOs.count > 0 || deletePOs.count > 0) {
		NSLog(@"There are %d MOs need to upload or %d MOs need to delete", workingMOs.count, deletePOs.count);
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
		
		[EWDataStore updateToServer];
	}
}

#pragma mark -


+ (void)updateParseObjectFromManagedObject:(NSManagedObject *)managedObject{
	NSError *error;
    
    //validation
    if (![EWDataStore validateMO:managedObject]) {
		NSLog(@"!!! Validation failed for %@(%@), skip upload. Detail: \n%@", managedObject.entity.name, managedObject.serverID, managedObject);
		return;
	}
    
    //skip if updating other PFUser
    //make sure the value is the latest from store
    [managedObject.managedObjectContext refreshObject:managedObject mergeChanges:NO];
    
    NSString *parseObjectId = [managedObject valueForKey:kParseObjectID];
    PFObject *object;
    if (parseObjectId) {
        //download
        object =[managedObject getParseObjectWithError:&error];
        
        if (!object) {
            //TODO: handle error
            if ([error code] == kPFErrorObjectNotFound) {
                NSLog(@"PO %@ couldn't be found!", managedObject.entity.serverClassName);
                // Now also check for connection errors:
                //delete ParseID from MO
//                NSManagedObjectID *ID = mo.objectID;
//                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//                    NSManagedObject *localMO = [localContext objectWithID:ID];
//                    [localContext deleteObject:localMO];
//                    NSLog(@"MO %@ deleted", mo.entity.name);
//                }];
            } else if ([error code] == kPFErrorConnectionFailed) {
                NSLog(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                [managedObject updateEventually];
				return;
            } else if (error) {
                NSLog(@"*** Error in getting related parse object from MO (%@). \n Error: %@", managedObject.entity.name, [error userInfo][@"error"]);
                [managedObject updateEventually];
				return;
            }
            
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
	
    [object save:&error];
    if (!error) {
        
        //assign connection between MO and PO
        [EWDataStore performSaveCallbacksWithParseObject:object andManagedObjectID:managedObject.objectID];
        [managedObject.managedObjectContext saveToPersistentStoreAndWait];
        
        
        //remove from queue
        [EWDataStore removeObjectFromWorkingQueue:managedObject];
    } else {
        NSLog(@"Failed to save server object: %@", error.description);
        
    }
    
    //time stamp for updated date. This is very important, otherwise mo might seems to be outdated
    [managedObject setValue:[NSDate date] forKey:kUpdatedDateKey];

}

+ (void)deleteParseObject:(PFObject *)parseObject{
    [parseObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (succeeded) {
            //Good
            NSLog(@"~~~> PO %@(%@) deleted from server", parseObject.parseClassName, parseObject.objectId);
            [EWDataStore removeDeleteQueue:parseObject];
            
        }else if (error.code == kPFErrorObjectNotFound){
            //fine
            NSLog(@"~~~> Trying to deleted PO %@(%@) but not found", parseObject.parseClassName, parseObject.objectId);
            [EWDataStore removeDeleteQueue:parseObject];
            
        }else{
            //not good
            [EWDataStore appendDeleteQueue:parseObject];
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
//observe all context, but only modify updatedAt on main thread
- (void)preSaveAction:(NSNotification *)notification{
	NSManagedObjectContext *localContext = (NSManagedObjectContext *)[notification object];
	
	NSSet *updatedObjects = localContext.updatedObjects;
	NSSet *insertedObjects = localContext.insertedObjects;
	NSSet *objects = [updatedObjects setByAddingObjectsFromSet:insertedObjects];
	
    //for updated mo
    for (NSManagedObject *mo in objects) {
		//Potential bug: CoreData could not fulfill a fault for mo
		//First test MO exist
		if (![localContext existingObjectWithID:mo.objectID error:NULL]) {
			NSLog(@"*** MO you are trying to modify doesn't exist in the sqlite: %@", mo.objectID);
			break;
		}
		
		NSDate *lastUpdated = [mo valueForKey:kUpdatedDateKey];
	
		//skip if marked save to local
		if ([self.saveToLocalItems containsObject:mo]) {
			break;
		}
		
		//additional check for updated object
		if ([updatedObjects containsObject:mo] && ![insertedObjects containsObject:mo]) {
			//if last updated doesn't exist,
			if (!lastUpdated) return;
			
			//remove unnecessary changes
			//skip this step as when save is made from back context to main context, the mo doesn't have changed values any more
//			if (!mo.valueToUpload) {
//				break;
//			}
		}
		
		
		//Pre-save validate
		BOOL good = [EWDataStore validateMO:mo];
		if (!good && [mo.serverID isEqualToString:me.objectId]) {
			NSLog(@"Validation failed on saving %@", mo);
		}
		
		if ([NSThread isMainThread]) {
			//only update date on main thread
			[mo setValue:[NSDate date] forKeyPath:kUpdatedDateKey];
		}
		
    }
	
		
	if (localContext == [EWDataStore mainContext]) {
		[EWDataStore enqueueChangesInContext:localContext];
	}
}


@end



#pragma mark - Core Data ManagedObject extension
@implementation NSManagedObject (PFObject)
#import <objc/runtime.h>

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
    
    //download if needed
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
                    //if ([PO allKeys].count > 0)
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
            
            //found relatedMOs that aren't on server
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
            
            //DELETE from the relation to MO not found on server
            for (NSManagedObject *MOToDelete in managedObjectToDelete) {
                NSLog(@"~~~> Delete to-many relation on MO %@(%@)->%@(%@)", self.entity.name, parseObject.objectId, obj.name, [MOToDelete valueForKey:kParseObjectID]);
                NSMutableSet *relatedMOs = [self mutableSetValueForKey:key];
                [relatedMOs removeObject:MOToDelete];
                [self setValue:relatedMOs forKeyPath:key];
            }
            
            
        }else{//to one
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
                //relation empty, check inverse relation first
                NSManagedObject *inverseMO = [self valueForKey:key];
                if (!inverseMO) return;
                PFObject *inversePO = inverseMO.parseObject;
                BOOL inverseRelationExists = YES;
                if (obj.inverseRelationship.isToMany) {
                    PFRelation *reflectRelation = [inversePO valueForKey:obj.inverseRelationship.name];
                    NSArray *reflectPOs = [[reflectRelation query] findObjects];
                    inverseRelationExists = [reflectPOs containsObject:relatedParseObject];
                }else{
                    PFObject *reflectPO = [inversePO valueForKey:obj.inverseRelationship.name];
                    inverseRelationExists = reflectPO ? YES:NO;
                }
                
                
                if (!inverseRelationExists) {
                    [self setValue:nil forKey:key];
                    NSLog(@"~~~> Delete to-one relation on MO %@(%@)->%@(%@)", self.entity.name, parseObject.objectId, obj.name, [inverseMO valueForKey:kParseObjectID]);
                }else{
                    NSLog(@"*** Something wrong, the inverse relation %@(%@) <-> %@(%@) deoesn't agree", self.entity.name, [self valueForKey:kParseObjectID], inverseMO.entity.name, [inverseMO valueForKey:kParseObjectID]);
                }
            }
        }
    }];
    
    //UpdatedDate here only when the relations is updated
    [self setValue:[NSDate date] forKey:kUpdatedDateKey];
    
    //pre save check
    [EWDataStore saveToLocal:self];
}

- (PFObject *)parseObject{
//	if (![EWDataStore sharedInstance].reachability.isReachable) {
//		NSLog(@"Network not reachable, skip getting PO");
//		return nil;
//	}
	
	NSError *err;
    PFObject *object = [self getParseObjectWithError:&err];
    if (err) return nil;
	
    //update value
    [self assignValueFromParseObject:object];
    
    return object;
}

- (PFObject *)getParseObjectWithError:(NSError **)err{
    NSString *parseObjectId = self.serverID;
    
    if (parseObjectId) {
		//try to find PO in the pool first
		PFObject *object = [[EWDataStore sharedInstance].serverObjectPool valueForKey:parseObjectId];
		
		//if not found, then query
		if (!object || !object.isDataAvailable || !object.isNewerThanMO) {
			//fetch from server if not found
			//or if PO doesn't have data avaiable
			//or if PO is older than MO
			PFQuery *q = [PFQuery queryWithClassName:self.entity.serverClassName];
			[q whereKey:kParseObjectID equalTo:parseObjectId];
			q.cachePolicy = kPFCachePolicyCacheElseNetwork;
			[self.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
				if (obj.isToMany && !obj.inverseRelationship) {
					//NSLog(@"Relation %@ included when fetching %@", key, self.entity.name);
					[q includeKey:key];
				}
			}];
			
			object = [q getFirstObject:err];
			if (object) {
				//save to queue
				[[EWDataStore sharedInstance].serverObjectPool setObject:object forKey:parseObjectId];
			}else if(*err){
				NSLog(@"*** Failed to get PO %@ with error: %@", self.serverID, *err);
			}
			
			
		}
        
		if (!object.isDataAvailable && *err) {
			if ((*err).code == kPFErrorObjectNotFound) {
				NSLog(@"*** PO %@(%@) doesn't exist on server", self.entity.serverClassName, self.serverID);
				[self setValue:nil forKeyPath:kParseObjectID];
			}else{
				NSLog(@"*** Failed to get PO(%@) from server. %@", self.serverID, *err);
			}
			
			return nil;
		}
        return object;
    }else{
        NSLog(@"!!! ParseObjectID not exist, upload first!");
        return nil;
    }
    
    return nil;
}

- (void)createParseObjectWithCompletion:(void (^)(void))block {
    PFObject *object = [PFObject objectWithClassName:self.entity.serverClassName];
    NSError *error;
    [object save:&error];
    if (!error) {
        NSLog(@"+++> CREATED PO %@(%@)", object.parseClassName, object.objectId);
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
        NSLog(@"+++> Insert MO %@ from refresh", self.entity.name);
        [self updateEventually];
        [EWDataStore save];
        if (block) {
            block();
        }
    }else{
        if ([self hasChanges]) {
            NSLog(@"!!! The MO (%@) you are trying to refresh HAS CHANGES, which makes the process UNSAFE!", self.entity.name);
        }
        
        //BOOL outdated = self.isOutDated;
        BOOL isPerson = [self isKindOfClass:[EWPerson class]];
        if (!isPerson) {
            //if (!outdated) NSLog(@"MO %@(%@) is not out dated, skip refresh in background", self.entity.name, self.serverID);
            
			NSLog(@"MO %@(%@) is not person, shallow refresh", self.entity.name, self.serverID);
			
			[self refreshShallowWithCompletion:^{
				if (block) {
					block();
				}
			}];
            
            
            return;
        }
        
        NSManagedObjectID *objectID = self.objectID;
        
        //save async
//        dispatch_async([EWDataStore sharedInstance].dispatch_queue, ^{
//			NSManagedObjectContext *localContext = [EWDataStore currentContext];
//            NSManagedObject *currentMO = [localContext objectWithID:objectID];
//            
//            NSLog(@"===> Refreshing %@ (%@) in background", self.entity.name, [self valueForKey:kParseObjectID]);
//            
//            PFObject *object = currentMO.parseObject;
//            [currentMO updateValueAndRelationFromParseObject:object];
//            [localContext saveToPersistentStoreAndWait];
//            
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (block) {
//                    block();
//                }
//            });
//
//        });
		
		[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
			NSManagedObject *currentMO = [localContext objectWithID:objectID];
			NSLog(@"Refreshing %@ (%@) in background", self.entity.name, [self valueForKey:kParseObjectID]);
			
			PFObject *object = currentMO.parseObject;
            [currentMO updateValueAndRelationFromParseObject:object];
			
		} completion:^(BOOL success, NSError *error) {
			block();
		}];
            
        
    }
}

- (void)refresh{
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
        if ([self hasChanges]) {
            NSLog(@"*** The MO (%@) you are trying to refresh HAS CHANGES, which makes the process UNSAFE!", self.entity.name);
        }
        
//        if (!self.isOutDated) {
//            NSLog(@"MO %@(%@) skipped refresh because up to date (%@)", self.entity.name, [self valueForKey:kUpdatedDateKey], self.serverID);
//            return;
//        }
        NSLog(@"===> Refreshing MO %@", self.entity.name);
        PFObject *object = [self parseObject];
        [self updateValueAndRelationFromParseObject:object];
        [EWDataStore saveToLocal:self];
    }
}

- (void)refreshEventually{
	[EWDataStore appendObject:self toQueue:kParseQueueRefresh];
}

- (void)refreshRelatedInBackground{
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
                [MO refreshInBackgroundWithCompletion:^{
                    NSLog(@"Relation %@(%@) -> %@(%@) refreshed in background", self.entity.name, [self valueForKey:kParseObjectID], description.destinationEntity.name, [relatedMOs valueForKey:kParseObjectID]);
                }];
            }
        }else{
            NSManagedObject *MO = [self valueForKey:key];
            [MO refreshInBackgroundWithCompletion:^{
                NSLog(@"Relation %@(%@) -> %@(%@) refreshed in background", self.entity.name, [self valueForKey:kParseObjectID], description.destinationEntity.name, [MO valueForKey:kParseObjectID]);
            }];
        }
    }];
}

- (void)refreshShallowWithCompletion:(void (^)(void))block{
    if (![EWDataStore sharedInstance].reachability.isReachable) {
		NSLog(@"Network not reachable, refresh later.");
		//refresh later
		[self refreshEventually];
		return;
	}
	
    if (!self.isOutDated) {
        return;
    }
    
    NSManagedObjectID *ID = self.objectID;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSError *err;
        NSManagedObject *backMO = [localContext existingObjectWithID:ID error:&err];
        if (err) {
            NSLog(@"*** Failed to get back MO: %@", err.description);
            return ;
        }
        
        //Get PO from server, also add inlcude key for pointer
        PFObject *PO = self.parseObject;
        
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
        
        block();
        
    }];
    
}


- (void)assignValueFromParseObject:(PFObject *)object{
    [object fetchIfNeeded];
    if (!object.isDataAvailable) {
        NSLog(@"*** The PO %@(%@) you passed in doesn't have any data. Deleted from server?", object.parseClassName, object.objectId);
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
            [self setPFFile:parseValue forPropertyDescription:obj];
            
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
    
    [EWDataStore saveToLocal:self];
}


- (void)setPFFile:(PFFile *)file forPropertyDescription:(NSAttributeDescription *)attributeDescription{
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		NSError *error;
		NSData *data = [file getData:&error];
		//[file getDataWithBlock:^(NSData *data, NSError *error) {
		if (error || !data) {
			NSLog(@"@@@ Failed to download PFFile: %@", error.description);
			return;
		}
		NSManagedObject *localSelf = [localContext objectWithID:self.objectID];
		NSString *className = [localSelf getPropertyClassByName:attributeDescription.name];
		if ([className isEqualToString:@"UIImage"]) {
			UIImage *img = [UIImage imageWithData:data];
			[localSelf setValue:img forKey:attributeDescription.name];
		}
		else{
			[localSelf setValue:data forKey:attributeDescription.name];
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
    [EWDataStore appendDeleteQueue:po];

    //delete
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext deleteObject:self];
    }];
}


- (NSArray *)valueToUpload{
	NSMutableArray *changes = self.changedValues.allKeys.mutableCopy;
	[changes removeObjectsInArray:attributeUploadSkipped];
	if (changes.count > 0) {
		return changes;
	}
	return nil;
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
	
    NSParameterAssert([managedObject valueForKey:kParseObjectID]);
    NSDate *updateAt = [managedObject valueForKeyPath:kUpdatedDateKey];
    if (updateAt && [self.updatedAt timeIntervalSinceDate:updateAt] > kStalelessInterval) {
        NSLog(@"@@@ Trying to update MO %@, but PO is newer! Please check the code.(%@ -> %@)", managedObject.entity.name, updateAt, self.updatedAt);
        return;
    }

//    NSArray *changeValues = [[[EWDataStore sharedInstance].changesDictionary objectForKey:mo.objectID.URIRepresentation.absoluteString] allKeys];
//    if (!changeValues) {
//        changeValues = attributeDescriptions.allKeys;
//    }
    [managedObject.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *obj, BOOL *stop) {
//        if (![changeValues containsObject:key]){
//            NSLog(@"!!! MO attribute %@(%@)->%@ omitted", mo.entity.name, [mo valueForKey:kParseObjectID], obj.name);
//            return;
//        }
        
        //check if changed
        if (key.skipUpload) {
            return;
        }
        
        id value = [managedObject valueForKey:key];
        
        //there could have some optimization that checks if value equals to PFFile value, and thus save some network calls. But in order to compare there will be another network call to fetch, the the comparison is redundant.
        if ([value isKindOfClass:[NSData class]]) {
            //data
			EWPerson *localMe = (EWPerson *)[localContext objectWithID:me.objectID];
			NSString *fileName = [NSString stringWithFormat:@"%@.m4a", localMe.name];
            PFFile *dataFile = [PFFile fileWithName:fileName data:value];
            [self setObject:dataFile forKey:key];
        }else if ([value isKindOfClass:[UIImage class]]){
            //image
            PFFile *dataFile = [PFFile fileWithName:@"Image.png" data:UIImagePNGRepresentation((UIImage *)value)];
            //[dataFile saveInBackground];//TODO: handle file upload exception
            [self setObject:dataFile forKey:key];
        }else if ([value isKindOfClass:[CLLocation class]]){
            //location
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
    
    //relation
    NSMutableDictionary *mutableRelationships = [managedObject.entity.relationshipsByName mutableCopy];
    [mutableRelationships enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
        id relatedManagedObjects = [managedObject valueForKey:key];
        if (relatedManagedObjects){
            if ([obj isToMany]) {
                //To-Many relation
                //Determine array or relation
                if (!obj.inverseRelationship) {
                    //No inverse relation, use array of pointer
                    
                    NSSet *relatedMOs = [managedObject valueForKey:key];
                    NSMutableArray *relatedPOs = [NSMutableArray new];
                    for (NSManagedObject *MO in relatedMOs) {
                        PFObject *PO = [PFObject objectWithoutDataWithClassName:MO.entity.serverClassName objectId:[MO valueForKey:kParseObjectID]];
                        [relatedPOs addObject:PO];
                    }
                    [self setObject:[relatedPOs copy] forKey:key];
                    return;
                }
                PFRelation *parseRelation = [self relationForKey:key];
                //Find related PO to delete async
                [[parseRelation query] findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    NSMutableArray *relatedParseObjects = [objects mutableCopy];
                    if (relatedParseObjects.count) {
                        NSArray *relatedParseObjectsToDelete = [relatedParseObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT %K IN %@", kParseObjectID, [relatedManagedObjects valueForKey:@"objectId"]]];
                        for (PFObject *PO in relatedParseObjectsToDelete) {
                            [parseRelation removeObject:PO];
                            
                            NSLog(@"~~~> To-many relation on PO %@(%@)->%@(%@) deleted when update from MO", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], obj.name, PO.objectId);
                        }
                        //save
                        if (relatedParseObjectsToDelete.count) {
                            [self saveInBackground];
                        }
                    }
                }];
                
                //related managedObject that needs to add
                for (NSManagedObject *relatedManagedObject in relatedManagedObjects) {
                    NSString *parseID = relatedManagedObject .serverID;
                    if (parseID) {
                        //the pfobject already exists, need to inspect PFRelation to determin add or remove
                        
                        PFObject *relatedParseObject = [PFObject objectWithoutDataWithClassName:relatedManagedObject.entity.serverClassName objectId:parseID];
                        //[relatedParseObject fetchIfNeeded];
                        [parseRelation addObject:relatedParseObject];
                        
                    } else {
                        __block PFObject *blockObject = self;
                        __block PFRelation *blockParseRelation = parseRelation;
                        //set up a saving block
                        NSLog(@"Relation %@ -> %@ save block setup", blockObject.parseClassName, relatedManagedObject.entity.serverClassName);
                        PFObjectResultBlock connectRelationship = ^(PFObject *object, NSError *error) {
                            //the relation can only be additive, which is not a problem for new relation
                            [blockParseRelation addObject:object];
                            [blockObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                NSLog(@"Relation %@ -> %@ (%@) established", blockObject.parseClassName, object.parseClassName, object.objectId);
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
                        [EWDataStore appendInsertQueue:relatedManagedObject];
                    }
                }
            } else {
                //TO-One relation
                NSManagedObject *relatedManagedObject = [managedObject valueForKey:key];
                NSString *parseID = relatedManagedObject.serverID;
                if (parseID) {
                    PFObject *relatedParseObject = relatedManagedObject.parseObject;
                    [self setObject:relatedParseObject forKey:key];
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
                    [EWDataStore addSaveCallback:connectRelationship forManagedObjectID:relatedManagedObject.objectID];
                }
            }
        }else{
            //empty related object, delete PO relationship
            if ([self valueForKey:key]) {
                NSParameterAssert(!obj.isToMany);//relation cannot be to-many, as it's always has value
                NSLog(@"Empty relationship on MO %@(%@) -> %@, delete PO relation.", managedObject.entity.name, self.objectId, obj.name);
                
                NSRelationshipDescription *inverseRelation = obj.inverseRelationship;
                PFObject *inversePO = self[key];
				if ([inversePO isKindOfClass:[EWPerson class]]) {
					NSLog(@"*** Something wrong, we should not modify any relation with other user. MO: %@", inversePO);
					return;
				}
                if (inverseRelation.isToMany) {
                    //inverse to-many relation need to be updated
                    [inversePO fetchIfNeeded];
                    PFRelation *inversePFRelation = inversePO[inverseRelation.name];
                    [inversePFRelation removeObject:self];
                    [inversePO save:nil];
                    NSLog(@"~~~> Removed inverse to-many relation: %@ -> %@", self.parseClassName, inversePO.parseClassName);
                }else{
                    //to-one
                    [inversePO removeObjectForKey:inverseRelation.name];
                }
                
                [self removeObjectForKey:key];
            }
        }
        
    }];
    //Only save when network is available so that MO can link with PO
    //[self saveEventually];
}

- (NSManagedObject *)managedObjectInContext:(NSManagedObjectContext *)context{

    NSManagedObject *mo = [NSClassFromString(self.localClassName) MR_findFirstByAttribute:kParseObjectID withValue:self.objectId inContext:context];
    
    if (!mo) {
        //if managedObject not exist, create it locally
        mo = [NSClassFromString(self.localClassName) MR_createInContext:context];
        [mo assignValueFromParseObject:self];
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
	NSManagedObject *mo = [NSClassFromString(self.localClassName) MR_findFirstByAttribute:kParseObjectID withValue:self.objectId];
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
