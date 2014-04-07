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

//Model Manager
#import "EWAlarmManager.h"
#import "EWTaskStore.h"
#import "EWMediaStore.h"
#import "EWMediaItem.h"
#import "NSString+MD5.h"

//Util
#import "FTWCache.h"
#import "SMBinaryDataConversion.h"

//Global variable
//NSManagedObjectContext *context;
SMClient *client;
SMPushClient *pushClient;
AmazonSNSClient *snsClient;
//NSDate *lastChecked;

@implementation EWDataStore
@synthesize model;
@synthesize currentContext;
@synthesize dispatch_queue, coredata_queue;
@synthesize lastChecked;

+ (EWDataStore *)sharedInstance{
    
    static EWDataStore *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWDataStore alloc] init];
    });
    return sharedStore_;
}

-(id)init{
    self = [super init];
    if (self) {
        //dispatch queue
        dispatch_queue = dispatch_queue_create("com.wokealarm.datastore.dispatchQueue", DISPATCH_QUEUE_SERIAL);
        coredata_queue = dispatch_queue_create("com.wokealarm.datastore.coreDataQueue", DISPATCH_QUEUE_SERIAL);
        
        //AWS
        snsClient = [[AmazonSNSClient alloc] initWithAccessKey:AWS_ACCESS_KEY_ID withSecretKey:AWS_SECRET_KEY];
        snsClient.endpoint = [AmazonEndpoints snsEndpoint:US_WEST_2];
        
        //stackMob
        SM_CACHE_ENABLED = YES;//enable cache
        //SM_CORE_DATA_DEBUG = YES; //enable core data debug
        client = [[SMClient alloc] initWithAPIVersion:@"0" publicKey:kStackMobKeyDevelopment];
        client.userSchema = @"EWPerson";
        client.userPrimaryKeyField = @"username";
        
        //core data
        self.coreDataStore = [client coreDataStoreWithManagedObjectModel:self.model];
        
        //cache policy
        self.coreDataStore.fetchPolicy = SMFetchPolicyTryCacheElseNetwork;
        __block SMCoreDataStore *blockCoreDataStore = self.coreDataStore;
        self.coreDataStore.defaultSMMergePolicy = SMMergePolicyLastModifiedWins;
        [client.networkMonitor setNetworkStatusChangeBlock:^(SMNetworkStatus status) {
            if (status == SMNetworkStatusReachable) {
                if (currentUser) {
                    NSLog(@"Connected to server, and user fetched, strat syncing");
                    [blockCoreDataStore syncWithServer];
                }else{
                    NSLog(@"User login process haven't finished, delay snycing");
                }
                
            }
            else {
                NSLog(@"Disconnected from server, enter cache only mode");
                [blockCoreDataStore setFetchPolicy:SMFetchPolicyCacheOnly];
            }
        }];
        
        [self.coreDataStore setSyncCompletionCallback:^(NSArray *objects){
            NSLog(@"Syncing is complete, item synced: %@. Change the datastore policy to fetch from the network", objects);
            
            
            //Change fetch policy
            [blockCoreDataStore setFetchPolicy:SMFetchPolicyTryNetworkElseCache];
            
            
            // Notify other views that they should reload their data from the network
            if (objects.count) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kFinishedSync object:nil];//TODO
            }
            
        }];
        
        //refesh failure behavior
        __block SMUserSession *currentSession = client.session;
        [client setTokenRefreshFailureBlock:^(NSError *error, SMFailureBlock originalFailureBlock) {
            NSLog(@"Automatic refresh token has failed");
            // Reset local session info
            [currentSession clearSessionInfo];
            
            // Show custom login screen
            //[blockSelf showLoginScreen];
            
            // Optionally call original failure block
            originalFailureBlock(error);
        }];

        //watch for login event
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDataCheck) name:kPersonLoggedIn object:Nil];
    }
    return self;
}

- (NSManagedObjectModel *)model
{
    if (model != nil) {
        return model;
    }
    //Returns a model created by merging all the models found in given bundles. If you specify nil, then the main bundle is searched.
    //managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"EarlyWorm" withExtension:@"momd"];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return model;
}

- (void)save{

    //save on current thread
    [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
        NSLog(@"Failed to save on app enter ");
    }];
    
    //save on designated thread
    dispatch_async(coredata_queue, ^{
        [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
            NSLog(@"Failed to save on dedicated queue");
        }];
    });
}

- (NSManagedObjectContext *)currentContext{
    NSManagedObjectContext *c = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
    
    //[context observeContext:c];
    //No need to observe because both context are child-context of SM private context
    
    return c;
}

- (NSDate *)lastChecked{
    NSUserDefaults *defalts = [NSUserDefaults standardUserDefaults];
    NSDate *timeStamp = [defalts objectForKey:kLastChecked];
    return timeStamp;
}

- (void)setLastChecked:(NSDate *)time{
    if (lastChecked) {
        NSUserDefaults *defalts = [NSUserDefaults standardUserDefaults];
        [defalts setObject:time forKey:kLastChecked];
        [defalts synchronize];
    }
}


#pragma mark - Login Check
- (void)loginDataCheck{
    NSLog(@"[%s]", __func__);
    
    //change fetch policy
    NSLog(@"0. Start sync with server");
    [self.coreDataStore syncWithServer];
    
    //refresh current user
    NSLog(@"1. refresh current user");
    [EWDataStore objectForCurrentContext:currentUser];
    
    //check alarm, task, and local notif
    [self checkAlarmData];
    
    
    //update data with timely updates
    [[EWDataStore sharedInstance] registerServerUpdateService];
    
}


