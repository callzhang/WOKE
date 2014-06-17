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

#define MR_LOGGING_ENABLED 0
#import <MagicalRecord/CoreData+MagicalRecord.h>

//Util
#import "FTWCache.h"

#pragma mark - 
#define kServerTransformTypes               @{@"CLLocation": @"PFGeoPoint"} //localType: serverType
#define kServerTransformClasses             @{@"EWPerson": @"_User"} //localClass: serverClass

@interface EWDataStore()
@property NSManagedObjectContext *context; //the main context(private), only expose 'currentContext' as a class method
@property (nonatomic) NSMutableDictionary *parseSaveCallbacks;
@property (nonatomic) NSTimer *saveToServerDelayTimer;
@end

@implementation EWDataStore
@synthesize context;
@synthesize model;
@synthesize dispatch_queue, coredata_queue;
@synthesize lastChecked;
//@synthesize snsClient;
@synthesize parseSaveCallbacks;
@synthesize updateQueue, insertQueue, deleteQueue;

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
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateModifiedDate:) name:NSManagedObjectContextObjectsDidChangeNotification object:context];
        //Observe context save to update the update/insert/delete queue
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addToQueueUpOnSaving:) name:NSManagedObjectContextDidSaveNotification object:context];
        
        //facebook
        [PFFacebookUtils initializeFacebook];
        
        //cache policy
        //network chenge policy
        //refesh failure behavior

        //watch for login event
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDataCheck) name:kPersonLoggedIn object:Nil];
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
    if (![currentInstallation[@"username"] isEqualToString: me.username]){
        currentInstallation[@"username"] = me.username;
        [currentInstallation saveInBackground];
    };
    
    //change fetch policy
    //NSLog(@"0. Start sync with server");
    //[self.coreDataStore syncWithServer];
    
    //refresh current user
    NSLog(@"1. Register AWS push key");
    [EWDataStore registerAPNS];
    
    //check alarm, task, and local notif
    NSLog(@"2. Check alarm");
    [[EWAlarmManager sharedInstance] scheduleAlarm];
    
    NSLog(@"3. Check task");
    [[EWTaskStore sharedInstance] scheduleTasks];
    
    NSLog(@"4. Check local notification");
    [EWTaskStore.sharedInstance checkScheduledNotifications];
    
    //updating facebook friends
    NSLog(@"5. Updating facebook friends");
    [EWUserManagement getFacebookFriends];
    
    //update data with timely updates
    [self registerServerUpdateService];
    
}


#pragma mark - PUSH

+ (void)registerAPNS{
    //push
#if TARGET_IPHONE_SIMULATOR
    //Code specific to simulator
#else
    //pushClient = [[SMPushClient alloc] initWithAPIVersion:@"0" publicKey:kStackMobKeyDevelopment privateKey:kStackMobKeyDevelopmentPrivate];
    //register everytime in case for events like phone replacement
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeNewsstandContentAvailability | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
#endif
}

+ (void)registerPushNotificationWithToken:(NSData *)deviceToken{
    
    //Parse: Store the deviceToken in the current Installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
    
    
    
}

#pragma mark - DATA from Amazon S3
+ (NSData *)getRemoteDataWithKey:(NSString *)key{
    if (!key) {
        return nil;
    }
    
    NSData *data = nil;
    
    //s3 file
    if ([key hasPrefix:@"http"]) {
        //read from url
        NSURL *audioURL = [NSURL URLWithString:key];
        NSString *keyHash = [audioURL.absoluteString MD5Hash];
        data = [FTWCache objectForKey:keyHash];
        if (!data) {
            //get from remote
            NSError *err;
            data = [NSData dataWithContentsOfURL:audioURL options:NSDataReadingUncached error:&err];
            if (err) {
                NSLog(@"@@@@@@ Error occured in reading remote content: %@", err);
            }
            [FTWCache setObject:data forKey:keyHash];
        }
        
    }else if ([[NSURL URLWithString:key] isFileURL]){
        //local file
        NSLog(@"string is a local file: %@", key);
        @try {
            data = [NSData dataWithContentsOfFile:key];
        }
        @catch (NSException *exception) {
            //pass by file name only, for main bundle resources
            NSArray *array = [key componentsSeparatedByString:@"."];
            NSAssert(array.count != 2, @"Please provide a file name with extension");
            NSString *filePath = [[NSBundle mainBundle] pathForResource:array[0] ofType:array[1]];
            data = [NSData dataWithContentsOfFile:filePath];
        }
        
    }else if(key.length > 500){
        //string contains data
        data = [key dataUsingEncoding:NSUTF8StringEncoding];
        //TODO: save again.
        NSLog(@"Return the audio key as the data itself, please check!");
        
    }
    
    return data;
}

