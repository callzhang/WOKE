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
#import "EWDownloadManager.h"
#import "EWAlarmManager.h"
#import "EWTaskStore.h"
#import "EWMediaStore.h"
#import "EWMediaItem.h"
#import "NSString+MD5.h"
#import "EWWakeUpManager.h"
#import "EWServer.h"

#define MR_LOGGING_ENABLED 0
#import <MagicalRecord/CoreData+MagicalRecord.h>

//Util
#import "FTWCache.h"

#pragma mark - 
#define kServerTransformTypes               @{@"CLLocation": @"PFGeoPoint"} //localType: serverType
#define kServerTransformClasses             @{@"EWPerson": @"_User"} //localClass: serverClass
#define kUserClass                          @"EWPerson"
#define classSkipped                        @[@"EWPerson"]
#define attributeUploadSkipped              @[kParseObjectID, kUpdatedDateKey, kCreatedDateKey, @"score"]

@interface EWDataStore()
@property NSManagedObjectContext *context; //the main context(private), only expose 'currentContext' as a class method
@property (nonatomic) NSMutableDictionary *parseSaveCallbacks;
@property (nonatomic) NSTimer *saveToServerDelayTimer;
@property (nonatomic) NSMutableDictionary *changesDictionary;
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
        coredata_queue = dispatch_queue_create("com.wokealarm.datastore.coreDataQueue", DISPATCH_QUEUE_SERIAL);
        
        //AWS
        //snsClient = [[AmazonSNSClient alloc] initWithAccessKey:AWS_ACCESS_KEY_ID withSecretKey:AWS_SECRET_KEY];
        //snsClient.endpoint = [AmazonEndpoints snsEndpoint:US_WEST_2];
        
        
        
        //core data
        //[MagicalRecord setLoggingMask:MagicalRecordLoggingMaskError];
        [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Woke"];
        context = [NSManagedObjectContext MR_defaultContext];
        //observe context change to update the modifiedData of that MO. (Only observe the main context)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateModifiedDate:) name:NSManagedObjectContextObjectsDidChangeNotification object:context];
        //Observe context save to update the update/insert/delete queue
        //This turns out to be not possible because there are actions that need to save to local be not update to server
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addToQueueUpOnSaving:) name:NSManagedObjectContextDidSaveNotification object:context];
        
        //facebook
        [PFFacebookUtils initializeFacebook];
        
        //cache policy
        //network chenge policy
        //refesh failure behavior

        //watch for login event
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDataCheck) name:kPersonLoggedIn object:Nil];
        
        //change dic
        self.changesDictionary = [NSMutableDictionary new];
        self.parseSaveCallbacks = [NSMutableDictionary dictionary];
        self.saveCallbacks = [NSMutableArray new];
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
    
    
    //refresh current user
    NSLog(@"1. Register AWS push key");
    [EWServer registerAPNS];
    
    //check alarm, task, and local notif
    NSLog(@"2. Check alarm");
    [[EWAlarmManager sharedInstance] scheduleAlarm];
    
    NSLog(@"3. Check task");
    [[EWTaskStore sharedInstance] scheduleTasks];
    [EWTaskStore.sharedInstance checkScheduledNotifications];
    
    NSLog(@"4. Check my unread media");
    [[EWMediaStore sharedInstance] checkMediaAssets];
    
    //updating facebook friends
    NSLog(@"5. Updating facebook friends");
    [EWUserManagement getFacebookFriends];
    
    //update facebook info
    NSLog(@"6. Updating facebook info");
    [EWUserManagement updateFacebookInfo];
    
    //Update my relations
    NSLog(@"7. Refresh my relation in background");
    [me refreshRelatedInBackground];
    
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
    [EWUserManagement updateLastSeen];
    
    //location
    NSLog(@"[2] Start location recurring update");
    [EWUserManagement registerLocation];
    
    //check task
    NSLog(@"[3] Start recurring task schedule");
    [[EWTaskStore sharedInstance] scheduleTasks];
    
    //check alarm timer
    NSLog(@"[4] Start recurring alarm timer check");
    [EWWakeUpManager alarmTimerCheck];
    //});
    
}



