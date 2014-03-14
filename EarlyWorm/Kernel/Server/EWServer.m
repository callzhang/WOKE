//
//  EWServer.m
//  EarlyWorm
//
//  Translate client requests to server custom code, providing a set of tailored APIs to client coding environment.
//
//  Created by Lee on 2/21/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWServer.h"
#import "UIAlertView+.h"

//model
#import "EWDataStore.h"
#import "EWPersonStore.h"
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWMediaItem.h"
#import "EWMediaStore.h"
#import "EWDownloadManager.h"

//view
#import "EWWakeUpViewController.h"
#import "EWAppDelegate.h"
#import "AVManager.h"
#import "UIAlertView+.h"

//Tool
#import "EWUIUtil.h"

@implementation EWServer

+ (EWServer *)sharedInstance{
    static EWServer *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWServer alloc] init];
    });
    return manager;
}

+ (void)getPersonWakingUpForTime:(NSDate *)time location:(SMGeoPoint *)geoPoint callbackBlock:(SMFullResponseSuccessBlock)successBlock{
    NSLog(@"%s", __func__);
    
    NSString *userId = currentUser.username;
    NSInteger timeSince1970 = (NSInteger)[time timeIntervalSince1970];
    NSString *timeStr = [NSString stringWithFormat:@"%d", timeSince1970];
    NSString *lat = [geoPoint.latitude stringValue];
    NSString *lon = [geoPoint.longitude stringValue];
    NSString *geoStr = [NSString stringWithFormat:@"%@,%@", lat, lon];
    
    
    SMCustomCodeRequest *request = [[SMCustomCodeRequest alloc]
                                    initGetRequestWithMethod:@"get_person_waking_up"];
    
    [request addQueryStringParameterWhere:@"personId" equals:userId];
    [request addQueryStringParameterWhere:@"time" equals:timeStr];
    [request addQueryStringParameterWhere:@"location" equals:geoStr];
    
    [[[SMClient defaultClient] dataStore]
     performCustomCodeRequest:request
     onSuccess:successBlock
     onFailure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id responseBody){
         [NSException raise:@"Server custom code error" format:@"Reason: %@", error.description];
         //retry...
         
     }];
}

#pragma mark - Push Notification

+ (void)buzz:(NSArray *)users{
    //TODO: buzz sound selection
    //TODO: buzz message selection
    //TODO: bedge number
    NSMutableArray *userIDs = [[NSMutableArray alloc] initWithCapacity:users.count];
    for (EWPerson *person in users) {
        [userIDs addObject:person.username];
    }
        
    //send push notification, The payload can consist of the alert, badge, and sound keys.
    NSDictionary *pushMessage = @{@"aps": @{@"alert": [NSString stringWithFormat:@"New buzz from %@", currentUser.name],
                                            @"badge": @1,
                                            @"sound": @"buzz.caf",
                                            @"content-available": @1,
                                            },
                                  kPushPersonKey: currentUser.username,
                                  @"type": kPushTypeBuzzKey};
    [EWServer AWSPush:pushMessage toUsers:(NSArray *)users onSuccess:^(SNSPublishResponse *response) {
        NSLog(@"Buzz sent via AWS: %@", response.messageId);
    } onFailure:^(NSException *exception) {
        NSLog(@"Failed to send Buzz: %@", exception.description);
    }];
    
    /*
    [pushClient sendMessage:pushMessage toUsers:userIDs onSuccess:^{
        NSLog(@"Buzz successfully sent to %@", userIDs);
    } onFailure:^(NSError *error) {
        NSString *str = [NSString stringWithFormat:@"Failed to send buzz. Reason:%@", error.localizedDescription];
        EWAlert(str);
    }];
     */
    
}