#pragma mark - local cache

+ (NSString *)localPathForKey:(NSString *)key{
    if (key.length > 500) {
        NSLog(@"*** Something wrong with url, the url contains data");
        return nil;
    }else if ([[NSURL URLWithString:key] isFileURL] || [key hasPrefix:@"/"] || [key hasPrefix:@"\\"]) {
        //NSLog(@"Is local file path, return key directly");
        return key;
    }
    
    NSString *path = [FTWCache localPathForKey:[key MD5Hash]];
    if (!path) {
        //not in local, need to download
        //[[EWDownloadManager sharedInstance] downloadUrl:[NSURL URLWithString:key]];
        return nil;
    }
    return path;
}

+ (void)updateCacheForKey:(NSString *)key withData:(NSData *)data{
    if (!key) {
        key = [[NSDate date] date2numberLongString];
        NSLog(@"Assigned new key %@", key);
    }
    
    if (key.length == 15) {
        [NSException raise:@"Passed in MD5 value" format:@"Please provide original url string"];
    }
    
    NSString *hashKey = [key MD5Hash];
    [FTWCache setObject:data forKey:hashKey];
    
}

+ (NSDate *)lastModifiedDateForObjectAtKey:(NSString *)key{
    if (!key) {
        return nil;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *path = [self localPathForKey:key];
	
	if ([fileManager fileExistsAtPath:path])
	{
		NSDate *modificationDate = [[fileManager attributesOfItemAtPath:path error:nil] objectForKey:NSFileModificationDate];
        return modificationDate;
    }
    return nil;
}

+ (void)deleteCacheForKey:(NSString *)key{
    if (!key) return;
    NSString *path = [self localPathForKey:key];
    if (path){
        NSError *err;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&err];
        if (err) {
            NSLog(@"Delete cache with error: %@", err);
        }
    }
}

#pragma mark - Timely sync
- (void)registerServerUpdateService{
    self.serverUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:kServerUpdateInterval target:self selector:@selector(serverUpdate:) userInfo:nil repeats:0];
    [self serverUpdate:nil];
}
     
- (void)serverUpdate:(NSTimer *)timer{
    //services that need to run periodically
    NSLog(@"%s: Start sync service", __func__);
    
    //dispatch_async(dispatch_queue, ^{
        
        //lsat seen
        NSLog(@"Start last seen recurring task");
        [EWUserManagement updateLastSeen];
        
        //location
        NSLog(@"Start location recurring task");
        [EWUserManagement registerLocation];
        
        //check task
        NSLog(@"Start recurring task schedule");
        [[EWTaskStore sharedInstance] scheduleTasks];
        
        //check alarm timer
        NSLog(@"Start recurring alarm timer check");
        [EWWakeUpManager alarmTimerCheck];
    //});
    
}


#pragma mark - Core Data Threading
//+ (void)saveDataInContext:(void(^)(NSManagedObjectContext *currentContext))block
//{
//	NSManagedObjectContext *currentContext = [EWDataStore currentContext];
//	[currentContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
//	[context setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
//	[context observeContext:currentContext];
//    
//    //execute change block
//    if (block) {
//        block(currentContext);
//    }
//	
//    //save
//	if ([currentContext hasChanges]){
//        //commit save to background context
//		[currentContext saveOnSuccess:^{
//            NSLog(@"Background change saved to context");
//        }onFailure:^(NSError *error) {
//            NSLog(@"Save in background thread context failed");
//        }];
//        //revert the default merge policy for main context
//        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
//	}
//}

//+ (void)saveDataInBackgroundInBlock:(void(^)(NSManagedObjectContext *context))saveBlock completion:(void(^)(void))completion
//{
//	dispatch_async([EWDataStore sharedInstance].coredata_queue, ^{
//		[self saveDataInContext:saveBlock];
//        
//        if (completion) {
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                completion();
//            });
//        }
//	});
//}