#pragma mark - Core Data Threading
+ (NSManagedObject *)objectForCurrentContext:(NSManagedObject *)obj{
    
    if (obj == nil) {
        NSLog(@"Passed in nil to get current MO");
        return nil;
    }
    
    //check thread save
    if ([obj.managedObjectContext isEqual:[EWDataStore currentContext]]) {
        return obj;
    }
    //get objectID
    __block NSManagedObjectID *objectID;
    [obj.managedObjectContext performBlockAndWait:^{
        objectID = obj.objectID;
        if (!objectID || objectID.isTemporaryID) {
            
            //need to save the MO to get the ID
            if ([obj.managedObjectContext isEqual:[EWDataStore sharedInstance].context]) {
                [EWDataStore saveToLocal:obj];
            }else{
                [obj.managedObjectContext saveToPersistentStoreAndWait];
            }
        }
    }];
    
    if (!objectID) {
        NSLog(@"*** failed to get the ID, return UNSAFE MO %@(%@)", obj.entity.name, [obj valueForKey:kParseObjectID]);
        return obj;
    }
    
    NSError *error;
    NSManagedObject * objForCurrentContext = [[EWDataStore currentContext] existingObjectWithID:objectID error:&error];
    if (error) {
        NSLog(@"*** Error getting exsiting MO %@(%@)", obj.entity.name, obj.objectID);
        return obj;
    }
    return objForCurrentContext;
}


+ (void)save{
    
    NSManagedObjectContext *context = [EWDataStore sharedInstance].context;
    NSSet *inserts = [context insertedObjects];
    NSSet *updates = [context updatedObjects];
    NSSet *deletes = [context deletedObjects];
    
    if (inserts.count || updates.count || deletes.count) {
        for (NSManagedObject *MO in inserts) {
            NSString *serverID = [MO valueForKey:kParseObjectID];
            if (serverID) {
                NSLog(@"MO %@ has serverID, means it is fetched from server, skip!", MO.entity.name);
                continue;
            }
            NSLog(@"+++> MO %@ inserted to context", MO.entity.name);
            [EWDataStore appendInsertQueue:MO];
        }
        for (NSManagedObject *MO in updates) {
            //skip if updatedMO contained in insertedMOs
            if ([inserts containsObject:MO]) {
                continue;
            }
            //check if updated keys are valid
            NSMutableArray *changedKeys = MO.changedValues.allKeys.mutableCopy;
            [changedKeys removeObjectsInArray:attributeUploadSkipped];
            if (changedKeys.count > 0) {
                NSLog(@"===> MO %@(%@) updated to context with changes: %@", MO.entity.name, [MO valueForKey:kParseObjectID], changedKeys);
                [EWDataStore appendUpdateQueue:MO];
            }
            
        }
        for (NSManagedObject *MO in deletes) {
            NSLog(@"~~~> MO %@ deleted to context", MO.entity.name);
            PFObject *PO = [MO parseObject];
            [EWDataStore appendDeleteQueue:PO];
        }
        [context saveToPersistentStoreAndWait];
        
        if ([EWDataStore workingQueue].count > 0) {
            NSLog(@"@@@ Executing an UPLOAD action while there are still objects in working queue");
        }
        
        [[EWDataStore sharedInstance].saveToServerDelayTimer invalidate];
        [EWDataStore sharedInstance].saveToServerDelayTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateToServer) userInfo:nil repeats:NO];
        
    }
    
}

+ (void)saveWithCompletion:(EWSavingCallback)block{
    [[EWDataStore sharedInstance].saveCallbacks addObject:block];
    [EWDataStore save];
}

