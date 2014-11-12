//
//  EWWakeUpManager.m
//  EarlyWorm
//
//  Created by Lei on 3/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWWakeUpManager.h"
#import "EWPersonManager.h"
#import "AVManager.h"
#import "EWAppDelegate.h"
#import "EWMedia.h"
#import "EWMediaManager.h"
#import "EWNotificationManager.h"
#import "EWPerson.h"
#import "EWUserManagement.h"
#import "EWServer.h"
#import "ATConnect.h"
#import "EWBackgroundingManager.h"
#import "EWAlarm.h"
#import "EWActivity.h"

//UI
#import "EWWakeUpViewController.h"
#import "EWSleepViewController.h"
#import "EWPostWakeUpViewController.h"
#import "EWActivityManager.h"
#import "EWAlarmManager.h"


@interface EWWakeUpManager()
//retain the controller so that it won't deallocate when needed
@property (nonatomic, retain) EWWakeUpViewController *controller;
@end


@implementation EWWakeUpManager
@synthesize isWakingUp = _isWakingUp;

+ (EWWakeUpManager *)sharedInstance{
    static EWWakeUpManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWWakeUpManager alloc] init];
    });
    return manager;
}

- (id)init{
	self = [super init];
	[[NSNotificationCenter defaultCenter] addObserverForName:kBackgroundingEnterNotice object:nil queue:nil usingBlock:^(NSNotification *note) {
		[self alarmTimerCheck];
		[self sleepTimerCheck];
	}];
	return self;
}

- (BOOL)isWakingUp{
    @synchronized(self){
        return _isWakingUp;
    }
}

- (void)setIsWakingUp:(BOOL)isWakingUp{
    @synchronized(self){
        _isWakingUp = isWakingUp;
    }
}