//+ (NSManagedObject *)refreshObjectWithServer:(NSManagedObject *)obj{
//    dispatch_sync([EWDataStore sharedInstance].coredata_queue, ^{
//        [self saveDataInContext:^(NSManagedObjectContext *currentContext) {
//            NSManagedObject *newObj = [currentContext objectWithID:obj.objectID];
//            NSLog(@"Fetched obj at background: %@", newObj.class);
//        }];
//    });
//    
//    NSAssert([obj.managedObjectContext isEqual:[EWDataStore currentContext]], @"Current context is not equal to obj's context");
//    
//    obj = [obj.managedObjectContext objectWithID:obj.objectID];
//    return obj;
//}

+ (NSManagedObject *)objectForCurrentContext:(NSManagedObject *)obj{
    
    if (obj == nil) {
        NSLog(@"Passed in nil");
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
            //need to obtain perminent ID
//            NSError *err;
//            NSLog(@"Obtaining perminant ID for %@", obj.entity.name);
//            [obj.managedObjectContext obtainPermanentIDsForObjects:@[obj] error:&err];
//            objectID = obj.objectID;
            //TODO: need to check if data persist to the store
            
            //just save the MO, it's fine now
            [obj.managedObjectContext saveToPersistentStoreAndWait];
        }
    }];
    NSError *error;
    NSManagedObject * objForCurrentContext = [[EWDataStore currentContext] existingObjectWithID:objectID error:&error];
    if (error) {
        NSLog(@"*** Error getting exsiting MO %@", obj.entity.name);
    }
    return objForCurrentContext;
}


+ (void)save{
    NSLog(@"%s", __func__);
    //find updated/inserted/deleted objects in main context
    NSParameterAssert([NSThread isMainThread]);
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
            [[EWDataStore sharedInstance] appendInsertQueue:MO];
        }
        for (NSManagedObject *MO in updates) {
            NSLog(@"===> MO %@ updated to context", MO.entity.name);
            [[EWDataStore sharedInstance] appendUpdateQueue:MO];
        }
        for (NSManagedObject *MO in deletes) {
            NSLog(@"---> MO %@ deleted to context", MO.entity.name);
            PFObject *PO = [MO parseObject];
            if (PO) {
                [[EWDataStore sharedInstance] appendDeleteQueue:PO];
            }
        }
        [context saveToPersistentStoreAndWait];
        
        
        
        [[EWDataStore sharedInstance].saveToServerDelayTimer invalidate];
        
        [EWDataStore sharedInstance].saveToServerDelayTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateToServer) userInfo:nil repeats:NO];
    }
    
}

+ (NSManagedObjectContext *)currentContext{
    return [NSManagedObjectContext MR_contextForCurrentThread];
}


#pragma mark - Server Related Accessor methods
- (NSMutableDictionary *)parseSaveCallbacks{
    if (!parseSaveCallbacks) {
        parseSaveCallbacks = [NSMutableDictionary dictionary];
    }
    return parseSaveCallbacks;
}

//update queue
- (NSSet *)updateQueue{
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueUpdate];
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

- (void)appendUpdateQueue:(NSManagedObject *)mo{
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueUpdate];
    NSMutableSet *set = [[NSMutableSet setWithArray:array] mutableCopy];
    NSManagedObjectID *objectID = mo.objectID;
    if ([objectID isTemporaryID]) {
        [mo.managedObjectContext obtainPermanentIDsForObjects:@[mo] error:NULL];
        objectID = mo.objectID;
    }
    NSString *str = objectID.URIRepresentation.absoluteString;
    [set addObject:str];
    [[NSUserDefaults standardUserDefaults] setValue:[set allObjects] forKey:kParseQueueUpdate];
}

- (void)removeObjectFromUpdateQueue:(NSManagedObject *)mo{
    NSMutableArray *array = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueUpdate] mutableCopy];
    NSManagedObjectID *objectID = mo.objectID;
    NSString *str = objectID.URIRepresentation.absoluteString;
    if ([array containsObject:str]) {
        [array removeObject:str];
        [[NSUserDefaults standardUserDefaults] setValue:[array copy] forKey:kParseQueueUpdate];
        //NSLog(@"Removed object %@ from update queue", mo.entity.name);
    }
}

//insert queue
- (NSSet *)insertQueue{
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueInsert];
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

