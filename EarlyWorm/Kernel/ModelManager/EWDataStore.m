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
#import "AVManager.h"

//Global variable
NSManagedObjectContext *context;
SMClient *client;
SMPushClient *pushClient;
AmazonSNSClient *snsClient;
NSDate *lastChecked;

@implementation EWDataStore
@synthesize model;
@synthesize currentContext;
@synthesize dispatch_queue;

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
        
        //lastChecked
        lastChecked = [NSDate date];
        
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
        context = [self.coreDataStore contextForCurrentThread];
        
        
        //cache policy
        self.coreDataStore.fetchPolicy = SMFetchPolicyCacheOnly;
        __block SMCoreDataStore *blockCoreDataStore = self.coreDataStore;
        //self.coreDataStore.fetchPolicy = SMFetchPolicyCacheOnly; //initial fetch should from cache
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
    [context saveOnSuccess:^{
        NSLog(@"Core Data saved");
    } onFailure:^(NSError *error) {
        NSLog(@"Error in save Core Data objects: %@", error.description);
    }];
}

- (NSManagedObjectContext *)currentContext{
    return [self.coreDataStore contextForCurrentThread];
}


#pragma mark - Login Check
- (void)loginDataCheck{
    //change fetch policy
    NSLog(@"%s: user logged in, start sync with server", __func__);
    [self.coreDataStore syncWithServer];
    
    //refresh current user
    dispatch_async(dispatch_queue, ^{
        NSLog(@"1. refresh current user");
        [context refreshObject:currentUser mergeChanges:YES];
    });
    
    //check alarm, task, and local notif
    [self checkAlarmData];
    
}


- (void)checkAlarmData{
    NSInteger nAlarm = [[EWAlarmManager sharedInstance] allAlarms].count;
    NSInteger nTask = [[EWTaskStore sharedInstance] allTasks].count;
    if (nTask == 0 && nAlarm == 0) {
        return;
    }
    
    
    //check alarm
    BOOL alarmGood = [EWAlarmManager.sharedInstance checkAlarms];
    if (!alarmGood) {
        NSLog(@"2. Alarm not set up yet");
        dispatch_async(dispatch_queue, ^{
            [[EWAlarmManager sharedInstance] scheduleAlarm];
        });
        
    }
    
    //check task
    BOOL taskGood = [EWTaskStore.sharedInstance checkTasks];
    if (!taskGood) {
        NSLog(@"3. Task needs to be scheduled");
        dispatch_async(dispatch_queue, ^{
            [EWTaskStore.sharedInstance scheduleTasks];
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
    if ([[NSURL URLWithString:key] isFileURL]) {
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

- (NSString *)localPathForUrl:(NSString *)url{
    if (url.length > 500) {
        NSLog(@"*** Something wrong with url, the url contains data");
        return nil;
    }
    NSString *path = [FTWCache localPathForKey:url.MD5Hash];
    if (!path) {
        //not in local, need to download
        [[EWDownloadManager sharedInstance] downloadUrl:[NSURL URLWithString:url]];
        return nil;
    }
    return path;
}

#pragma mark - other

@end
