//
//  EWStore.m
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWDataStore.h"
#import "EWUserManagement.h"
#import "EWPersonManager.h"
#import "EWMediaManager.h"
//#import "EWTaskManager.h"
#import "EWAlarmManager.h"
#import "EWWakeUpManager.h"
#import "EWServer.h"
//#import "EWTaskItem.h"
#import "EWMedia.h"
#import "EWNotification.h"
#import "EWUIUtil.h"
#import "EWStatisticsManager.h"
#import "EWBackgroundingManager.h"


@implementation EWDataStore

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
	//set up server sync
	[[EWSync sharedInstance] setup];
	//watch for login event
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDataCheck) name:kPersonLoggedIn object:nil];
	
	return self;
}


#pragma mark - Login Check
- (void)loginDataCheck{
    DDLogVerbose(@"=== [%s] Logged in, performing login tasks.===", __func__);
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (![currentInstallation[kParseObjectID] isEqualToString: [EWSession sharedSession].currentUser.objectId]){
        currentInstallation[kUserID] = [EWSession sharedSession].currentUser.objectId;
        currentInstallation[kUsername] = [EWSession sharedSession].currentUser.username;
        [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                DDLogVerbose(@"Installation %@ saved", currentInstallation.objectId);
            }else{
                DDLogVerbose(@"*** Installation %@ failed to save: %@", currentInstallation.objectId, error.description);
            }
        }];
	};
	
	
	//init backgrounding manager
	[EWBackgroundingManager sharedInstance];
	
    //continue upload to server if any
    DDLogVerbose(@"0. Continue uploading to server");
    [[EWSync sharedInstance] resumeUploadToServer];
	
	//fetch everyone
	DDLogVerbose(@"1. Getting everyone");
	[[EWPersonManager sharedInstance] getEveryoneInBackgroundWithCompletion:NULL];
    
    //refresh current user
    DDLogVerbose(@"2. Register AWS push key");
    [EWServer registerAPNS];
    
    //check alarm, task, and local notif
    DDLogVerbose(@"3. Check alarm");
	[[EWAlarmManager sharedInstance] scheduleAlarm];
	
	DDLogVerbose(@"5. Check my social graph");
	//
	
    DDLogVerbose(@"4. Check my unread media");//media also will be checked with background fetch
    [[EWMediaManager sharedInstance] checkMediaAssetsInBackground];
    
    //updating facebook friends
    DDLogVerbose(@"5. Updating facebook friends");
    [EWUserManagement getFacebookFriends];
    
    //update facebook info
    //DDLogVerbose(@"6. Updating facebook info");
    //[EWUserManagement updateFacebookInfo];
	DDLogVerbose(@"6. Check scheduled local notifications");
	[[EWAlarmManager sharedInstance] checkScheduledLocalNotifications];
    
    //Update my relations cancelled here because the we should wait for all sync task finished before we can download the rest of the relation
    NSLog(@"7. Refresh my media");
    [[EWMediaManager sharedInstance] mediaCreatedByPerson:[EWSession sharedSession].currentUser];
	
	//location
	DDLogVerbose(@"8. Start location recurring update");
	[EWUserManagement registerLocation];
	
    
    //update data with timely updates
	//first time
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[@"start_date"] = [NSDate date];
	userInfo[@"count"] = @0;
	[NSTimer scheduledTimerWithTimeInterval:kServerUpdateInterval target:self selector:@selector(serverUpdate:) userInfo:userInfo repeats:YES];
	
}

- (void)serverUpdate:(NSTimer *)timer{

	if (timer) {
		NSInteger count;
		NSDate *start = timer.userInfo[@"start_date"];
		count = [(NSNumber *)timer.userInfo[@"count"] integerValue];
		DDLogVerbose(@"=== Server update started at %@ is running for the %ld times ===", start.date2detailDateString, (long)count);
		count++;
		timer.userInfo[@"count"] = @(count);
	}
	
    //services that need to run periodically
    if (![EWSession sharedSession].currentUser) {
        return;
    }
    //this will run at the beginning and every 600s
    DDLogVerbose(@"Start sync service");
	
	//fetch everyone
	DDLogVerbose(@"[1] Getting everyone");
	[[EWPersonManager sharedInstance] getEveryoneInBackgroundWithCompletion:NULL];
	
    //location
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
		DDLogVerbose(@"[2] Start location recurring update");
		[EWUserManagement registerLocation];
	}
    
}



@end