- (void)appendInsertQueue:(NSManagedObject *)mo{
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueInsert];
    NSMutableSet *set = [[NSMutableSet setWithArray:array] mutableCopy];
    NSManagedObjectID *objectID = mo.objectID;
    if ([objectID isTemporaryID]) {
        [mo.managedObjectContext obtainPermanentIDsForObjects:@[mo] error:NULL];
        objectID = mo.objectID;
    }
    NSString *str = objectID.URIRepresentation.absoluteString;
    [set addObject:str];
    [[NSUserDefaults standardUserDefaults] setObject:[set allObjects] forKey:kParseQueueInsert];
}

- (void)removeObjectFromInsertQueue:(NSManagedObject *)mo{
    NSMutableArray *array = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueInsert] mutableCopy];
    NSManagedObjectID *objectID = mo.objectID;
    NSString *str = objectID.URIRepresentation.absoluteString;
    if ([array containsObject:str]) {
        [array removeObject:str];
        [[NSUserDefaults standardUserDefaults] setValue:[array copy] forKey:kParseQueueInsert];
        //NSLog(@"Removed object %@ from insert queue", mo.entity.name);
    }
}

//DeletedQueue underlying is a dictionary of objectId:className
- (NSSet *)deleteQueue{
    NSDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy];
    NSParameterAssert(!dic || [dic isKindOfClass:[NSDictionary class]]);
    NSMutableSet *set = [NSMutableSet new];
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *ID, NSString *className, BOOL *stop) {
        [set addObject:[PFObject objectWithoutDataWithClassName:className objectId:ID]];
    }];
    return [set copy];
}

- (void)appendDeleteQueue:(PFObject *)object{
    NSMutableDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy];
    [dic setObject:object.parseClassName forKey:object.objectId];
    [[NSUserDefaults standardUserDefaults] setObject:[dic copy] forKey:kParseQueueDelete];
}

- (void)removeDeleteQueue:(PFObject *)object{
    NSMutableDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy];
    [dic removeObjectForKey:object.objectId];
    [[NSUserDefaults standardUserDefaults] setObject:[dic copy] forKey:kParseQueueDelete];
}

#pragma mark - Parse Server methods
#pragma mark -
+(void)updateToServer{
    //make sure it is called on main thread
    NSParameterAssert([NSThread isMainThread]);
    if([[NSManagedObjectContext contextForCurrentThread] hasChanges]){
        NSLog(@"There is still some change when updating to server, save and do it later");
        [EWDataStore save];
        return;
    }
    
    NSLog(@"Start update to server");
    

//    
//    //get a list of ManagedObject to insert/Update/Delete
//    NSMutableSet *insertedManagedObjects = [[NSManagedObjectContext MR_contextForCurrentThread].insertedObjects mutableCopy];
//    NSMutableSet *updatedManagedObjects = [[NSManagedObjectContext MR_contextForCurrentThread].updatedObjects mutableCopy];
//    NSSet *deletedManagedObjects = [NSManagedObjectContext MR_contextForCurrentThread].deletedObjects;
//    
//    //add queue to operation array && save array to queue
//    for (NSManagedObject *MO in insertedManagedObjects) {
//        [[EWDataStore sharedInstance] appendInsertQueue:MO];
//    }
//    [insertedManagedObjects unionSet: EWDataStore.sharedInstance.insertQueue];
//    for (NSManagedObject *MO in updatedManagedObjects) {
//        [[EWDataStore sharedInstance] appendUpdateQueue:MO];
//    }
//    [updatedManagedObjects unionSet: EWDataStore.sharedInstance.updateQueue];
//    NSMutableSet *deletedServerObjects = [NSMutableSet new];
//    for (NSManagedObject *mo in deletedManagedObjects) {
//        PFObject *object = [mo parseObject];
//        if (object) {
//            [deletedServerObjects addObject:object];
//            [[EWDataStore sharedInstance] appendDeleteQueue:object];
//        }
//    }
//    [deletedServerObjects unionSet: EWDataStore.sharedInstance.deleteQueue];
    
    //only ManagedObjectID is thread safe
    NSSet *insertedManagedObjectIDs = [EWDataStore.sharedInstance.insertQueue valueForKey:@"objectID"];
    NSMutableSet *updatedManagedObjectIDs = [[EWDataStore.sharedInstance.updateQueue valueForKey:@"objectID"] mutableCopy];
    NSSet *deletedServerObjects = EWDataStore.sharedInstance.deleteQueue;
    
    
    NSLog(@"============ Start updating to server. There are %lu inserts, %lu updates, and %lu deletes ===============", (unsigned long)insertedManagedObjectIDs.count, (unsigned long)updatedManagedObjectIDs.count, (unsigned long)deletedServerObjects.count);
    
    
    [updatedManagedObjectIDs unionSet:insertedManagedObjectIDs];

    dispatch_async([EWDataStore sharedInstance].dispatch_queue, ^{
        //perform network calls
        
        for (NSManagedObjectID *ID in updatedManagedObjectIDs) {
            [EWDataStore updateParseObjectFromManagedObjectID:ID];
        }
        
        for (NSManagedObject *managedObject in deletedServerObjects) {
            NSLog(@"Deleting PO %@ (%@)", managedObject.entity.serverClassName, [managedObject valueForKey:kParseObjectID]);
            [EWDataStore deleteParseObject:managedObject.parseObject];
        }
        
    });
}
#pragma mark -


