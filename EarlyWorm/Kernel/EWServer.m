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
#import "FTWCache.h"

@implementation EWServer

+ (EWServer *)sharedInstance{
    static EWServer *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWServer alloc] init];
    });
    return manager;
}


#pragma mark - Main Server method
+ (void)getPersonWakingUpForTime:(NSDate *)time location:(SMGeoPoint *)geoPoint callbackBlock:(SMFullResponseSuccessBlock)successBlock{
    NSLog(@"%s", __func__);
    
    NSString *userId = currentUser.username;
    NSInteger timeSince1970 = (NSInteger)[time timeIntervalSince1970];
    NSString *timeStr = [NSString stringWithFormat:@"%ld", (long)timeSince1970];
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
        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
    } onFailure:^(NSException *exception) {
        NSLog(@"Failed to send Buzz: %@", exception.description);
        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
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
        if (!target.aws_id) {
            NSString *str = [NSString stringWithFormat:@"User (%@) doesn't have a valid push key to receive buzz", target.name];
            EWAlert(str);
            continue;
        }
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