+ (void)pushMedia:(NSString *)mediaId ForUsers:(NSArray *)users ForTask:(NSString *)taskId{
    //users
    NSMutableArray *userIDs = [[NSMutableArray alloc] initWithCapacity:users.count];
    for (EWPerson *person in users) {
        [userIDs addObject:person.username];
    }
    //message
    NSDictionary *pushMessage = @{@"aps": @{@"badge": @1,
                                              @"sound": @"media.caf",
                                              @"content-available": @1
                                              },
                                  @"type": kPushMediaKey,
                                  kPushPersonKey: currentUser.username,
                                  kPushMediaKey: mediaId,
                                  kPushTaskKey: taskId};
    [EWServer AWSPush:pushMessage toUsers:users onSuccess:^(SNSPublishResponse *response) {
        NSLog(@"Push media successfully sent to %@, message ID: %@", userIDs, response.messageId);
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
            hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
            hud.mode = MBProgressHUDModeCustomView;
            hud.labelText = @"Sent";
            [hud hide:YES afterDelay:1.5];
        });
        

    } onFailure:^(NSException *exception) {
        NSString *str = [NSString stringWithFormat:@"Send push message about media %@ failed. Reason:%@", mediaId, exception.description];
        EWAlert(str);
    }];
    /*
    [pushClient sendMessage:pushMessage toUsers:userIDs onSuccess:^{
        NSLog(@"Push media successfully sent to %@", userIDs);
        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
        hud.mode = MBProgressHUDModeCustomView;
        hud.labelText = @"Sent";
        [hud hide:YES afterDelay:1.5];

    } onFailure:^(NSError *error) {
        NSString *str = [NSString stringWithFormat:@"Send push message about media %@ failed. Reason:%@", mediaId, error.localizedDescription];
        EWAlert(str);
    }];*/
}


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
            task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:currentUser];
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
            NSLog(@"Delay for %d seconds", delayInSeconds);
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
                    if ([EWServer isRootPresentingWakeUpView]) {
                        //wakeup vc is presenting
                        EWWakeUpViewController *vc = (EWWakeUpViewController *)rootViewController.presentingViewController;
                        [vc.tableView reloadData];
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
        
       
        
        //active: play alert
        /*
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Buzz" message:message delegate:[EWServer sharedInstance] cancelButtonTitle:@"Cancel" otherButtonTitles:@"View", nil];
        alert.userInfo = @{@"type": kPushTypeBuzzKey};
        [alert show];*/
        

    }else if ([type isEqualToString:kPushTypeMediaKey]){
        // ============== Media ================
        NSLog(@"Received Task type push: %@", taskID);
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
                    if (![EWServer isRootPresentingWakeUpView]) {
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
        
        //check download
        EWDownloadManager *dlManager = [EWDownloadManager sharedInstance];
        
        //task
        EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
        
        //add download completion task
        dlManager.completionTask = ^{
            
            //use EWWakeUpVC to start play
            EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] initWithTask:task];
            
            //active: alert
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                EWAlert(@"Time to wake up!");
                
                
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
                
                //present wakeup view
                [rootViewController presentViewController:nav animated:YES completion:NULL];
                
                
            }else{
                //play
                [controller startPlayCells];
            }
            
            
        };
        
        
        
        //>>>>> start download task <<<<<
        [dlManager downloadTask:task];
        
        
    }else if([type isEqualToString:@"test"]){
        
        // ============== Test ================
        
        NSLog(@"Received === test === type push");
        //EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
        EWMediaItem *media = [[EWMediaStore sharedInstance] getMediaByID:mediaID];
        [[AVManager sharedManager] playMedia:media];
        
        
        
    }else{
        // Other push type not supported
        NSString *str = [NSString stringWithFormat:@"Unknown push type received: %@", notification];
        NSLog(@"Received unknown type of push msg");
        EWAlert(str);
    }
}


#pragma mark - Handle notification info on app launch
+ (void)handleAppLaunchNotification:(id)notification{
    if([notification isKindOfClass:[UILocalNotification class]]){
        //========= local notif ===========
        UILocalNotification *localNotif = (UILocalNotification *)notification;
        NSString *taskID = [localNotif.userInfo objectForKey:kLocalNotificationUserInfoKey];
        
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //current task
                EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:currentUser]; //[[EWTaskStore sharedInstance] getTaskByID:taskID];
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

#pragma mark - Alert Delegate
/**
 action when user received push alert in active state
 1. buzz: play the buzz (shouldn't be here)
 2. media:
    a. before woke: play voice
    b. after woke or before timer: do nothing
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *type = alertView.userInfo[@"type"];
    
    if ([type isEqualToString:kPushTypeBuzzKey]) {
        NSLog(@"Clicked OK on buzz");
        
    }else if ([type isEqualToString:kPushTypeMediaKey]) {
        //got taskInAction
        EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:alertView.userInfo[kPushTaskKey]];
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
        controller.task = task;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        EWAppDelegate * appDelegate = (EWAppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate.window.rootViewController presentViewController:navigationController animated:YES completion:NULL];
    }

}


#pragma mark - AWS method

+ (void)AWSPush:(NSDictionary *)pushDic toUsers:(NSArray *)users onSuccess:(void (^)(SNSPublishResponse *))successBlock onFailure:(void (^)(NSException *))failureBlock{
    NSString *pushStr = [EWUIUtil toString:pushDic];
    pushStr = [pushStr stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    pushStr = [NSString stringWithFormat:@"{\"APNS_SANDBOX\":\"%@\", \"default\":\"You got a new push from AWS\"}", pushStr];
    SNSPublishRequest *request = [[SNSPublishRequest alloc] init];
    request.message = pushStr;
    request.messageStructure = @"json";
    
    for (EWPerson *target in users) {
        request.targetArn = target.aws_id;
        if (!currentUser.aws_id) NSLog(@"Unable to send message: no AWS ID found on target:%@", target.username);
        NSLog(@"Push content: %@ \nTarget:%@", pushStr, currentUser.name);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @try {
                SNSPublishResponse *response = [snsClient publish:request];
                successBlock(response);
            }
            @catch (NSException *exception) {
                failureBlock(exception);
            }
        });
    }
    
    
    

}

@end
