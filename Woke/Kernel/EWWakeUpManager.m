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

//UI
#import "EWWakeUpViewController.h"
#import "EWSleepViewController.h"
#import "EWPostWakeUpViewController.h"


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
    EWActivity *activity;
	
    if (!mediaID) {
        NSLog(@"Push doesn't have media ID, abort!");
        return;
    }

    
    EWMedia *media = [EWMedia getMediaByID:mediaID];
    EWAlarm *nextAlarm = [EWPerson myNextAlarm];
    //NSDate *nextTimer = nextAlarm.time;
    
    if ([type isEqualToString:kPushMediaTypeVoice]) {
        // ============== Media ================
        NSParameterAssert(mediaID);
        NSLog(@"Received voice type push");
        

        //download media
        NSLog(@"Downloading media: %@", media.objectId);
        
        //[[EWDownloadManager sharedInstance] downloadMedia:media];//will play after downloaded in test mode+
        
        //determin action based on task timing
        if ([[NSDate date] isEarlierThan:nextAlarm.time]) {
            
            //============== pre alarm -> download ==============
            
        }else if (!task.completed && [[NSDate date] timeIntervalSinceDate:task.time] < kMaxWakeTime){
            
            //============== struggle ==============
            
            [EWWakeUpManager presentWakeUpViewWithTask:task];
            
            //broadcast so wakeupVC can react to it
            //[[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:self userInfo:@{kPushMediaKey: mediaID, kPushTaskKey: task.objectId}];
            
            //use KVO
            [task addMediasObject:media];
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
        
        [[AVManager sharedManager] playSystemSound:[NSURL URLWithString:media.audioKey]];
        
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
    EWTaskItem *nextTask = [[EWTaskManager sharedInstance] nextValidTaskForPerson:[EWSession sharedSession].currentUser];
	
    //get target task
    EWTaskItem *task;
    if (info) {
        NSString *taskID = info[kPushTaskID];
        NSString *taskLocalID = info[kLocalTaskKey];
        NSParameterAssert(taskID || taskLocalID);
        if (taskID) {
            isLaunchedFromRemoteNotification = YES;
            task = [[EWTaskManager sharedInstance] getTaskByID:taskID];
        }else if (taskLocalID){
            isLaunchedFromLocalNotification = YES;
            NSURL *url = [NSURL URLWithString:taskLocalID];
            NSManagedObjectID *ID = [mainContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
            if (ID) {
                task = (EWTaskItem *)[mainContext existingObjectWithID:ID error:NULL];
            }else{
                DDLogError(@"The task objectID is invalid for alarm timer local notif: %@",taskLocalID);
            }
        }
		
		//check
t				DDLogWarn(@"Task passed in %@(%@) is not the next task", task.serverID, task.time);
				task = nextTask;
			}
		}
		else{
			if (isLaunchedFromLocalNotification) {
				DDLogError(@"Task from local notif for wake doesn't exist!\n%@", taskLocalID);
			}else if (isLaunchedFromRemoteNotification){
				DDLogError(@"Task from remote notif for wake doesn't exist!\n%@", taskID);
			}else{
				DDLogError(@"Task for wake doesn't exist!\n%@", info);
			}
			return;
		}
	}else{
		task = nextTask;
	}
	
	
    NSLog(@"Start handle timer event");
    if (!task) {
        NSLog(@"*** %s No task found for next task, abord", __func__);
        return;
    }
    
    if (task.state == NO) {
        NSLog(@"Task is OFF, skip today's alarm");
        return;
    }
    
    if (task.completed) {
        // task completed
        NSLog(@"Task has completed at %@, skip.", task.completed.date2String);
        return;
    }
    if (task.time.timeElapsed > kMaxWakeTime) {
        NSLog(@"Task(%@) from notification has passed the wake up window. Handle it with checkPastTasks.", task.objectId);
        [[EWTaskManager sharedInstance] checkPastTasksInBackgroundWithCompletion:NULL];
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
    NSArray *medias = [EWSession sharedSession].currentUser.mediaAssets.allObjects;
    
    //fill media from mediaAssets, if no media for task, create a pseudo media
    NSInteger nVoice = [[EWTaskManager sharedInstance] numberOfVoiceInTask:task];
    NSInteger nVoiceNeeded = kMaxVoicePerTask - nVoice;
    
    for (EWMedia *media in medias) {
        if (!media.targetDate || [media.targetDate timeIntervalSinceNow]<0) {
            
            //find media to add
            [task addMediasObject: media];
            //remove media from mediaAssets, need to remove relation doesn't have inverse relation. This is to make sure the sender doesn't need to modify other person
            [[EWSession sharedSession].currentUser removeMediaAssetsObject:media];
            [media removeReceiversObject:[EWSession sharedSession].currentUser];
            
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
    nVoice = [[EWTaskManager sharedInstance] numberOfVoiceInTask:task];
    if (nVoice == 0) {
        //need to create some voice
        EWMedia *media = [[EWMediaManager sharedInstance] getWokeVoice];
        [task addMediasObject:media];
    }
    
    //save
    [EWSync save];
	
	//set volume
	[[AVManager sharedManager] setDeviceVolume:1.0];
    
    //cancel local alarm
    [[EWTaskManager sharedInstance] cancelNotificationForTask:task];
    
    if (isLaunchedFromLocalNotification) {
        
        NSLog(@"Entered from local notification, start wakeup view now");
        [EWWakeUpManager presentWakeUpViewWithTask:task];
        
    }else if (isLaunchedFromRemoteNotification){
        
        NSLog(@"Entered from remote notification, start wakeup view now");
        [EWWakeUpManager presentWakeUpViewWithTask:task];
        
    }else{
        //fire an alarm
        NSLog(@"=============> Firing Alarm timer notification <===============");
        UILocalNotification *alarm = [[UILocalNotification alloc] init];
        alarm.alertBody = [NSString stringWithFormat:@"It's time to wake up (%@)", [task.time date2String]];
        alarm.alertAction = @"Wake up!";
        //alarm.soundName = me.preference[@"DefaultTone"];
        alarm.userInfo = @{kLocalTaskKey: task.objectID.URIRepresentation.absoluteString,
                           kLocalNotificationTypeKey: kLocalNotificationTypeAlarmTimer};
        [[UIApplication sharedApplication] scheduleLocalNotification:alarm];
        
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
                [EWWakeUpManager presentWakeUpViewWithTask:task];
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
    EWTaskItem *task = [[EWTaskManager sharedInstance] nextTaskAtDayCount:0 ForPerson:[EWSession sharedSession].currentUser];
    //present
    [EWWakeUpManager presentWakeUpViewWithTask:task];
}

+ (void)presentWakeUpViewWithTask:(EWTaskItem *)task{
    if (![EWWakeUpManager isRootPresentingWakeUpView] && ![EWWakeUpManager sharedInstance].controller) {
        //init wake up view controller
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] initWithTask:task];
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
+ (void)woke:(EWTaskItem *)task{
    [EWWakeUpManager sharedInstance].controller = nil;
    [EWWakeUpManager sharedInstance].isWakingUp = NO;
    
    //handle wakeup signel
    [[ATConnect sharedConnection] engage:kWakeupSuccess fromViewController:rootViewController];
    
    //set wakeup time, move to past, schedule and save
    [[EWTaskManager sharedInstance] completedTask:task];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWokeNotification object:nil];
    
    //TODO: something to do in the future
    //notify friends and challengers
    //update history stats
}


#pragma mark - CHECK TIMER
- (void) alarmTimerCheck{
    //check time
    if (![EWSession sharedSession].currentUser) return;
    EWTaskItem *task = [[EWTaskManager sharedInstance] nextValidTaskForPerson:[EWSession sharedSession].currentUser];
    if (task.state == NO) return;
    
    //alarm time up
    NSTimeInterval timeLeft = [task.time timeIntervalSinceNow];

	
    static NSTimer *timerScheduled;
    if (timeLeft > 0 && (!timerScheduled || ![timerScheduled.fireDate isEqualToDate:task.time])) {
        NSLog(@"%s: About to init alart timer in %fs", __func__, timeLeft);
		[timerScheduled invalidate];
		[NSTimer bk_scheduledTimerWithTimeInterval:timeLeft-1 block:^(NSTimer *timer) {
			[EWWakeUpManager handleAlarmTimerEvent:nil];
		} repeats:NO];
		NSLog(@"===========================>> Alarm Timer scheduled on %@) <<=============================", task.time.date2String);
    }
	
	if (timeLeft > kServerUpdateInterval) {
		[NSTimer scheduledTimerWithTimeInterval:timeLeft/2 target:self selector:@selector(alarmTimerCheck) userInfo:nil repeats:NO];
		DDLogVerbose(@"Next alarm timer check in %.1fs", timeLeft/2);
	}
}

- (void)sleepTimerCheck{
    //check time
    if (![EWSession sharedSession].currentUser) return;
    EWTaskItem *task = [[EWTaskManager sharedInstance] nextValidTaskForPerson:[EWSession sharedSession].currentUser];
    if (task.state == NO) return;
    
    //alarm time up
    NSNumber *sleepDuration = [EWSession sharedSession].currentUser.preference[kSleepDuration];
    NSInteger durationInSeconds = sleepDuration.integerValue * 3600;
    NSDate *sleepTime = [task.time dateByAddingTimeInterval:-durationInSeconds];
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
    NSString *taskID = notification.userInfo[kLocalTaskKey];
    if ([EWSession sharedSession].currentUser) {
        //logged in enter sleep mode
        EWTaskItem *task = [[EWTaskManager sharedInstance] nextValidTaskForPerson:[EWSession sharedSession].currentUser];
        NSNumber *duration = [EWSession sharedSession].currentUser.preference[kSleepDuration];
        BOOL nextTaskMatched = [task.objectID.URIRepresentation.absoluteString isEqualToString:taskID];
        NSInteger h = task.time.timeIntervalSinceNow/3600;
        BOOL needSleep = h < duration.floatValue && h > 1;
        BOOL presenting = rootViewController.presentedViewController;
        if (nextTaskMatched && needSleep && !presenting) {
            EWSleepViewController *controller = [[EWSleepViewController alloc] initWithNibName:nil bundle:nil];
            [rootViewController presentViewControllerWithBlurBackground:controller];
        }
        
    }
}

@end