#pragma mark - Handle push notification
+ (void)handlePushMedia:(NSDictionary *)notification{
    NSString *pushType = notification[kPushType];
    NSParameterAssert([pushType isEqualToString:kPushTypeMedia]);
    NSString *type = notification[kPushMediaType];
    NSString *mediaID = notification[kPushMediaID];
    EWActivity *activity = [[EWActivityManager sharedManager] currentAlarmActivity];
	
    if (!mediaID) {
        NSLog(@"Push doesn't have media ID, abort!");
        return;
    }

    
    EWMedia *media = [EWMedia getMediaByID:mediaID];
    //NSDate *nextTimer = nextAlarm.time;
    
    if ([type isEqualToString:kPushMediaTypeVoice]) {
        // ============== Media ================
        NSParameterAssert(mediaID);
        NSLog(@"Received voice type push");
        

        //download media
        NSLog(@"Downloading media: %@", media.objectId);
        [media downloadMediaFile];
        
        //determin action based on task timing
        if ([[NSDate date] isEarlierThan:activity.time]) {
            
            //============== pre alarm -> download ==============
            
        }else if (!activity.completed && [[NSDate date] timeIntervalSinceDate:activity.time] < kMaxWakeTime){
            
            //============== struggle ==============
            [EWWakeUpManager presentWakeUpViewWithActivity:activity];
            
            //broadcast so wakeupVC can react to it
            //[[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:self userInfo:@{kPushMediaKey: mediaID, kPushTaskKey: task.objectId}];
            
            //use KVO
            [activity addMediasObject:media];
            [EWSync save];
            
        }else{
            
            //Woke state -> assign media to next task, download
            if (![[EWSession sharedSession].currentUser.unreadMedias containsObject:media]) {
                [[EWSession sharedSession].currentUser addUnreadMediasObject:media];
                [EWSync save];
                
            }
            
        }
        
#ifdef DEBUG
        [[[UIAlertView alloc] initWithTitle:@"Voice来啦" message:@"收到一条神秘的语音."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#endif
        
        
    }else if([type isEqualToString:@"test"]){
        
        // ============== Test ================
        
        NSLog(@"Received === test === type push");
        [UIApplication sharedApplication].applicationIconBadgeNumber = 9;
        
    }
}

+ (void)handleAlarmTimerEvent:(NSDictionary *)info{
    NSParameterAssert([NSThread isMainThread]);
    if ([EWWakeUpManager sharedInstance].isWakingUp) {
        DDLogWarn(@"WakeUpManager is already handling alarm timer, skip");
        return;
    }else if ([EWWakeUpManager isRootPresentingWakeUpView]) {
		DDLogWarn(@"WakeUpView is already presented, skip");
		return;
	}
    
    BOOL isLaunchedFromLocalNotification = NO;
    BOOL isLaunchedFromRemoteNotification = NO;
	
    //get target activity
    EWAlarm *alarm;
    EWActivity *activity = [[EWActivityManager sharedManager] currentAlarmActivity];
    if (info) {
        NSString *alarmID = info[kPushAlarmID];
        NSString *alarmLocalID = info[kLocalAlarmID];
        NSParameterAssert(alarmID || alarmLocalID);
        if (alarmID) {
            isLaunchedFromRemoteNotification = YES;
            alarm = (EWAlarm *)[EWSync managedObjectWithClass:@"EWAlarm" withID:alarmID];
        }else if (alarmLocalID){
            isLaunchedFromLocalNotification = YES;
            NSURL *url = [NSURL URLWithString:alarmLocalID];
            NSManagedObjectID *ID = [mainContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
            if (ID) {
                alarm = (EWAlarm *)[mainContext existingObjectWithID:ID error:NULL];
            }else{
                DDLogError(@"The task objectID is invalid for alarm timer local notif: %@",alarmLocalID);
            }
        }
		
	}else{
		alarm = [EWPerson myNextAlarm];
	}
	
	
    NSLog(@"Start handle timer event");
    if (!alarm) {
        DDLogError(@"*** %s No alarm found for next alarm, abord", __func__);
        return;
    }
    
    if (alarm.state == NO) {
        NSLog(@"Alarm is OFF, skip today's alarm");
        return;
    }
    
    if (activity.completed) {
        // task completed
        NSLog(@"Activity has completed at %@, skip.", activity.completed.date2String);
        return;
    }
    if (activity.time.timeElapsed > kMaxWakeTime) {
        NSLog(@"Activity(%@) from notification has passed the wake up window. Handle it with checkPastTasks.", activity.objectId);
        [[EWActivityManager sharedManager] currentAlarmActivity];
        return;
    }
#if !DEBUG
    if (task.time.timeIntervalSinceNow>0) {
        DDLogWarn(@"Task %@(%@) passed in is in the future", task.time.date2String, task.objectId);
        return;
    }
#endif
    //state change
    [EWWakeUpManager sharedInstance].isWakingUp = YES;
    
    //update media
    [[EWMediaManager sharedInstance] checkMediaAssets];
    NSArray *medias = [EWSession sharedSession].currentUser.unreadMedias.allObjects;
    
    //fill media from mediaAssets, if no media for task, create a pseudo media
    NSInteger nVoiceNeeded = 1;
    
    for (EWMedia *media in medias) {
        if (!media.targetDate || [media.targetDate timeIntervalSinceNow]<0) {
            
            //find media to add
            [activity addMediasObject: media];
            //remove media from mediaAssets, need to remove relation doesn't have inverse relation. This is to make sure the sender doesn't need to modify other person
            [[EWSession sharedSession].currentUser removeUnreadMediasObject:media];
            //!!!single directional relation? Remove media.receiver?
            
            //stop if enough
            if ([media.type isEqualToString: kMediaTypeVoice]) {
                //reduce the counter
                nVoiceNeeded--;
                if (nVoiceNeeded <= 0) {
                    break;
                }
            }
        }
    }
    
    //add Woke media is needed
    if (activity.medias.count == 0) {
        //need to create some voice
        EWMedia *media = [[EWMediaManager sharedInstance] getWokeVoice];
        [activity addMediasObject:media];
    }
    
    //save
    [EWSync save];
	
	//set volume
	[[AVManager sharedManager] setDeviceVolume:1.0];
    
    //cancel local alarm
    [alarm cancelLocalNotification];
    
    if (isLaunchedFromLocalNotification) {
        
        NSLog(@"Entered from local notification, start wakeup view now");
        [EWWakeUpManager presentWakeUpViewWithActivity:activity];
        
    }else if (isLaunchedFromRemoteNotification){
        
        NSLog(@"Entered from remote notification, start wakeup view now");
        [EWWakeUpManager presentWakeUpViewWithActivity:activity];
        
    }else{
        //fire an alarm
        NSLog(@"=============> Firing Alarm timer notification <===============");
        UILocalNotification *note = [[UILocalNotification alloc] init];
        note.alertBody = [NSString stringWithFormat:@"It's time to wake up (%@)", [alarm.time date2String]];
        note.alertAction = @"Wake up!";
        //alarm.soundName = me.preference[@"DefaultTone"];
        note.userInfo = @{kLocalAlarmID: alarm.objectID.URIRepresentation.absoluteString,
                           kLocalNotificationTypeKey: kLocalNotificationTypeAlarmTimer};
        [[UIApplication sharedApplication] scheduleLocalNotification:note];
        
        //play sound
        [[AVManager sharedManager] playSoundFromFileName:[EWSession sharedSession].currentUser.preference[@"DefaultTone"]];
        
        //play sounds after 30s - time for alarm
        double d = 10;
#ifdef DEBUG
        d = 5;
#endif
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //present wakeupVC and paly when displayed
            [[AVManager sharedManager] volumeFadeWithCompletion:^{
                [EWWakeUpManager presentWakeUpViewWithActivity:activity];
            }];
            
        });
    }
}

#pragma mark - Utility
+ (BOOL)isRootPresentingWakeUpView{
    //determin if WakeUpViewController is presenting
    UIViewController *vc = rootViewController.presentedViewController;
    if ([vc isKindOfClass:[EWWakeUpViewController class]]) {
        return YES;
    }else if ([vc isKindOfClass:[EWPostWakeUpViewController class]]){
        return YES;
    }
    return NO;
}

+ (void)presentWakeUpView{
    //get absolute next task
    EWActivity *activity = [EWActivityManager sharedManager].currentAlarmActivity;
    //present
    [EWWakeUpManager presentWakeUpViewWithActivity:activity];
}

+ (void)presentWakeUpViewWithActivity:(EWActivity *)activity{
    if (![EWWakeUpManager isRootPresentingWakeUpView] && ![EWWakeUpManager sharedInstance].controller) {
        //init wake up view controller
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] initWithActivity:activity];
        //save to manager
        [EWWakeUpManager sharedInstance].controller = controller;
        
        //dispatch to main thread
        [rootViewController presentWithBlur:controller withCompletion:NULL];
        
    }else{
        DDLogInfo(@"Wake up view is already presenting, skip presenting wakeUpView");
		//NSParameterAssert([EWWakeUpManager sharedInstance].isWakingUp == YES);
    }
}

