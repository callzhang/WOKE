//
//  EWStore.m
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWDataStore.h"
#import <Parse/Parse.h>
#import "EWUserManagement.h"
#import "EWPersonStore.h"
#import "EWDownloadManager.h"
#import "EWAlarmManager.h"
#import "EWTaskStore.h"
#import "EWMediaStore.h"
#import "EWMediaItem.h"
#import "NSString+MD5.h"
#import "EWWakeUpManager.h"

//Util
#import "FTWCache.h"

//Global variable
//NSManagedObjectContext *context;
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
        
        //Parse
        [Parse setApplicationId:@"p1OPo3q9bY2ANh8KpE4TOxCHeB6rZ8oR7SrbZn6Z"
                      clientKey:@"9yfUenOzHJYOTVLIFfiPCt8QOo5Ca8fhU8Yqw9yb"];
        //[PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        
        //core data
        [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Woke"];
        currentContext = [NSManagedObjectContext MR_defaultContext];
        
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
    [[EWDataStore currentContext] save:nil];
    
    //save on designated thread

}

- (NSManagedObjectContext *)currentContext{
    if ([NSThread isMainThread]) {
        return currentContext;
    }
    [NSException raise:@"Core Data context is not allowed to run off the main thread" format:@"Check you code!"];
    return nil;
}

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
    NSLog(@"========> %s <=========", __func__);
    
    //change fetch policy
    //NSLog(@"0. Start sync with server");
    //[self.coreDataStore syncWithServer];
    
    //refresh current user
    NSLog(@"1. Register AWS push key");
    [EWUserManagement registerAPNS];
    
    //check alarm, task, and local notif
    [self checkAlarmData];
    
    //updating facebook friends
    //dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"5. Updating facebook friends");
        [EWUserManagement getFacebookFriends];
    //});
    
    
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
    //dispatch_async(dispatch_queue, ^{
        NSLog(@"2. Check alarm");
        [[EWAlarmManager sharedInstance] scheduleAlarm];
    //});
    
    //check task
    //dispatch_async(dispatch_queue, ^{
        NSLog(@"3. Check task");
        [EWTaskStore.sharedInstance scheduleTasks];
    //});
    
    //check local notif
    //dispatch_async(dispatch_queue, ^{
        NSLog(@"4. Start check local notification");
        [EWTaskStore.sharedInstance checkScheduledNotifications];
    //});
    
}

#pragma mark - DATA from Amazon S3
- (NSData *)getRemoteDataWithKey:(NSString *)key{
    if (!key) {
        return nil;
    }
    
    NSData *data = nil;
    
    //local file
    if ([[NSURL URLWithString:key] isFileURL] || ![key hasPrefix:@"http"]) {
        data = [NSData dataWithContentsOfFile:key];
        return data;
    }
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

- (void)deleteCacheForKey:(NSString *)key{
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
    self.serverUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:serverUpdateInterval target:self selector:@selector(serverUpdate:) userInfo:nil repeats:0];
    [self serverUpdate:nil];
}
     
- (void)serverUpdate:(NSTimer *)timer{
    //services that need to run periodically
    NSLog(@"%s: Start sync service", __func__);
    
    dispatch_async(dispatch_queue, ^{
        
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
    });
    
}

#pragma mark - Utilities
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
    //not thread save
//    if ([obj.managedObjectContext isEqual:[EWDataStore currentContext]]) {
//        return obj;
//    }
    if (obj == nil) {
        NSLog(@"Passed in nil managed object");
        return nil;
    }
    NSManagedObject * objForCurrentContext = [[EWDataStore sharedInstance].currentContext objectWithID:obj.objectID];
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