+ (void)updateParseObjectFromManagedObjectID:(NSManagedObjectID *)managedObjectID{
    NSError *error;
    NSManagedObject *mo = [[NSManagedObjectContext contextForCurrentThread] existingObjectWithID:managedObjectID error:&error];
    if (!mo) {
        NSLog(@"*** Failed to get MO from background context: %@", error);
    }
    NSString *parseObjectId = [mo valueForKey:kParseObjectID];
    PFObject *object;
    if (parseObjectId) {
        //update
        NSError *err;
        object = [[PFQuery queryWithClassName:mo.entity.serverClassName] getObjectWithId:parseObjectId error:&err];
        //object = [PFObject objectWithoutDataWithClassName:mo.entity.serverClassName objectId:parseObjectId];
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
        //skip if updating other PFUser
        //TODO: Set ACL for PFUser to enable public writability
        if ([mo.entity.serverClassName isEqualToString:@"_User"]) {
            if (![object.objectId isEqualToString:[EWUserManagement me].objectId]) {
                NSLog(@"Skip updating other PFUser: %@", [object valueForKey:@"name"]);
                [[EWDataStore sharedInstance] removeObjectFromInsertQueue:mo];
                [[EWDataStore sharedInstance] removeObjectFromUpdateQueue:mo];
                return;
            }
        }
    } else {
        //insert
        object = [PFObject objectWithClassName:mo.entity.serverClassName];
        [object save];//need to save before working on PFRelation
    }
    
    //==========set Parse value and store callback block===========
    [object updateValueFromManagedObject:mo];
    //=============================================================
    

    [object save:&error];
    if (!error) {
        
        if (parseObjectId) {
            NSLog(@"---------> PO updated to server: %@", mo.entity.serverClassName);
        }else{
            NSLog(@"=========> PO created: %@", mo.entity.serverClassName);
        }
        
        //assign connection between MO and PO
        [mo setValue:object.objectId forKey:kParseObjectID];
        [EWDataStore performSaveCallbacksWithParseObject:object andManagedObjectID:mo.objectID];
        [[NSManagedObjectContext contextForCurrentThread] saveToPersistentStoreAndWait];
        
        //remove from queue
        [[EWDataStore sharedInstance] removeObjectFromInsertQueue:mo];
        [[EWDataStore sharedInstance] removeObjectFromUpdateQueue:mo];
    } else {
        NSLog(@"Failed to save server object: %@", error.description);
        [mo updateEventually];
    }
    //}];
    
    

}