//indicate that the user has woke
+ (void)woke:(EWActivity *)activity{
    [EWWakeUpManager sharedInstance].controller = nil;
    [EWWakeUpManager sharedInstance].isWakingUp = NO;
    
    //handle wakeup signel
    [[ATConnect sharedConnection] engage:kWakeupSuccess fromViewController:rootViewController];
    
    //set wakeup time, move to past, schedule and save
    [EWActivityManager completeActivity:activity];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWokeNotification object:nil];
    
    //TODO: something to do in the future
    //notify friends and challengers
    //update history stats
}


#pragma mark - CHECK TIMER
- (void) alarmTimerCheck{
    //check time
    if (![EWSession sharedSession].currentUser) return;
    EWAlarm *alarm = [EWPerson myNextAlarm];
    if (alarm.state == NO) return;
    
    //alarm time up
    NSTimeInterval timeLeft = [alarm.time timeIntervalSinceNow];

	
    static NSTimer *timerScheduled;
    if (timeLeft > 0 && (!timerScheduled || ![timerScheduled.fireDate isEqualToDate:alarm.time])) {
        NSLog(@"%s: About to init alart timer in %fs", __func__, timeLeft);
		[timerScheduled invalidate];
		[NSTimer bk_scheduledTimerWithTimeInterval:timeLeft-1 block:^(NSTimer *timer) {
			[EWWakeUpManager handleAlarmTimerEvent:nil];
		} repeats:NO];
		NSLog(@"===========================>> Alarm Timer scheduled on %@) <<=============================", alarm.time.date2String);
    }
	
	if (timeLeft > kServerUpdateInterval) {
		[NSTimer scheduledTimerWithTimeInterval:timeLeft/2 target:self selector:@selector(alarmTimerCheck) userInfo:nil repeats:NO];
		DDLogVerbose(@"Next alarm timer check in %.1fs", timeLeft/2);
	}
}

- (void)sleepTimerCheck{
    //check time
    if (![EWSession sharedSession].currentUser) return;
    EWAlarm *alarm = [EWPerson myNextAlarm];
    if (alarm.state == NO) return;
    
    //alarm time up
    NSNumber *sleepDuration = [EWSession sharedSession].currentUser.preference[kSleepDuration];
    NSInteger durationInSeconds = sleepDuration.integerValue * 3600;
    NSDate *sleepTime = [alarm.time dateByAddingTimeInterval:-durationInSeconds];
	NSTimeInterval timeLeft = sleepTime.timeIntervalSinceNow;
    static NSTimer *timerScheduled;
    if (timeLeft > 0 && (!timerScheduled || ![timerScheduled.fireDate isEqualToDate:sleepTime])) {
        NSLog(@"%s: About to init alart timer in %fs", __func__, timeLeft);
		[timerScheduled invalidate];
		timerScheduled = [NSTimer bk_scheduledTimerWithTimeInterval:timeLeft-1 block:^(NSTimer *timer) {
			[EWWakeUpManager handleSleepTimerEvent:nil];
		} repeats:NO];
		NSLog(@"===========================>> Sleep Timer scheduled on %@ <<=============================", sleepTime.date2String);
    }
	
	if (timeLeft > 300) {
		[NSTimer scheduledTimerWithTimeInterval:timeLeft/2 target:self selector:@selector(alarmTimerCheck) userInfo:nil repeats:NO];
		DDLogVerbose(@"Next alarm timer check in %.1fs", timeLeft);
	}
}

+ (void)handleSleepTimerEvent:(UILocalNotification *)notification{
    NSString *taskID = notification.userInfo[kLocalAlarmID];
    if ([EWSession sharedSession].currentUser) {
        //logged in enter sleep mode
        EWAlarm *alarm = [EWPerson myNextAlarm];
        NSNumber *duration = [EWSession sharedSession].currentUser.preference[kSleepDuration];
        BOOL nextTaskMatched = [alarm.objectID.URIRepresentation.absoluteString isEqualToString:taskID];
        NSInteger h = alarm.time.timeIntervalSinceNow/3600;
        BOOL needSleep = h < duration.floatValue && h > 1;
        BOOL presenting = rootViewController.presentedViewController;
        if (nextTaskMatched && needSleep && !presenting) {
            EWSleepViewController *controller = [[EWSleepViewController alloc] initWithNibName:nil bundle:nil];
            [rootViewController presentViewControllerWithBlurBackground:controller];
        }
        
    }
}

@end