- (void)checkAlarmData{
    NSInteger nAlarm = [[EWAlarmManager sharedInstance] alarmsForUser:currentUser].count;
    NSInteger nTask = [EWTaskStore myTasks].count;
    if (nTask == 0 && nAlarm == 0) {
        return;
    }
    
    
    //check alarm
    BOOL alarmGood = [EWAlarmManager.sharedInstance checkAlarms];
    if (!alarmGood) {
        NSLog(@"2. Alarm not set up yet");
        dispatch_async(dispatch_queue, ^{
            [[EWAlarmManager sharedInstance] scheduleAlarm];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmNewNotification object:nil userInfo:nil];
        });
        
    }
    
    //check task
    BOOL taskGood = [EWTaskStore.sharedInstance checkTasks];
    if (!taskGood) {
        NSLog(@"3. Task needs to be scheduled");
        dispatch_async(dispatch_queue, ^{
            [EWTaskStore.sharedInstance scheduleTasks];
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskNewNotification object:nil userInfo:nil];
        });
        
    }
    
    //check local notif
    dispatch_async(dispatch_queue, ^{
        NSLog(@"4. Start check local notification");
        [EWTaskStore.sharedInstance checkScheduledNotifications];
    });
    
}

#pragma mark - DATA from Amazon S3
- (NSData *)getRemoteDataWithKey:(NSString *)key{
    if (!key) {
        return nil;
    }
    
    NSData *data = nil;
    
    //local file
    if ([[NSURL URLWithString:key] isFileURL] || ![key hasPrefix:@"http"]) {
        NSLog(@"Is local file path, return data directly");
        data = [NSData dataWithContentsOfFile:key];
        return data;
    }
    //s3 file
    if ([SMBinaryDataConversion stringContainsURL:key]) {
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
        
    }else if(key.length > 500){
        //string contains data
        data = [SMBinaryDataConversion dataForString:key];
        //TODO: save again.
        NSLog(@"Return the audio key as the data itself, please check!");
        
    }else if(![key hasPrefix:@"http"]){
        //local data
        NSLog(@"string is a local file: %@", key);
        NSArray *array = [key componentsSeparatedByString:@"."];
        if (array.count != 2) [NSException raise:@"Unexpected file format" format:@"Please provide a who file name with extension"];
        NSString *filePath = [[NSBundle mainBundle] pathForResource:array[0] ofType:array[1]];
        data = [NSData dataWithContentsOfFile:filePath];
    }
    
    return data;
}

#pragma mark - local cache

- (NSString *)localPathForKey:(NSString *)key{
    if (key.length > 500) {
        NSLog(@"*** Something wrong with url, the url contains data");
        return nil;
    }
    NSString *path = [FTWCache localPathForKey:[key MD5Hash]];
    if (!path) {
        //not in local, need to download
        //[[EWDownloadManager sharedInstance] downloadUrl:[NSURL URLWithString:key]];
        return nil;
    }
    return path;
}

- (void)updateCacheForKey:(NSString *)key withData:(NSData *)data{
    if (key.length == 15) {
        [NSException raise:@"Passed in MD5 value" format:@"Please provide original url string"];
    }
    NSString *hashKey = [key MD5Hash];
    [FTWCache setObject:data forKey:hashKey];
    
}

- (NSDate *)lastModifiedDateForObjectAtKey:(NSString *)key{
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

#pragma mark - Timely sync
- (void)registerServerUpdateService{
    self.serverUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:serverUpdateInterval target:self selector:@selector(serverUpdate:) userInfo:nil repeats:0];
    [self serverUpdate:nil];
}
     
- (void)serverUpdate:(NSTimer *)timer{
    //services that need to run periodically
    NSLog(@"%s: Start sync service", __func__);
    
    dispatch_async(dispatch_queue, ^{
        //sync server
        [self.coreDataStore syncWithServer];
        
        //lsat seen
        NSLog(@"update last seen recurring task");
        [[EWUserManagement sharedInstance] updateLastSeen];
        
        //location
        NSLog(@"update location recurring task");
        [[EWUserManagement sharedInstance] registerLocation];
        
        //profilePic & bgImg
        //NSLog(@"Update profile pic recurring task");
        //[[EWUserManagement sharedInstance] checkUserCache];
        
        //check task
        NSLog(@"Update task recurring task");
        [[EWTaskStore sharedInstance] scheduleTasks];
    });
    
}

#pragma mark - Utilities
+ (SMRequestOptions*)optionFetchCacheElseNetwork{
    SMRequestOptions *options = [SMRequestOptions options];
    options.fetchPolicy = SMFetchPolicyTryCacheElseNetwork;
    return options;
}

+ (SMRequestOptions *)optionFetchNetworkElseCache{
    SMRequestOptions *options = [SMRequestOptions options];
    options.fetchPolicy = SMFetchPolicyTryNetworkElseCache;
    return options;
}

+ (NSManagedObjectContext *)currentContext{
    return [SMClient defaultClient].coreDataStore.contextForCurrentThread;
}


#pragma mark - Core Data with multithreading
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
    NSManagedObject * objForCurrentContext = [[EWDataStore sharedInstance].currentContext objectWithID:obj.objectID];
    NSAssert([[objForCurrentContext class] isEqual: [obj class]], @"Returned different class");
    return objForCurrentContext;
}

+ (EWPerson *)user{
    if ([NSThread isMainThread]) {
        return currentUser;
    }else{
        //NSLog(@"**** Get current user on background thread ****");
        return (EWPerson *)[[EWDataStore currentContext] objectWithID:currentUser.objectID];
    }
    return nil;
}
@end
