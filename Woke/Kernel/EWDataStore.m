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
    [[EWSync sharedInstance] resumeUploadToServer];
	
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
		[NSTimer bk_scheduledTimerWithTimeInterval:60 block:^(NSTimer *timer) {
			//[EWPersonStore updateMe];
		} repeats:NO];
	}];
	
	NSLog(@"5. Check my social graph");
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
    NSLog(@"7. Refresh my media");
    [[EWMediaStore sharedInstance] mediaCreatedByPerson:me];
	
	//location
	NSLog(@"8. Start location recurring update");
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
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
		NSLog(@"[2] Start location recurring update");
		[EWUserManagement registerLocation];
	}
    
    //check task
    NSLog(@"[3] Start recurring task schedule");
	[[EWTaskStore sharedInstance] scheduleTasksInBackgroundWithCompletion:^{
		//[EWPersonStore updateMe];
	}];
    
}



@end






