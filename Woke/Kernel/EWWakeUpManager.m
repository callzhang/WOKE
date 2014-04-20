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
        manager = [super init];
        
    });
    return manager;
}


#pragma mark - Handle push notification
+ (void)handlePushNotification:(NSDictionary *)notification{
    NSString *type = notification[kPushTypeKey];
    NSString *taskID = notification[kPushTaskKey];
    NSString *mediaID = notification[kPushMediaKey];
    NSString *personID = notification[kPushPersonKey];
    
    if (!mediaID) {
        
        NSLog(@"Push doesn't have media ID, abort!");
        return;
    }

    
    __block EWMediaItem *media = [[EWMediaStore sharedInstance] getMediaByID:mediaID];
    __block EWTaskItem *task;
    //get task
    if (!taskID) {
        task = [media.tasks anyObject];
        taskID = task.ewtaskitem_id;
    }
    if (!personID) {
        personID = media.author.username;
        
#ifdef DEV_TEST
        EWPerson *sender = [[EWPersonStore sharedInstance] getPersonByID:personID];
        //alert
        [[[UIAlertView alloc] initWithTitle:@"Buzz 来啦" message:[NSString stringWithFormat:@"Got a buzz from %@. This message will not display in release.", sender.name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#endif
    }
    
    
    if ([type isEqualToString:kPushTypeBuzzKey]) {
        // ============== Buzz ================
        
        
        NSLog(@"Received buzz from %@", personID);
        
        //sound
        NSString *buzzType = media.buzzKey;
        NSDictionary *sounds = buzzSounds;
        NSString *buzzSound = buzzType?sounds[buzzType]:@"buzz.caf";
        
        if (task.completed || [[NSDate date] timeIntervalSinceDate:task.time] > kMaxWakeTime) {
            
            //============== the buzz window has passed ==============
            NSLog(@"@@@ Buzz window has passed, save it to next day");
            
            
            EWTaskItem *tmrTask = [[EWTaskStore sharedInstance] nextNth:1 validTaskForPerson:[EWDataStore user]];
            [media removeTasksObject:task];
            [media addTasksObject:tmrTask];
            [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
                [[EWDataStore currentContext] saveAndWait:NULL];
            }];
            
            return;
        }else if ([[NSDate date] isEarlierThan:task.time]){
            
            //============== buzz earlier than alarm, schedule local notif ==============
            
            
            UILocalNotification *notif = [[UILocalNotification alloc] init];
            //time
            NSDate *fireTime = [task.time timeByAddingSeconds:(150 + arc4random_uniform(5)*30)];
            notif.fireDate = fireTime;
            //sound
            
            notif.soundName = buzzSound;
            //message
            notif.alertBody = [NSString stringWithFormat:@"Buzz from %@", media.author.name];
            notif.userInfo = @{kPushTaskKey: taskID, kPushMediaKey: mediaID};
            //schedule
            [[UIApplication sharedApplication] scheduleLocalNotification:notif];
            
            NSLog(@"Scheduled local notif on %@", [fireTime date2String]);
            
#ifdef DEV_TEST
            [[AVManager sharedManager] playSoundFromFile:buzzSound];
#endif
            
        }else{
            
            //============== struggle ==============
            
            [EWWakeUpManager presentWakeUpViewWithTask:task];
            
            //broadcast event so that wakeup VC can play it
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewBuzzNotification object:self userInfo:@{kPushTaskKey: taskID}];
        }
        
      
        

        
    }else if ([type isEqualToString:kPushTypeMediaKey]){
        // ============== Media ================
        NSLog(@"Received voice type push");
        
                
        if ([[NSDate date] isEarlierThan:task.time]) {
            
            //============== pre alarm -> download ==============
            
            NSLog(@"Download media: %@", media.ewmediaitem_id);
            [[EWDownloadManager sharedInstance] downloadMedia:media];//will play after downloaded in test mode
            
        }else if (!task.completed && [[NSDate date] timeIntervalSinceDate:task.time] < kMaxWakeTime){
            
            //============== struggle ==============
            
            [EWWakeUpManager presentWakeUpViewWithTask:task];
            
            //broadcast so wakeupVC can react to it
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:self userInfo:@{kPushMediaKey: mediaID, kPushTaskKey: taskID}];
            
            
            
        }else{
            
            //Woke state -> assign media to next task, download
            
            EWTaskItem *nextTask = [[EWTaskStore sharedInstance] nextNth:1 validTaskForPerson: currentUser];
            [task removeMediasObject:media];
            [nextTask addMediasObject:media];
            [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
                NSLog(@"Unable to save: %@", error.description);
            }];
            
            //download to cache
            [[EWDownloadManager sharedInstance] downloadMedia:media];
        }
        
        
    }else if([type isEqualToString:kPushTypeTimerKey]){
        // ============== Timer ================
        
        [EWWakeUpManager handleAlarmTimerEvent];
        
        
    }else if([type isEqualToString:@"test"]){
        
        // ============== Test ================
        
        NSLog(@"Received === test === type push");
        [UIApplication sharedApplication].applicationIconBadgeNumber = 9;
        
        //EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
        EWMediaItem *media = [[EWMediaStore sharedInstance] getMediaByID:mediaID];
        //NSURL *cacheUrl = [NSURL fileURLWithPath:[FTWCache localPathForKey:media.audioKey]];
        //[[AVManager sharedManager] playSoundFromURL:cacheUrl];
        
        [[AVManager sharedManager] playSystemSound:[NSURL URLWithString:media.audioKey]];
        
    }else{
        // Other push type not supported
        NSString *str = [NSString stringWithFormat:@"Unknown push type received: %@", notification];
        NSLog(@"Received unknown type of push msg");
        EWAlert(str);
    }
}