+ (void)saveToLocal:(NSManagedObject *)mo{
    if(![NSThread isMainThread]){
        [[NSManagedObjectContext contextForCurrentThread] saveToPersistentStoreAndWait];
    }
    //pre save check
    NSArray *updates  = [[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueUpdate];
    NSArray *inserts  = [[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueUpdate];
    NSString *ID = mo.objectID.URIRepresentation.absoluteString;
    NSArray *u = [updates filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@", ID]];
    NSArray *i = [inserts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@", ID]];
    if (u.count) {
        NSLog(@"!!! The object %@ you are trying to update from PO is already in the update queue. Check your code! (%@)", mo.entity.name, ID);
    }
    if (i.count) {
        NSLog(@"!!! The object %@ you are trying to insert from PO is already in the insert queue. Check your code! (%@)", mo.entity.name, ID);
    }
    
    //check if update in process
    BOOL updating = [[EWDataStore sharedInstance].saveToServerDelayTimer isValid];
    //save to enqueue the updates
    [EWDataStore save];
    
    //remove from the update queue
    [EWDataStore removeObjectFromInsertQueue:mo];
    [EWDataStore removeObjectFromUpdateQueue:mo];
    
    //cancel update
    if (!updating) {
        [[EWDataStore sharedInstance].saveToServerDelayTimer invalidate];
    }
}

+ (NSManagedObjectContext *)currentContext{
    return [NSManagedObjectContext contextForCurrentThread];
}


#pragma mark - Server Updating Queue methods
//update queue
+ (NSSet *)updateQueue{
    return [EWDataStore getObjectFromQueue:kParseQueueUpdate];
}

+ (void)appendUpdateQueue:(NSManagedObject *)mo{
    NSManagedObjectID *objectID = mo.objectID;
    if ([objectID isTemporaryID]) {
        [mo.managedObjectContext obtainPermanentIDsForObjects:@[mo] error:NULL];
        objectID = mo.objectID;
    }
    //Add changed attributes minus skipped ones to changes dic
    NSString *str = objectID.URIRepresentation.absoluteString;
    NSMutableDictionary *changeDic = [[mo changedValues] mutableCopy];
    [changeDic removeObjectsForKeys:attributeUploadSkipped];
    [changeDic addEntriesFromDictionary:[[EWDataStore sharedInstance].changesDictionary objectForKey:str]];
    if (changeDic) {
        [[EWDataStore sharedInstance].changesDictionary setObject:[changeDic copy] forKey:objectID];
    }
    
    //skip if included in insert queue
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueInsert];
    if ([array containsObject:str]) {
        NSLog(@"MO %@(%@) insertion to update queue skipped because it is contained in insert queue", mo.entity.name, [mo valueForKey:kParseObjectID]);
        return;
    }
    
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
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:queue];
    NSMutableSet *set = [NSMutableSet new];
    for (NSString *str in array) {
        NSURL *url = [NSURL URLWithString:str];
        NSManagedObjectID *ID = [[EWDataStore currentContext].persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
        if (!ID) {
            NSLog(@"@@@ ManagedObjectID not found: %@", url);
            continue;
        }
        NSManagedObject *MO = [[EWDataStore currentContext] objectWithID:ID];
        [set addObject:MO];
    }
    return [set copy];
}

+ (void)appendObject:(NSManagedObject *)mo toQueue:(NSString *)queue{
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
        NSLog(@"MO %@(%@) add to %@", mo.entity.name, [mo valueForKey:kParseObjectID], queue);
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

#pragma mark - Parse Server methods
+(void)updateToServer{
    //make sure it is called on main thread
    NSParameterAssert([NSThread isMainThread]);
    if([[NSManagedObjectContext contextForCurrentThread] hasChanges]){
        NSLog(@"There is still some change when updating to server, save and do it later");
        [EWDataStore save];
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
    
    
    NSLog(@"============ Start updating to server =============== \n Inserts:%@, \n Updates:%@ \n and Deletes:%@ \n ==============================", [insertedManagedObjects valueForKey:kParseObjectID], [updatedManagedObjects valueForKey:kParseObjectID], deletedServerObjects);
    
    
    NSArray *callbacks = [[EWDataStore sharedInstance].saveCallbacks copy];
    [[EWDataStore sharedInstance].saveCallbacks removeAllObjects];

    //start background update
    dispatch_async([EWDataStore sharedInstance].dispatch_queue, ^{
        
        for (NSManagedObjectID *ID in workingObjectIDs) {
            [EWDataStore updateParseObjectFromManagedObjectID:ID];
        }
        
        for (PFObject *po in deletedServerObjects) {
            NSLog(@"~~~> Deleting PO %@ (%@)", po.parseClassName, po.objectId);
            [EWDataStore deleteParseObject:po];
        }
        
        //completion block
        dispatch_async(dispatch_get_main_queue(), ^{
            for (EWSavingCallback block in callbacks){
                block();
            }
        });
    });
}
#pragma mark -


+ (void)updateParseObjectFromManagedObjectID:(NSManagedObjectID *)managedObjectID{
    NSError *error;
    NSManagedObject *mo = [[NSManagedObjectContext contextForCurrentThread] existingObjectWithID:managedObjectID error:&error];
    if (!mo) {
        NSLog(@"Object not found for ID %@", managedObjectID);
        return;
    }
    
    //skip if updating other PFUser
    //TODO: Set ACL for PFUser to enable public writability
    if ([mo isKindOfClass:[EWPerson class]]) {
        if (![(EWPerson *)mo isMe]) {
            NSLog(@"Skip updating other PFUser: %@", [(EWPerson *)mo name]);
            [EWDataStore removeObjectFromWorkingQueue:mo];
            return;
        }
    }
    
    NSString *parseObjectId = [mo valueForKey:kParseObjectID];
    PFObject *object;
    if (parseObjectId) {
        //download
        NSError *err;
        object =[mo getParseObjectWithError:&err];
        
        if (!object) {
            //TODO: handle error
            if ([err code] == kPFErrorObjectNotFound) {
                NSLog(@"PO couldn't be found %@!", mo.entity.serverClassName);
                // Now also check for connection errors:
                //delete ParseID from MO
                NSManagedObjectID *ID = mo.objectID;
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                    NSManagedObject *localMO = [localContext objectWithID:ID];
                    [localContext deleteObject:localMO];
                    NSLog(@"MO %@ deleted", mo.entity.name);
                }];
            } else if ([err code] == kPFErrorConnectionFailed) {
                NSLog(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                [mo updateEventually];
            } else if (err) {
                NSLog(@"*** Error in getting related parse object from MO (%@). \n Error: %@", mo.entity.name, [err userInfo][@"error"]);
                [mo updateEventually];
            }
            
            return;
        }
        
    } else {
        //insert
        object = [PFObject objectWithClassName:mo.entity.serverClassName];
        [object save:&error];//need to save before working on PFRelation
        if (!error) {
            NSLog(@"+++> CREATED PO %@(%@)", object.parseClassName, object.objectId);
            [mo setValue:object.objectId forKey:kParseObjectID];
            [mo setValue:object.updatedAt forKeyPath:kUpdatedDateKey];
        }else{
            [mo updateEventually];
            return;
        }
        
    }
    
    //==========set Parse value/relation and callback block===========
    [object updateFromManagedObject:mo];
    //================================================================
    

    [object save:&error];
    if (!error) {
        
        if (parseObjectId) {
            NSLog(@"---------> PO updated to server: %@(%@)", mo.entity.serverClassName, [mo valueForKey:kParseObjectID]);
        }else{
            NSLog(@"=========> PO created: %@(%@)", mo.entity.serverClassName,[mo valueForKey:kParseObjectID]);
        }
        
        //assign connection between MO and PO
        [EWDataStore performSaveCallbacksWithParseObject:object andManagedObjectID:mo.objectID];
        [[EWDataStore currentContext] saveToPersistentStoreAndWait];
        
        
        //remove from queue
        [EWDataStore removeObjectFromWorkingQueue:mo];
    } else {
        NSLog(@"Failed to save server object: %@", error.description);
        
    }
    
    //time stamp for updated date. This is very important.
    [mo setValue:[NSDate date] forKey:kUpdatedDateKey];

}

+ (void)deleteParseObject:(PFObject *)parseObject{
    [parseObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (succeeded) {
            //Good
            [EWDataStore removeDeleteQueue:parseObject];
            
        }else if (error.code == kPFErrorObjectNotFound){
            //fine
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

- (void)updateModifiedDate:(NSNotification *)notification{
    NSSet *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
    
    //NSLog(@"Observed %lu ManagedObject changed, updating 'UpdatedAt'.", (unsigned long)updatedObjects.count);
    for (NSManagedObject *mo in updatedObjects) {
        double interval = [[mo valueForKey:kUpdatedDateKey] timeIntervalSinceNow];
        if (interval < -1) {
            //update time
            [mo setValue:[NSDate date] forKeyPath:kUpdatedDateKey];
        }
    }
}

//- (void)addToQueueUpOnSaving:(NSNotification *)notification{
//    NSParameterAssert([NSThread isMainThread]);
//    NSSet *inserts = notification.userInfo[NSInsertedObjectsKey];
//    NSSet *updates = notification.userInfo[NSUpdatedObjectsKey];
//    NSSet *deletes = notification.userInfo[NSDeletedObjectsKey];
//    if (inserts.count || updates.count || deletes.count) {
//        for (NSManagedObject *MO in inserts) {
//            NSLog(@"+++> MO %@ inserted to context", MO.entity.name);
//            [self appendInsertQueue:MO];
//        }
//        for (NSManagedObject *MO in updates) {
//            NSLog(@"===> MO %@ updated to context", MO.entity.name);
//            [self appendUpdateQueue:MO];
//        }
//        for (NSManagedObject *MO in deletes) {
//            NSLog(@"---> MO %@ deleted to context", MO.entity.name);
//            PFObject *PO = [MO parseObject];
//            if (PO) {
//                [self appendDeleteQueue:PO];
//            }
//        }
//        [EWDataStore save];
//    }
//}


@end



#pragma mark - Core Data ManagedObject extension
@implementation NSManagedObject (PFObject)
#import <objc/runtime.h>

- (void)updateValueAndRelationFromParseObject:(PFObject *)parseObject{
    if (!parseObject) {
        NSLog(@"*** The MO %@ doesn't not has server key, please check", self.entity.name);
        return;
    }
    
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
                    [relatedMOs addObject:PO.managedObject];
                }
                [self setValue:[relatedMOs copy] forKey:key];
                return ;
            }
            
            //Fetch PFRelation for normal relation
            PFRelation *toManyRelation;
            @try{
                toManyRelation = [parseObject relationForKey:key];
            }
            @catch (NSException *exception) {
                NSLog(@"Failed to assign value of key: %@ from Parse Object %@ to ManagedObject %@ \n Error: %@", key, parseObject, self, exception.description);
                return;
            }
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
                NSManagedObject *relatedManagedObject = [object managedObject];
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
                NSManagedObject *relatedManagedObject = [relatedParseObject managedObject];
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
    return [self getParseObjectWithError:nil];
}

- (PFObject *)getParseObjectWithError:(NSError **)err{
    NSString *parseObjectId = [self valueForKey:kParseObjectID];
    
    if (parseObjectId) {
        PFObject *object;
        //download
        NSDate *updatedAt = (NSDate *)[self valueForKey:kUpdatedDateKey];
        //try to get the object locally first if not outdated
        if (![updatedAt isOutDated]) {
            object = [PFObject objectWithoutDataWithClassName:self.entity.serverClassName objectId:parseObjectId];
            [object fetchIfNeeded];
        }else{
            //if local mo is outdated, query from server
            PFQuery *query = [PFQuery queryWithClassName:self.entity.serverClassName];
            if ([self isKindOfClass:[EWPerson class]]) {
                NSLog(@"Fetching User %@ with keys", [self valueForKey:@"name"]);
                [query includeKey:@"friends"];
                [query includeKey:@"mediaAssets"];
                [query includeKey:@"tasks"];
                [query includeKey:@"alarms"];
            }
            object = [query getObjectWithId:parseObjectId error:err];
        }
        return object;
    }else{
        NSLog(@"!!! ParseObjectID not exist, upload first!");
        return nil;
    }
    
    return nil;
}

- (void)refreshInBackgroundWithCompletion:(void (^)(void))block{
    NSParameterAssert([NSThread isMainThread]);
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
            NSLog(@"*** The MO (%@) you are trying to refresh HAS CHANGES, which makes the process UNSAFE!", self.entity.name);
        }
        
        NSDate *updatedAt = [self valueForKey:kUpdatedDateKey];
        if (updatedAt && ![updatedAt isOutDated] && ![self isKindOfClass:[EWPerson class]]) {
            NSLog(@"MO %@(%@) is not out dated, skip refresh in background", self.entity.name, [self valueForKey:kParseObjectID]);
            return;
        }
        
        NSManagedObjectID *objectID = self.objectID;
        
        //save async
        dispatch_async([EWDataStore sharedInstance].dispatch_queue, ^{
            
            NSManagedObjectContext *localContext = [EWDataStore currentContext];
            NSManagedObject *currentMO = [localContext objectWithID:objectID];
            
            NSLog(@"===> Refreshing %@ (%@) in background", self.entity.name, [self valueForKey:kParseObjectID]);
            
            PFObject *object = currentMO.parseObject;
            [currentMO updateValueAndRelationFromParseObject:object];
            [localContext saveToPersistentStoreAndWait];
            
            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block();
                });
                
            }
        });
    }
}

