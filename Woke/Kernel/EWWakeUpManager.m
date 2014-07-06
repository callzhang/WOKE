//
//  EWWakeUpManager.m
//  EarlyWorm
//
//  Created by Lei on 3/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWWakeUpManager.h"
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWPersonStore.h"
#import "AVManager.h"
#import "EWAppDelegate.h"
#import "EWMediaItem.h"
#import "EWMediaStore.h"
#import "EWDownloadManager.h"
#import "UIViewController+Blur.h"
#import "EWDownloadManager.h"
#import "EWNotificationManager.h"
#import "EWPerson.h"
#import "EWUserManagement.h"
#import "EWServer.h"


//UI
#import "EWWakeUpViewController.h"


@interface EWWakeUpManager()
//retain the controller so that it won't deallocate when needed
@property (nonatomic, retain) EWWakeUpViewController *controller;
@end


@implementation EWWakeUpManager

+ (EWWakeUpManager *)sharedInstance{
    static EWWakeUpManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWWakeUpManager alloc] init];
        
    });
    return manager;
}


#pragma mark - Handle push notification
+ (void)handlePushNotification:(NSDictionary *)notification{
    NSString *type = notification[kPushTypeKey];
    NSString *mediaID = notification[kPushMediaKey];
    NSString *taskID = notification[kPushTaskKey];
    NSString *personID = notification[kPushPersonKey];
    
    if (!mediaID) {
        
        NSLog(@"Push doesn't have media ID, abort!");
        return;
    }

    
    EWMediaItem *media = [[EWMediaStore sharedInstance] getMediaByID:mediaID];
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextValidTaskForPerson:me];
//    EWPerson *person;
//    if (!personID) {
//        personID = media.author.username;
//        person = media.author;
//    }
    
    
    if ([type isEqualToString:kPushTypeBuzzKey]) {
        // ============== Buzz ===============
        
        NSLog(@"Received buzz from %@", media.author.name);
        
        //sound
        NSString *buzzSoundName = media.buzzKey?:me.preference[@"buzzSound"];
        NSDictionary *sounds = buzzSounds;
        NSString *buzzSound = sounds[buzzSoundName];
        
#ifdef DEV_TEST
        EWPerson *sender = media.author;
        //alert
        [[[UIAlertView alloc] initWithTitle:@"Buzz 来啦" message:[NSString stringWithFormat:@"Got a buzz from %@. This message will not display in release.", sender.name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        
#endif
        
        if (task.completed || [[NSDate date] timeIntervalSinceDate:task.time] > kMaxWakeTime) {
            
            //============== the buzz window has passed ==============
            NSLog(@"@@@ Buzz window has passed, save it to next day");
            
            //do nothing
            
            return;
            
        }else if ([[NSDate date] isEarlierThan:task.time]){
            
            //============== buzz earlier than alarm, schedule local notif ==============
            
            UILocalNotification *notif = [[UILocalNotification alloc] init];
            //time: a random time after
            NSDate *fireTime = [task.time timeByAddingSeconds:(150 + arc4random_uniform(5)*30)];
            notif.fireDate = fireTime;
            //sound
            
            notif.soundName = buzzSound;
            //message
            notif.alertBody = [NSString stringWithFormat:@"Buzz from %@", media.author.name];
            notif.userInfo = @{kPushTaskKey: task.objectId, kPushMediaKey: mediaID, kLocalTaskKey: task.objectID.URIRepresentation.absoluteString};
            //schedule
            [[UIApplication sharedApplication] scheduleLocalNotification:notif];
            
            NSLog(@"Scheduled local notif on %@", [fireTime date2String]);
            
        }else{
            
            //============== struggle ==============
            
            [EWWakeUpManager presentWakeUpViewWithTask:task];
            
            //broadcast event so that wakeup VC can play it
            //[[NSNotificationCenter defaultCenter] postNotificationName:kNewBuzzNotification object:self userInfo:@{kPushTaskKey: task.objectId}];
            
            [task addMediasObject:media];
            [EWDataStore save];
        }
        

        
    }else if ([type isEqualToString:kPushTypeMediaKey]){
        // ============== Media ================
        NSLog(@"Received voice type push");
        

        //download media
        NSLog(@"Downloading media: %@", media.objectId);
        
        //[[EWDownloadManager sharedInstance] downloadMedia:media];//will play after downloaded in test mode+
        
        //determin action based on task timing
        if ([[NSDate date] isEarlierThan:task.time]) {
            
            //============== pre alarm -> download ==============
            
        }else if (!task.completed && [[NSDate date] timeIntervalSinceDate:task.time] < kMaxWakeTime){
            
            //============== struggle ==============
            
            [EWWakeUpManager presentWakeUpViewWithTask:task];
            
            //broadcast so wakeupVC can react to it
            //[[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:self userInfo:@{kPushMediaKey: mediaID, kPushTaskKey: task.objectId}];
            
            //use KVO
            [task addMediasObject:media];
            [EWDataStore save];
            
        }else{
            
            //Woke state -> assign media to next task, download
            if (![me.mediaAssets containsObject:media]) {
                [me addMediaAssetsObject:media];
                
                EWTaskItem *myTask = [EWMediaStore myTaskInMedia:media];
                if (myTask) {
                    //need to move to media pool
                    [media removeTasksObject:myTask];
                    [EWDataStore save];
                }
            }
            
        }
        
#ifdef DEV_TEST
        [[[UIAlertView alloc] initWithTitle:@"Voice来啦" message:@"收到一条神秘的语音."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#endif
        
        
    }else if([type isEqualToString:kPushTypeTimerKey]){
        // ============== Timer ================
        
        [EWWakeUpManager handleAlarmTimerEvent:notification];
        
        
    }else if([type isEqualToString:@"test"]){
        
        // ============== Test ================
        
        NSLog(@"Received === test === type push");
        [UIApplication sharedApplication].applicationIconBadgeNumber = 9;
        
        [[AVManager sharedManager] playSystemSound:[NSURL URLWithString:media.audioKey]];
        
    }else{
        // Other push type not supported
        NSString *str = [NSString stringWithFormat:@"Unknown push type received: %@", notification];
        NSLog(@"Received unknown type of push msg");
        EWAlert(str);
    }
}

+ (void)handleAlarmTimerEvent:(NSDictionary *)info{
    BOOL isLaunchedFromLocalNotification = NO;
    
    //get target task
    EWTaskItem *task;
    if (info) {
        NSString *taskID = info[kPushTaskKey];
        NSString *taskLocalID = info[kLocalTaskKey];
        NSParameterAssert(taskID || taskLocalID);
        if (taskID) {
            task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
        }else if (taskLocalID){
            isLaunchedFromLocalNotification = YES;
            task = [[EWTaskStore sharedInstance] getTaskByLocalID:taskLocalID];
        }
    }else{
        task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:me];
    }
    
    NSLog(@"Start handle timer event");
    if (!task) {
        NSLog(@"%s No task found for next task, abord", __func__);
        return;
    }
    
    if (task.state == NO) {
        NSLog(@"Task is OFF, skip today's alarm");
        return;
    }
    
    if (task.completed || task.time.timeElapsed > kMaxWakeTime) {
        task.completed = [task.time timeByAddingSeconds:kMaxWakeTime];
        [EWDataStore save];
        NSLog(@"Task has completed at %@, skip.", task.completed.date2String);
        return;
    }
    
    //update media
    NSArray *medias = [[EWMediaStore sharedInstance] checkMediaAssets];
    
    //fill media from mediaAssets, if no media for task, create a pseudo media
    NSInteger nVoice = [[EWTaskStore sharedInstance] numberOfVoiceInTask:task];
    NSInteger nVoiceNeeded = kMaxVoicePerTask - nVoice;
    
    for (EWMediaItem *media in medias) {
        if (!media.targetDate || [media.targetDate isEarlierThan:[NSDate date]]) {
            
            //find media to add
            [task addMediasObject: media];
            //remove media from mediaAssets
            [[EWPersonStore me] removeMediaAssetsObject:media];            
            
            if ([media.type isEqualToString: kMediaTypeVoice]) {
                
                //reduce the counter
                nVoiceNeeded--;
                if (nVoiceNeeded <= 0) {
                    break;
                }
            }
        }
    }
    
    //add fake media is needed
    nVoice = [[EWTaskStore sharedInstance] numberOfVoiceInTask:task];
    if (nVoice == 0) {
        //need to create some voice
        EWMediaItem *media = [[EWMediaStore sharedInstance] createPseudoMedia];
        [task addMediasObject:media];
    }
    //TODO: need to get some data from server (Simin)
    
    //save
    [EWDataStore save];
    
    //cancel local alarm
    [[EWTaskStore sharedInstance] cancelNotificationForTask:task];
    
    if (isLaunchedFromLocalNotification) {
        
        NSLog(@"Entered from local notification, start wakeup view now");
        [EWWakeUpManager presentWakeUpViewWithTask:task];
        
    }else{
        //fire an alarm
        NSLog(@"Firing alarm");
        UILocalNotification *alarm = [[UILocalNotification alloc] init];
        alarm.alertBody = [NSString stringWithFormat:@"It's time to wake up (%@)", [task.time date2String]];
        alarm.alertAction = @"Wake up!";
        alarm.userInfo = @{kLocalTaskKey: task.objectID.URIRepresentation.absoluteString,
                           kLocalNotificationTypeKey: kLocalNotificationTypeAlarmTimer};
        [[UIApplication sharedApplication] scheduleLocalNotification:alarm];
        [[AVManager sharedManager] playSoundFromFile:me.preference[@"DefaultTone"]];
        
        //play sounds after 30s - time for alarm
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //present wakeupVC and paly when displayed
            [EWWakeUpManager presentWakeUpViewWithTask:task];
        });
    }
    
    
    
    
}

#pragma mark - Utility
+ (BOOL)isRootPresentingWakeUpView{
    //determin if WakeUpViewController is presenting
    UIViewController *vc = rootViewController.presentedViewController;
    if ([vc isKindOfClass:[EWWakeUpViewController class]]) {
        return YES;
    }
    
    return NO;
}

+ (void)presentWakeUpView{
    //get absolute next task
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:me];
    //present
    [EWWakeUpManager presentWakeUpViewWithTask:task];
}