+ (void)deleteParseObject:(PFObject *)parseObject{
    [parseObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (succeeded) {
            //Good
            [[EWDataStore sharedInstance] removeDeleteQueue:parseObject];
            
        }else if (error.code == kPFErrorObjectNotFound){
            //fine
            [[EWDataStore sharedInstance] removeDeleteQueue:parseObject];
            
        }else{
            //not good
            [[EWDataStore sharedInstance] appendDeleteQueue:parseObject];
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

//- (void)updateModifiedDate:(NSNotification *)notification{
//    NSSet *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
//    
//    //NSLog(@"Observed %lu ManagedObject changed, updating 'UpdatedAt'.", (unsigned long)updatedObjects.count);
//    for (NSManagedObject *mo in updatedObjects) {
//        double interval = [[mo valueForKey:kUpdatedDateKey] timeIntervalSinceNow];
//        if (interval < -1) {
//            //update time
//            [mo setValue:[NSDate date] forKeyPath:kUpdatedDateKey];
//        }
//    }
//}

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
        NSLog(@"The MO %@ doesn't not has server key, please check", self.entity.name);
        return;
    }
    
    //download if needed
    [parseObject fetchIfNeeded];
    
    //attributes
    [self assignValueFromParseObject:parseObject];
    
    //realtion
    NSMutableDictionary *relations = [self.entity.relationshipsByName mutableCopy];
    [relations enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
        
        if ([obj isToMany]) {
            //Fetch PFRelation
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
            
            //delete MO not found on server
            for (NSManagedObject *MOToDelete in managedObjectToDelete) {
                [self.managedObjectContext deleteObject:MOToDelete];
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
                [self setValue:nil forKey:key];
            }
        }
    }];
    
    //UpdatedDate here only when the relations is updated
    [self setValue:[NSDate date] forKey:kUpdatedDateKey];
    
    //save
    [self.managedObjectContext saveToPersistentStoreAndWait];
}

- (PFObject *)parseObject{
    NSString *parseID = [self valueForKey:kParseObjectID];
    if (parseID) {
        PFQuery *query = [PFQuery queryWithClassName:self.entity.serverClassName];
        [query whereKey:kParseObjectID equalTo:parseID];
        PFObject *object = [query getFirstObject];
        if (!object) {
            NSLog(@"@@@ Need some treatment when no parse object found");
            [self setValue:nil forKey:kParseObjectID];
            //TODO: need to check if all related MO has removed their relation with self, if so, delete this MO.
        }	
        return object;
    }else{
        return nil;
    }
    
    
}

- (void)refreshInBackgroundWithCompletion:(void (^)(void))block{
    NSString *parseObjectId = [self valueForKey:kParseObjectID];
    if (!parseObjectId) {
        NSLog(@"+++> Insert a managedObject %@ from refresh", self.entity.name);
        [self updateEventually];
        [EWDataStore save];
        if (block) {
            block();
        }
    }else{
        
        NSManagedObjectID *objectID = self.objectID;
        NSLog(@"===> Updating a managedObject %@", self.entity.name);
        //save async
        dispatch_async([EWDataStore sharedInstance].dispatch_queue, ^{
            NSManagedObjectContext *localContext = [NSManagedObjectContext contextForCurrentThread];
            NSManagedObject *currentMO = [localContext objectWithID:objectID];
            PFObject *object = [currentMO parseObject];
            [currentMO updateValueAndRelationFromParseObject:object];
            [localContext saveToPersistentStoreAndWait];
            
            if (block) {
                block();
            }
        });
    }
}

- (void)refresh{
    //NSParameterAssert([NSThread isMainThread]);
    NSLog(@"Refresh %@ from server", self.entity.serverClassName);
    
    NSString *parseObjectId = [self valueForKey:kParseObjectID];
    
    if (!parseObjectId) {
        NSParameterAssert([self isInserted]);
        NSLog(@"+++> Insert a managedObject %@ from refresh", self.entity.name);
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
        NSLog(@"===> Updating a managedObject %@", self.entity.name);
        PFObject *object = [self parseObject];
        [self updateValueAndRelationFromParseObject:object];
        [self.managedObjectContext saveToPersistentStoreAndWait];
    }
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
                [self setValue:nil forKey:key];
            }
        }
    }];
    
    [[EWDataStore currentContext] saveToPersistentStoreAndWait];
}