- (void)refresh{
    //NSParameterAssert([NSThread isMainThread]);
    
    NSString *parseObjectId = [self valueForKey:kParseObjectID];
    
    if (!parseObjectId) {
        NSParameterAssert([self isInserted]);
        NSLog(@"+++> Insert MO %@ from refresh", self.entity.name);
        [self updateEventually];
        [EWDataStore save];
    }else{
        if ([self hasChanges]) {
            NSLog(@"*** The MO (%@) you are trying to refresh HAS CHANGES, which makes the process UNSAFE!", self.entity.name);
        }
        
        NSDate *updatedDate = [self valueForKey:kUpdatedDateKey];
        if (updatedDate && [updatedDate isOutDated] == NO) {
            NSLog(@"MO %@ skipped refresh because not outdated (%@)", self.entity.name, updatedDate);
            return;
        }
        NSLog(@"===> Refreshing MO %@", self.entity.name);
        PFObject *object = [self parseObject];
        [self updateValueAndRelationFromParseObject:object];
        [EWDataStore saveToLocal:self];
    }
}

- (void)refreshRelatedInBackground{
    
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
                [MO refreshInBackgroundWithCompletion:^{
                    NSLog(@"Relation %@ -> %@ refreshed in background", self.entity.name, description.destinationEntity.name);
                }];
            }
        }else{
            NSManagedObject *MO = [self valueForKey:key];
            [MO refreshInBackgroundWithCompletion:^{
                NSLog(@"Relation %@ -> %@ refreshed in background", self.entity.name, description.destinationEntity.name);
            }];
        }
    }];
}


