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

+ (void)buzz:(EWPerson *)user{
    //TODO: buzz sound selection
    //TODO: buzz message selection
    //TODO: bedge number
    
    
    //send push notification, The payload can consist of the alert, badge, and sound keys.
    NSDictionary *pushMessage = @{@"alert": [NSString stringWithFormat:@"New buzz from %@", currentUser.name],
                                  @"badge": @1,
                                  kPushPersonKey: currentUser.username,
                                  @"type": kPushTypeBuzzKey,
                                  @"sound": @"buzz.caf"};
    
    [pushClient sendMessage:pushMessage toUsers:@[user.username] onSuccess:^{
        NSLog(@"Buzz successfully sent to %@", user.name);
    } onFailure:^(NSError *error) {
        NSString *str = [NSString stringWithFormat:@"Failed to send buzz. Reason:%@", error.localizedDescription];
        EWAlert(str);
    }];

}

+ (void)pushMedia:(NSString *)mediaId ForUsers:(NSArray *)users ForTask:(NSString *)taskId{
    NSDictionary *pushMessage = @{@"alert": [NSString stringWithFormat:@"New media from %@", currentUser.name],
                                  @"badge": @1,
                                  @"sound": @"buzz.caf",
                                  @"type": kPushMediaKey,
                                  kPushPersonKey: currentUser.username,
                                  kPushMediaKey: mediaId,
                                  kPushTaskKey: taskId};
    [pushClient sendMessage:pushMessage toUsers:users onSuccess:^{
        NSLog(@"Push media sent successful");
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Media" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alert.userInfo = @{@"type": kPushTypeMediaKey, kPushTaskKey: taskID, kPushMediaKey: mediaID};
        [alert show];
    }else if([type isEqualToString:kPushTypeTimerKey]){
        //active: alert
        EWAlert(@"Time to wake up!");
        //suspend: play media
    }else{
        NSString *str = [NSString stringWithFormat:@"Unknown push received: %@", notification];
        EWAlert(str);
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