+ (void)presentWakeUpViewWithTask:(EWTaskItem *)task{
    if (![EWWakeUpManager isRootPresentingWakeUpView]) {
        //init wake up view controller
        __block EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] initWithTask:task];
        //save to manager
        [EWWakeUpManager sharedInstance].controller = controller;
        
        //dispatch to main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Presenting wakeUpView");
            if (rootViewController.presentedViewController) {
                [rootViewController dismissViewControllerAnimated:YES completion:^{
                    [rootViewController presentViewControllerWithBlurBackground:controller];
                }];
            }else{
                [rootViewController presentViewControllerWithBlurBackground:controller];
            }
            
        });
        
        
    }else{
        //save controller if not
        id controller = rootViewController.presentedViewController;
        if ([controller isKindOfClass:[EWWakeUpViewController class]]) {
            [EWWakeUpManager sharedInstance].controller = controller;
        } else {
            NSLog(@"*** Something wrong with detecting presented VC! Please cheeck!");
            [EWWakeUpManager presentWakeUpView];
        }
    }
}

//indicate that the user has woke
+ (void)woke{
    [EWWakeUpManager sharedInstance].controller = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kWokeNotification object:nil];
    //something to do in the future
    //notify friends and challengers
    //update history stats
}


#pragma mark - CHECK ALARM TIMER
+ (void) alarmTimerCheck{
    NSLog(@"===========================>> Check Alarm Timer <<=============================");
    
    //check time
    if (!me) return;
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:me];
    if (task.state == NO) return;
    
    //alarm time up
    NSTimeInterval timeLeft = [task.time timeIntervalSinceNow];
    
    if (timeLeft < kServerUpdateInterval && timeLeft > 0) {
        NSLog(@"alarmTimerCheck: About to init alart timer in %fs",timeLeft);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeLeft - 1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [EWWakeUpManager handleAlarmTimerEvent:nil];
        });
    }
    
}



@end