- (void)setPFFile:(PFFile *)file forPropertyDescription:(NSAttributeDescription *)attributeDescription{
    
    if ([file isDataAvailable]) {
        //get the data locally if available
        NSData *data = [file getData];
        NSString *className = [self getPropertyClassByName:attributeDescription.name];
        if ([className isEqualToString:@"UIImage"]) {
            UIImage *img = [UIImage imageWithData:data];
            [self setValue:img forKey:attributeDescription.name];
        }
        else{
            [self setValue:data forKey:attributeDescription.name];
        }
    }else{
        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (error) {
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
    
}

- (void)updateEventually{
    BOOL hasParseObjectLinked = !![self valueForKey:kParseObjectID];
    if (hasParseObjectLinked) {
        //update
        NSLog(@"%s: updated %@ eventually", __func__, self.entity.name);
        [[EWDataStore sharedInstance] appendUpdateQueue:self];
    }else{
        //insert
        NSLog(@"%s: insert %@ eventually", __func__, self.entity.name);
        [[EWDataStore sharedInstance] appendInsertQueue:self];
    }
    
}

- (void)deleteEventually{
    PFObject *po = self.parseObject;
    if (!po) {
        return;
    }
    NSLog(@"%s: delete %@ eventually", __func__, self.entity.name);
    [[EWDataStore sharedInstance] appendDeleteQueue:self.parseObject];

    //delete
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext deleteObject:self];
        [self.managedObjectContext saveToPersistentStoreAndWait];
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

@end

#pragma mark - Parse Object extension
@implementation PFObject (NSManagedObject)
- (void)updateValueFromManagedObject:(NSManagedObject *)managedObject{
    NSManagedObject *mo = [EWDataStore objectForCurrentContext:managedObject];
//    NSDate *updateAt = [mo valueForKeyPath:kUpdatedDateKey];
//    if (updateAt){
//        if ([updateAt timeIntervalSinceDate:self.updatedAt] < 0) {
//            NSParameterAssert([mo valueForKey:kParseObjectID]);
//            NSLog(@"@@@ Trying to update MO %@, but PO is newer, refresh MO!", mo.entity.name);
//            [mo refresh];
//            return;
//            
//        } //else if([updateAt timeIntervalSinceDate:self.updatedAt] == 0) {
//        //NSLog(@"The last modified dates are the same, parse object will not update to server");
//        //return;
//        //}
//        //continue if MO updatedAt is later or equal to parse updatedAt
//    }
    NSMutableDictionary *mutableAttributeValues = [mo.entity.attributesByName mutableCopy];
    [mutableAttributeValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *obj, BOOL *stop) {
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
            //other supported value: audio/video
            [self setObject:value forKey:key];
        }else{
            //value is nil, delete PO value
            [self removeObjectForKey:key];
        }
        
    }];
    
    //relation
    NSMutableDictionary *mutableRelationships = [mo.entity.relationshipsByName mutableCopy];
    [mutableRelationships enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
        id relatedManagedObjects = [mo valueForKey:key];
        if (relatedManagedObjects){
            if ([obj isToMany]) {
                //To-Many relation
                //Parse relation
                PFRelation *parseRelation = [self relationForKey:key];
                //Find related PO to delete async
                [[parseRelation query] findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    NSMutableArray *relatedParseObjects = [objects mutableCopy];
                    if (relatedParseObjects.count) {
                        NSArray *relatedParseObjectsToDelete = [relatedParseObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT objectId IN %@", [relatedManagedObjects valueForKey:@"objectId"]]];
                        for (PFObject *PO in relatedParseObjectsToDelete) {
                            [parseRelation removeObject:PO];
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
                NSLog(@"Empty relationship on %@ -> %@, delete PO relation.", managedObject.entity.name, obj.name);
                [self removeObjectForKey:key];
            }
        }
        
    }];
    //Only save when network is available so that MO can link with PO
    //[self saveEventually];
}

- (NSManagedObject *)managedObject{
    NSManagedObject *managedObject = [NSClassFromString(self.localClassName) MR_findFirstByAttribute:kParseObjectID withValue:self.objectId];
    
    if (!managedObject) {
        //if managedObject not exist, create it locally
        managedObject = [NSClassFromString(self.localClassName) MR_createEntity];
        [managedObject setValue:self.createdAt forKeyPath:kCreatedDateKey];
        NSLog(@"+++> MO created: %@ (%@)", self.localClassName, self.objectId);
    }
    //check if need to assign value
    NSDate *updated = [managedObject valueForKey:kUpdatedDateKey];
    
    if (!updated || [updated isEarlierThan:self.updatedAt]) {
        
        [managedObject assignValueFromParseObject:self];
        
//        if ([self isKindOfClass:[PFUser class]] && ![self.objectId isEqualToString:[PFUser currentUser].objectId]) {
//            //skip getting relation for other user
//            [managedObject assignValueFromParseObject:self];
//        }else{
//            [managedObject updateValueAndRelationFromParseObject:self];
//        }
        
    }
    
    
    return managedObject;
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
