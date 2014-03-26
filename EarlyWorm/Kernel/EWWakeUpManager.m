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
    NSString *type = notification[@"type"];
    //NSString *message = notification[@"aps"][@"alert"];
    NSString *taskID = notification[kPushTaskKey];
    NSString *mediaID = notification[kPushMediaKey];
    NSString *personID = notification[kPushPersonKey];
    
    if ([type isEqualToString:kPushTypeBuzzKey]) {
        // ============== Buzz ================
        NSLog(@"Received buzz from %@", personID);
        //get task
        EWTaskItem *task;
        NSInteger delayInSeconds = 0;
        if (!taskID) {
            //get taskID
            task = [[EWTaskStore sharedInstance] nextTaskForPerson:currentUser];
            taskID = task.ewtaskitem_id;
        }
        if (task.success) {
            //the buzz window has passed
            return;
        }else if ([[NSDate date] isEarlierThan:task.time]){
            //delay the message if earlier than alarm, otherwise no delay
            delayInSeconds = [task.time timeIntervalSinceDate:[NSDate date]];
#ifdef DEV_TEST
            delayInSeconds = 3;
#endif
            NSLog(@"Delay for %zd seconds", delayInSeconds);
        }
        //add sender to task
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //save buzzers and waker
            EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
            EWPerson *sender = [[EWPersonStore sharedInstance] getPersonByID:personID];
            //add waker
            [task addWakerObject:sender];
            //add buzzer
            [task addBuzzer:sender atTime:[NSDate date]];
            [context saveOnSuccess:^{
                //
            } onFailure:^(NSError *error) {
                NSLog(@"Unable to save: %@", error.description);
            }];
            
            //back to main thread with a delay to the time of alarm
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
                //app state active
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                    //play sound
                    [[AVManager sharedManager] playSoundFromFile:@"buzz.caf"];
                    //determin if WakeUpViewController is presenting
                    if ([EWWakeUpManager isRootPresentingWakeUpView]) {
                        //wakeup vc is presenting
                        if ([rootViewController.presentingViewController isKindOfClass:[EWWakeUpViewController class]]) {
                            EWWakeUpViewController *vc = (EWWakeUpViewController *)rootViewController.presentingViewController;
                            [vc.tableView reloadData];
                        }
                        
                    }
                    else{
                        //present vc
                        
                        [rootViewController dismissViewControllerAnimated:YES completion:NULL];
                        EWWakeUpViewController *wakeVC = [[EWWakeUpViewController alloc] initWithTask:task];
                        [rootViewController presentViewController:wakeVC animated:YES completion:NULL];
                        
                    }
                    
                }
            });
        });
        
        //broadcast event
        if (!taskID) taskID = @"";
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewBuzzNotification object:self userInfo:@{kPushTaskKey: taskID}];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:self userInfo:@{kPushMediaKey: mediaID, kPushTaskKey: taskID}];
        
        
        //active: play alert
        /*
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Buzz" message:message delegate:[EWServer sharedInstance] cancelButtonTitle:@"Cancel" otherButtonTitles:@"View", nil];
         alert.userInfo = @{@"type": kPushTypeBuzzKey};
         [alert show];*/
        
        
    }else if ([type isEqualToString:kPushTypeMediaKey]){
        // ============== Media ================
        NSLog(@"Received media type push: %@", taskID);
        //get task
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //download
            EWTaskItem *task;
            EWMediaItem *media;
            @try {
                task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
                media = [[EWMediaStore sharedInstance] getMediaByID:mediaID];
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception);
            }
            
            
            //back to main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([[NSDate date] isEarlierThan:task.time]) {
                    
                    //pre alarm -> download
                    
                    NSLog(@"Download media: %@", media.ewmediaitem_id);
                    [[EWDownloadManager sharedInstance] downloadMedia:media];//will play after downloaded
                    
                }else if (!task.completed){
                    NSLog(@"Task is not completed, playing audio");
                    //struggle (or passed 10 min) -> play media
                    [[AVManager sharedManager] playMedia:media];
                    
                    //present WakeUpView
                    if (![EWWakeUpManager isRootPresentingWakeUpView]) {
                        NSLog(@"Presenting wakeUpView");
                        [rootViewController dismissViewControllerAnimated:YES completion:^{
                            [rootViewController presentViewController:[[EWWakeUpViewController alloc] initWithTask:task] animated:YES completion:^{
                                //post notification
                                [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:self userInfo:@{kPushMediaKey: mediaID, kPushTaskKey: taskID}];
                            }];
                        }];
                    }
                    
                    
                }else{
                    
                    //Woke state -> assign media to next task, download
                    
                    EWTaskItem *nextTask = [[EWTaskStore sharedInstance] nextTaskAtDayCount:1 ForPerson:currentUser];
                    [task removeMediasObject:media];
                    [nextTask addMediasObject:media];
                    [context saveOnSuccess:^{
                        //
                    } onFailure:^(NSError *error) {
                        NSLog(@"Unable to save: %@", error.description);
                    }];
                    
                    //download to cache
                    [[EWDownloadManager sharedInstance] downloadMedia:media];
                }
            });
            
        });
        
        
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
    
    //task
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskForPerson:currentUser];
    
    //download
    [[EWDownloadManager sharedInstance] downloadTask:task withCompletionHandler:^{
        //cancel local alarm
        [[EWTaskStore sharedInstance] cancelNotificationForTask:task];
        
        //fire a silent alarm
        [[EWTaskStore sharedInstance] fireSilentAlarmForTask:task];
        
        //play sounds
        [[AVManager sharedManager] playTask:task];
        
        //present wakeupViewController
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
        if (![EWWakeUpManager isRootPresentingWakeUpView]) {
            [rootViewController dismissViewControllerAnimated:YES completion:^{
                [rootViewController presentViewControllerWithBlurBackground:controller];
                [[NSNotificationCenter defaultCenter] postNotificationName:kNewTimerNotification object:self userInfo:@{kPushTaskKey: task.ewtaskitem_id}];
            }];
        }
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