- (void)assignValueFromParseObject:(PFObject *)object{
    [object fetchIfNeeded];
    if ([self valueForKey:kParseObjectID]) {
        NSParameterAssert([[self valueForKey:kParseObjectID] isEqualToString:object.objectId]);
    }else{
        [self setValue:object.objectId forKey:kParseObjectID];
    }
    //attributes
    NSDictionary *managedObjectAttributes = self.entity.attributesByName;
    NSArray *allKeys = object.allKeys;
    //add or delete some attributes here
    [managedObjectAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *obj, BOOL *stop) {
        if (![allKeys containsObject:key]) {
            //NSLog(@"Key %@ does not exist on PO %@", key, object.parseClassName);
            return;//skip if not exist
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
                [self setValue:parseValue forKey:key];
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
    
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (error || !data) {
            NSLog(@"@@@ Failed to download PFFile: %@", error.description);
            return;
        }
        NSString *className = [self getPropertyClassByName:attributeDescription.name];
        if ([className isEqualToString:@"UIImage"]) {
            UIImage *img = [UIImage imageWithData:data];
            [self setValue:img forKey:attributeDescription.name];
        }
        else{
            [self setValue:data forKey:attributeDescription.name];
        }
    }];
    
}

- (void)updateEventually{
    BOOL hasParseObjectLinked = !![self valueForKey:kParseObjectID];
    if (hasParseObjectLinked) {
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
    PFObject *po = self.parseObject;
    if (!po) {
        return;
    }
    NSLog(@"%s: delete %@ eventually", __func__, self.entity.name);
    [EWDataStore appendDeleteQueue:self.parseObject];

    //delete
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext deleteObject:self];
    }];
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
    BOOL outdated = [date isOutDated];
    return outdated;
}


