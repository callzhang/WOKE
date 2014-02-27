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
#import "EWDataStore.h"
#import "EWPersonStore.h"
#import "UIAlertView+.h"
#import "EWTaskStore.h"
#import "EWWakeUpViewController.h"
#import "EWAppDelegate.h"

//model
#import "EWTaskItem.h"

@implementation EWServer

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
    NSDictionary *pushMessage = @{@"alert": [NSString stringWithFormat:@"New buzz from %@", currentUser.name],
                                  @"badge": @1,
                                  kPushPersonKey: currentUser.username,
                                  @"type": kPushTypeBuzzKey,
                                  @"sound": @"buzz.caf"};
    
    [pushClient sendMessage:pushMessage toUsers:userIDs onSuccess:^{
        NSLog(@"Buzz successfully sent to %@", userIDs);
    } onFailure:^(NSError *error) {
        NSString *str = [NSString stringWithFormat:@"Failed to send buzz. Reason:%@", error.localizedDescription];
        EWAlert(str);
    }];

}

+ (void)pushMedia:(NSString *)mediaId ForUsers:(NSArray *)users ForTask:(NSString *)taskId{
    //users
    NSMutableArray *userIDs = [[NSMutableArray alloc] initWithCapacity:users.count];
    for (EWPerson *person in users) {
        [userIDs addObject:person.username];
    }
    //message
    NSDictionary *pushMessage = @{@"alert": [NSString stringWithFormat:@"New media from %@", currentUser.name],
                                  @"badge": @1,
                                  @"sound": @"buzz.caf",
                                  @"type": kPushMediaKey,
                                  kPushPersonKey: currentUser.username,
                                  kPushMediaKey: mediaId,
                                  kPushTaskKey: taskId,
                                  @"content-available": @1};
    [pushClient sendMessage:pushMessage toUsers:userIDs onSuccess:^{
        NSLog(@"Push media successfully sent to %@", userIDs);
    } onFailure:^(NSError *error) {
        NSString *str = [NSString stringWithFormat:@"Send push message about media %@ failed. Reason:%@", mediaId, error.localizedDescription];
        EWAlert(str);
    }];
}


#pragma mark - Handle push notification
+ (void)handlePushNotification:(NSDictionary *)notification{
    NSString *type = notification[@"type"];
    NSString *message = [[notification valueForKey:@"aps"] valueForKey:@"alert"];
    NSString *taskID;
    NSString *mediaID;
    
    @try {
        taskID = notification[kPushTaskKey];
        mediaID = notification[kPushMediaKey];
    }
    @catch (NSError *err) {
        NSLog(@"%@", err);
    }

    
    if ([type isEqualToString:kPushTypeBuzzKey]) {
        NSString *from = notification[kPushPersonKey];
        //TODO: add from to task
        
        //active: play alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Buzz" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alert.userInfo = @{@"type": kPushTypeBuzzKey};
        [alert show];
        //suspend: do nothing
    }else if ([type isEqualToString:kPushTypeMediaKey]){
        //download
        //test: play
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Media" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Listen", nil];
        [alert show];
        //associate
        alert.userInfo = @{@"type": kPushTypeMediaKey, kPushTaskKey: taskID, kPushMediaKey: mediaID};
    }else if([type isEqualToString:kPushTypeTimerKey]){
        //active: alert
        EWAlert(@"Time to wake up!");
        //suspend: play media
    }else{
        NSString *str = [NSString stringWithFormat:@"Unknown push received: %@", notification];
        EWAlert(str);
    }
}


#pragma mark - Handle notification info on app launch
+ (void)handleAppLaunchNotification:(id)notification{
    if([notification isKindOfClass:[UILocalNotification class]]){
        //local notif
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
        //remote notif
        NSDictionary *remoteNotif = (NSDictionary *)notification;
        NSString *type = remoteNotif[@"type"];
        
        if ([type isEqualToString:kPushTypeTimerKey]) {
            //timer type
            NSString *taskID = remoteNotif[kPushTaskKey];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
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
            //media type
            EWAlert(@"You've got a voice tone. To find out who sent to you, get up on time on your next alarm!");
        }else if([type isEqualToString:kPushTypeBuzzKey]){
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

#pragma mark - Alert Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *type = alertView.userInfo[@"type"];
    if ([type isEqualToString:kPushTypeBuzzKey]) {
            //
    }else if ([type isEqualToString:kPushTypeMediaKey]) {
        //got taskInAction
        EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:alertView.userInfo[kPushTaskKey]];
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
        controller.task = task;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        EWAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate.window.rootViewController presentViewController:navigationController animated:YES completion:NULL];
    }

}

@end
