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

//Model Manager
#import "EWAlarmManager.h"
#import "EWTaskStore.h"
#import "EWMediaStore.h"
#import "NSString+MD5.h"

//Util
#import "FTWCache.h"
#import "SMBinaryDataConversion.h"

//Global variable
NSManagedObjectContext *context;
SMClient *client;
SMPushClient *pushClient;

@implementation EWDataStore
@synthesize model;

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
                NSLog(@"Connected to server, strat syncing");
                [blockCoreDataStore syncWithServer];
            }
            else {
                NSLog(@"Disconnected from server, enter cache only mode");
                [blockCoreDataStore setFetchPolicy:SMFetchPolicyCacheOnly];
            }
        }];
        
        [self.coreDataStore setSyncCompletionCallback:^(NSArray *objects){
            NSLog(@"Syncing is complete, item synced: %@. Change the policy to fetch from the network", objects);
            [blockCoreDataStore setFetchPolicy:SMFetchPolicyTryNetworkElseCache];
            // Notify other views that they should reload their data from the network
            [[NSNotificationCenter defaultCenter] postNotificationName:kFinishedSync object:nil];//TODO
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginCheck) name:kPersonLoggedIn object:Nil];
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


#pragma mark - Login Check
- (void)loginCheck{
    [self checkAlarmData];
}


- (void)checkAlarmData{
    //check alarm
    BOOL alarmGood = [EWAlarmManager.sharedInstance checkAlarms];
    if (!alarmGood) {
        NSLog(@"Alarm not set up yet");
        //[[EWAlarmManager sharedInstance] scheduleAlarm];
    }
    
    //check task
    BOOL taskGood = [EWTaskStore.sharedInstance checkTasks];
    if (!taskGood) {
        NSLog(@"Task needs to be scheduled");
        [EWTaskStore.sharedInstance scheduleTasks];
    }
    
    //check local notif
    [EWTaskStore.sharedInstance checkScheduledNotifications];
}

#pragma mark - DATA from Amazon S3
- (NSData *)getRemoteDataWithKey:(NSString *)key{
    if (!key) {
        return nil;
    }
    NSData *data;
    if ([SMBinaryDataConversion stringContainsURL:key]) {
        //read from url
        NSURL *audioURL = [NSURL URLWithString:key];
        NSString *keyHash = [audioURL.absoluteString MD5Hash];
        data = [FTWCache objectForKey:keyHash];
        if (!data) {
            //get from remote
            NSError *err;
            data = [NSData dataWithContentsOfURL:audioURL options:NSDataReadingUncached error:&err];//use uncached may increase speed?
            if (err) {
                NSLog(@"@@@@@@ Error occured in reading remote content: %@", err);
            }
            [FTWCache setObject:data forKey:keyHash];
        }
        
    }else if(key.length > 200){
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

@end
