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

//UI
#import "EWWakeUpViewController.h"


@implementation EWWakeUpManager


#pragma mark - Handle push notification
+ (void)handlePushNotification:(NSDictionary *)notification{
    NSString *type = notification[kPushTypeKey];
    NSString *taskID = notification[kPushTaskKey];
    NSString *mediaID = notification[kPushMediaKey];
    NSString *personID = notification[kPushPersonKey];
    
    __block EWMediaItem *media = [[EWMediaStore sharedInstance] getMediaByID:mediaID];
    __block EWTaskItem *task;
    //get task
    if (!taskID) {
        task = [media.tasks anyObject];
        taskID = task.ewtaskitem_id;
    }
    if (!personID) {
        personID = media.author.username;
    }
    
    if ([type isEqualToString:kPushTypeBuzzKey]) {
        // ============== Buzz ================
        
        
        NSLog(@"Received buzz from %@", personID);
        
        //sound
        NSString *buzzType = media.buzzKey;
        NSDictionary *sounds = buzzSounds;
        NSString *buzzSound = buzzType?sounds[buzzType]:@"buzz.caf";
        
        if (task.completed || [[NSDate date] timeIntervalSinceDate:task.time] > kMaxWakeTime) {
            //the buzz window has passed
            NSLog(@"@@@ Buzz window has passed, save it to next day");
            EWTaskItem *tmrTask = [[EWTaskStore sharedInstance] nextTaskForPerson:[EWDataStore user]];
            [media removeTasksObject:task];
            [media addTasksObject:tmrTask];
            [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
                [[EWDataStore currentContext] saveAndWait:NULL];
            }];
            
            return;
        }else if ([[NSDate date] isEarlierThan:task.time]){
            //buzz earlier than alarm, schedule local notif
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
            
        }else if (![self isRootPresentingWakeUpView]){
            //struggle
            //root is not presenting wakeupVC
            [[AVManager sharedManager] playSoundFromFile:buzzSound];
        }
        
      
        //broadcast event so that wakeup VC can play it
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewBuzzNotification object:self userInfo:@{kPushTaskKey: taskID}];
        
        
        //active: play alert
        /*
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Buzz" message:message delegate:[EWServer sharedInstance] cancelButtonTitle:@"Cancel" otherButtonTitles:@"View", nil];
         alert.userInfo = @{@"type": kPushTypeBuzzKey};
         [alert show];*/
        
        
    }else if ([type isEqualToString:kPushTypeMediaKey]){
        // ============== Media ================
        NSLog(@"Received voice type push");
        
                
        if ([[NSDate date] isEarlierThan:task.time]) {
            
            //pre alarm -> download
            
            NSLog(@"Download media: %@", media.ewmediaitem_id);
            [[EWDownloadManager sharedInstance] downloadMedia:media];//will play after downloaded
            
        }else if (!task.completed && [[NSDate date] timeIntervalSinceDate:task.time] < kMaxWakeTime){
            
            NSLog(@"User struggle...");
            
            //present WakeUpView
            if (![EWWakeUpManager isRootPresentingWakeUpView]) {
                NSLog(@"Presenting wakeUpView");
                [rootViewController dismissViewControllerAnimated:YES completion:^{
                    [rootViewController presentViewController:[[EWWakeUpViewController alloc] initWithTask:task] animated:YES completion:^{
                        //post notification
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:self userInfo:@{kPushMediaKey: mediaID, kPushTaskKey: taskID}];
                    }];
                }];
            }else{
                //broadcast so wakeupVC can react to it
                [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:self userInfo:@{kPushMediaKey: mediaID, kPushTaskKey: taskID}];
            }
            
            
        }else{
            
            //Woke state -> assign media to next task, download
            
            EWTaskItem *nextTask = [[EWTaskStore sharedInstance] nextTaskAtDayCount:1 ForPerson:currentUser];
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
    //task
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskForPerson:currentUser];
    
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
        [controller startPlayCells];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//             [controller startPlayCells];
//        });
        
        //present wakeupVC
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![EWWakeUpManager isRootPresentingWakeUpView]) {
                [rootViewController dismissViewControllerAnimated:YES completion:^{
                    [rootViewController presentViewControllerWithBlurBackground:controller];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNewTimerNotification object:self userInfo:@{kPushTaskKey: task.ewtaskitem_id}];
                }];
            }
        });
        
    }];
    
}


#pragma mark - Handle notification info on app launch
+ (void)handleAppLaunchNotification:(id)notification{
    if([notification isKindOfClass:[UILocalNotification class]]){
        //========= local notif ===========
        UILocalNotification *localNotif = (UILocalNotification *)notification;
        NSString *taskID = [localNotif.userInfo objectForKey:kPushTaskKey];
        
#ifdef DEV_TEST
        EWAlert(taskID);
#endif
        
        NSLog(@"Entered app with local notification with taskID %@", taskID);
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
        controller.task  = [[EWTaskStore sharedInstance] getTaskByID:taskID];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        
        [rootViewController presentViewController:navigationController animated:YES completion:NULL];
    }else if ([notification isKindOfClass:[NSDictionary class]]){
        //========== remote notif ============
        NSDictionary *remoteNotif = (NSDictionary *)notification;
        NSString *type = remoteNotif[@"type"];
        
        if ([type isEqualToString:kPushTypeTimerKey]) {
            //task type
            NSString *taskID = remoteNotif[kPushTaskKey];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
                if (!task) {
                    task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:currentUser];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
                    
                    //stop if task has finished
                    //if (task.completed) return;
                    
                    //present wakeup vc
                    EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
                    controller.task = task;
                    [rootViewController presentViewController:controller animated:YES completion:^{
                        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
                    }];
                });
            });
            
            
            
        }else if ([type isEqualToString:kPushTypeMediaKey]){
            // ============== Media ================
            //media type
            EWAlert(@"You've got a voice tone. To find out who sent to you, get up on time on your next alarm!");
            
            
        }else if([type isEqualToString:kPushTypeBuzzKey]){
            // ============== Buzz ================
            //buzz type
            NSString *personID = remoteNotif[kPushPersonKey];
            NSString *taskID = remoteNotif[kPushTaskKey];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                EWPerson *sender = [[EWPersonStore sharedInstance] getPersonByID:personID];
                EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
                [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
                //add person if not
                if (![task.waker containsObject:sender]) {
                    [task addWakerObject:sender];
                }
                
                //stop if task has finished
                //if (task.completed) return;
                
                //present wakeup vc
                EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
                controller.task = task;
                [rootViewController presentViewController:controller animated:YES completion:^{
                    [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
                }];
            });
            
            
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



@end