@end

#pragma mark - Parse Object extension
@implementation PFObject (NSManagedObject)
- (void)updateFromManagedObject:(NSManagedObject *)managedObject{
    NSManagedObject *mo = [EWDataStore objectForCurrentContext:managedObject];
    NSParameterAssert([mo valueForKey:kParseObjectID]);
    NSDate *updateAt = [mo valueForKeyPath:kUpdatedDateKey];
    if (updateAt && [self.updatedAt timeIntervalSinceDate:updateAt] > 60) {
        NSLog(@"@@@ Trying to update MO %@, but PO is newer! Please check the code.(%@ -> %@)", mo.entity.name, updateAt, self.updatedAt);
        NSParameterAssert(YES);
        return;
    }

    
    NSDictionary *attributeDescriptions = [mo.entity.attributesByName mutableCopy];
    NSArray *changeValues = [[[EWDataStore sharedInstance].changesDictionary objectForKey:mo.objectID.URIRepresentation.absoluteString] allKeys];
    if (!changeValues) {
        changeValues = attributeDescriptions.allKeys;
    }
    [attributeDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *obj, BOOL *stop) {
//        if (![changeValues containsObject:key]){
//            NSLog(@"!!! MO attribute %@(%@)->%@ omitted", mo.entity.name, [mo valueForKey:kParseObjectID], obj.name);
//            return;
//        }
        
        id value = [mo valueForKey:key];
        
        //there could have some optimization that checks if value equals to PFFile value, and thus save some network calls. But in order to compare there will be another network call to fetch, the the comparison is redundant.
        if ([value isKindOfClass:[NSData class]]) {
            //data
            PFFile *dataFile = [PFFile fileWithData:value];
            //[dataFile saveInBackground];
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
        }else if(value){
            //check if changed
            NSArray *attributes = attributeUploadSkipped;
            if ([attributes containsObject:obj.name]) {
                return;
            }
            
            if (![value isEqual:self[key]] && (value || [self valueForKey:key])) {
                NSLog(@"Attribute %@(%@)->%@ is changed from %@ to %@ on MO, assign  to PO", mo.entity.name, [mo valueForKey:kParseObjectID], obj.name, [self valueForKey:key], value);
            }
            [self setObject:value forKey:key];
        }else{
            //value is nil, delete PO value
            [self removeObjectForKey:key];
            //NSLog(@"Attribute %@(%@)->%@ is empty on MO, set nil to PO", mo.entity.name, [mo valueForKey:kParseObjectID], obj.name);
        }
        
    }];
    
    //relation
    NSMutableDictionary *mutableRelationships = [mo.entity.relationshipsByName mutableCopy];
    [mutableRelationships enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
        id relatedManagedObjects = [mo valueForKey:key];
        if (relatedManagedObjects){
            if ([obj isToMany]) {
                //To-Many relation
                //Determine array or relation
                if (!obj.inverseRelationship) {
                    //No inverse relation, use array of pointer
                    
                    NSSet *relatedMOs = [mo valueForKey:key];
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
                        NSArray *relatedParseObjectsToDelete = [relatedParseObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT objectId IN %@", [relatedManagedObjects valueForKey:@"objectId"]]];
                        for (PFObject *PO in relatedParseObjectsToDelete) {
                            [parseRelation removeObject:PO];
                            
                            NSLog(@"~~~> To-many relation on PO %@(%@)->%@(%@) deleted when update from MO", mo.entity.name, [mo valueForKey:kParseObjectID], obj.name, PO.objectId);
                        }
                        //save
                        if (relatedParseObjectsToDelete.count) {
                            [self saveInBackground];
                        }
                    }
                }];
                
                //related managedObject that needs to add
                for (NSManagedObject *relatedManagedObject in relatedManagedObjects) {
                    NSString *parseID = [relatedManagedObject valueForKey:kParseObjectID];
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
                                        [mo updateEventually];
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
                NSManagedObject *relatedManagedObject = [mo valueForKey:key];
                NSString *parseID = [relatedManagedObject valueForKey:kParseObjectID];
                if (parseID) {
                    NSString *parseClass = relatedManagedObject.entity.serverClassName;
                    PFObject *relatedParseObject = [PFObject objectWithoutDataWithClassName:parseClass objectId:parseID];
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
                                    [mo updateEventually];
                                }
                                
                            }
                        }];
                    };
                    //add to global save callback distionary
                    [EWDataStore addSaveCallback:connectRelationship forManagedObjectID:relatedManagedObject.objectID];
                }
            }
        }else{
            //empty relationship, delete PO relationship
            if (self[key]) {
                NSParameterAssert(!obj.isToMany);
                NSLog(@"Empty relationship on MO %@(%@) -> %@, delete PO relation.", managedObject.entity.name, self.objectId, obj.name);
                
                NSRelationshipDescription *inverseRelation = obj.inverseRelationship;
                PFObject *inversePO = self[key];
                if (inverseRelation.isToMany) {
                    //inverse to-many relation need to be updated
                    [inversePO fetchIfNeeded];
                    PFRelation *inversePFRelation = inversePO[inverseRelation.name];
                    [inversePFRelation removeObject:self];
                    [inversePO save];
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

- (NSManagedObject *)managedObject{
    NSManagedObject *mo = [NSClassFromString(self.localClassName) MR_findFirstByAttribute:kParseObjectID withValue:self.objectId];
    
    if (!mo) {
        //if managedObject not exist, create it locally
        mo = [NSClassFromString(self.localClassName) MR_createEntity];
        [mo assignValueFromParseObject:self];
        NSLog(@"+++> MO created: %@ (%@)", self.localClassName, self.objectId);
    }
    //check if need to assign value
    NSDate *updated = [mo valueForKey:kUpdatedDateKey];
    
    if (!updated || [updated isEarlierThan:self.updatedAt]) {
        
        [mo assignValueFromParseObject:self];
        //[EWDataStore saveToLocal:mo];
    }
    
    
    return mo;
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

@end