+ (void)handleAlarmTimerEvent{
    NSLog(@"Start handle timer event");
    //next REAL (not VALID) task
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:currentUser];
    
    if (!task) {
        NSLog(@"%s No task found for next task, abord", __func__);
        return;
    } 
    
    //if no media for task, create a pseudo media
    if (task.medias.count == 0) {
        
        EWMediaItem *media = [[EWMediaStore sharedInstance] createPseudoMedia];
        [task addMediasObject:media];
        [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
            NSLog(@"Failed to save task for pseudo media: %@", error);
        }];
    }
    
    //download
    [[EWDownloadManager sharedInstance] downloadTask:task withCompletionHandler:^{
        //cancel local alarm
        [[EWTaskStore sharedInstance] cancelNotificationForTask:task];
        
        //fire a silent alarm
        [[EWTaskStore sharedInstance] fireSilentAlarmForTask:task];
        
        //present wakeupViewController
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] initWithTask:task];
        
        //play sounds after 30s
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             [controller startPlayCells];
        });
        
        //present wakeupVC
        [EWWakeUpManager presentWakeUpViewWithTask:task];
        
        //post notification
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewTimerNotification object:self userInfo:@{kPushTaskKey: task.ewtaskitem_id}];
        
    }];
    
}


#pragma mark - Handle notification info on app launch
+ (void)handleAppLaunchNotification:(id)notification{
    if([notification isKindOfClass:[UILocalNotification class]]){
        //========= local notif ===========
        UILocalNotification *localNotif = (UILocalNotification *)notification;
        NSString *taskID = [localNotif.userInfo objectForKey:kPushTaskKey];
        
       
        EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
        NSLog(@"Entered app with local notification with task on %@", [task.time weekday]);
        
        if (task.completed) {
            NSLog(@"Task has already completed, ignore the local notification entry");
        }
        
        [EWWakeUpManager presentWakeUpViewWithTask:task];
        
        
    }else if ([notification isKindOfClass:[NSDictionary class]]){
        
        //========== push notif ============
        
        NSDictionary *remoteNotif = (NSDictionary *)notification;
        NSString *type = remoteNotif[@"type"];
        
        if ([type isEqualToString:kPushTypeTimerKey] || [type isEqualToString:kPushTypeMediaKey] || [type isEqualToString:kPushTypeBuzzKey]) {
            //========== push notif ============
            //task type
            NSString *mediaID = remoteNotif[kPushMediaKey];
            if (!mediaID) {
                NSLog(@"Media ID not found, aboard");
                return;
            }
            EWMediaItem *media = [[EWMediaStore sharedInstance] getMediaByID:mediaID];
            EWTaskItem *task = [media.tasks anyObject];
            
            if (!task.completed) {
                [EWWakeUpManager presentWakeUpViewWithTask:task];
            }else{
                EWAlert(@"Someone has sent a voice greeting to you. You will hear it on your next wake up.");
                EWTaskItem *nextTask = [[EWTaskStore sharedInstance] nextValidTaskForPerson:currentUser];
                NSAssert(task.ewtaskitem_id != nextTask.ewtaskitem_id, @"Something wrong, the next task shouldn't be the same as the task passed from push");
                [task removeMediasObject:media];
                [nextTask addMediasObject:media];
                [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
                    NSLog(@"Couldn't move the media to next");
                }];
            }
            
            
        }else if([type isEqualToString:kPushTypeNoticeKey]){
            // ============== System notice ================
            
            NSString *notificationID = remoteNotif[kPushNofiticationKey];
            [EWNotificationManager handleNotification:notificationID];
            
        }
    }else{
        NSLog(@"Unexpected userInfo from app launch: %@", notification);
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
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:currentUser];
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
            [rootViewController dismissViewControllerAnimated:YES completion:^{
                
                [rootViewController presentViewController:controller animated:YES completion:NULL];
            }];
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

@end
