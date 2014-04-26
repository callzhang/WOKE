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


#pragma mark - Main Server method
+ (NSArray *)getPersonAlarmAtTime:(NSDate *)time location:(SMGeoPoint *)geoPoint{
    NSLog(@"%s", __func__);
    
//    NSString *userId = currentUser.username;
//    NSInteger timeSince1970 = (NSInteger)[time timeIntervalSince1970];
//    NSString *timeStr = [NSString stringWithFormat:@"%ld", (long)timeSince1970];
//    NSString *lat = [geoPoint.latitude stringValue];
//    NSString *lon = [geoPoint.longitude stringValue];
//    NSString *geoStr = [NSString stringWithFormat:@"%@,%@", lat, lon];
//    
//    
//    SMCustomCodeRequest *request = [[SMCustomCodeRequest alloc]
//                                    initGetRequestWithMethod:@"get_person_waking_up"];
//    
//    [request addQueryStringParameterWhere:@"personId" equals:userId];
//    [request addQueryStringParameterWhere:@"time" equals:timeStr];
//    [request addQueryStringParameterWhere:@"location" equals:geoStr];
//    
//    [[[SMClient defaultClient] dataStore]
//     performCustomCodeRequest:request
//     onSuccess:successBlock
//     onFailure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id responseBody){
//         [NSException raise:@"Server custom code error" format:@"Reason: %@", error.description];
//         //retry...
//         
//     }];
    
    SMPredicate *locationPredicate =[SMPredicate predicateWhere:@"last_location" isWithin:10 kilometersOfGeoPoint:geoPoint];
    //NSPredicate *timePredicate = [NSPredicate predicateWithFormat:@"ANY tasks.time BETWEEN %@", @[time, [time timeByAddingMinutes:60]]];
    //NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[locationPredicate, timePredicate]];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWPerson"];
    request.predicate = locationPredicate;
    NSError *err;
    NSArray *personAround = [[EWDataStore currentContext] executeFetchRequestAndWait:request returnManagedObjectIDs:NO options:[EWDataStore optionFetchNetworkElseCache] error:&err];
    return personAround;
}


//Get person with task time and with location in async mode and a completion block
+ (void)getPersonAlarmAtTime:(NSDate *)time location:(SMGeoPoint *)geoPoint completion: (void (^)(NSArray *results))successBlock{
    __block NSArray *result;
    dispatch_async([EWDataStore sharedInstance].coredata_queue, ^{
        result = [EWServer getPersonAlarmAtTime:time location:geoPoint];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *mainResult = [NSMutableArray new];
            for (EWPerson *p in result) {
                EWPerson *p_ = [EWDataStore objectForCurrentContext:p];
                [mainResult addObject:p_];
            }
            
            if (mainResult.count == 0) {
                mainResult = [@[currentUser] mutableCopy];
            }
            
            //call back
            successBlock(mainResult);
        });
    });
}

#pragma mark - Push buzz

+ (void)buzz:(NSArray *)users{
    //delayed hide
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
    });
    
    
    
    for (EWPerson *person in users) {
        //get next task
        EWTaskItem *task = [[EWTaskStore sharedInstance] nextValidTaskForPerson:person];
        //create buzz
        EWMediaItem *buzz = [[EWMediaStore sharedInstance] createBuzzMedia];
        //add waker
        [task addWakerObject:person];
        //add sound
        NSString *sound = [EWDataStore user].preference[@"buzzSound"];
        buzz.buzzKey = sound ? sound : @"default";
        buzz.receiver = person;//send to media pool
        
        //push payload
        NSDictionary *pushMessage;
        
        
        if ([[NSDate date] isEarlierThan:task.time]) {
            
            //silent push
            pushMessage = @{@"aps": @{@"badge": @1,
                                      @"alert": @"Someone has sent you an buzz",
                                      @"content-available": @1,
                                      },
                            kPushMediaKey: buzz.ewmediaitem_id,
                            kPushTypeKey: kPushTypeBuzzKey};

            
        }else if (!task.completed || [[NSDate date] timeIntervalSinceDate:task.time] < kMaxWakeTime){
            //struggle state
            //send push notification, The payload can consist of the alert, badge, and sound keys.
            
            NSString *buzzType = buzz.buzzKey;
            NSDictionary *sounds = buzzSounds;
            NSString *buzzSound = sounds[buzzType];
            
            pushMessage = @{@"aps": @{@"alert": [NSString stringWithFormat:@"New buzz from %@", currentUser.name],
                                                    @"badge": @1,
                                                    @"sound": buzzSound,
                                                    @"content-available": @1,
                                                    },
                                          kPushMediaKey: buzz.ewmediaitem_id,
                                          kPushTypeKey: kPushTypeBuzzKey};

        }else{
            
            //tomorrow's task
            //silent push
            pushMessage = @{@"aps": @{@"badge": @1,
                                      @"alert": @"Someone has sent you an buzz",
                                      @"content-available": @1,
                                      },
                            kPushMediaKey: buzz.ewmediaitem_id,
                            kPushTypeKey: kPushTypeBuzzKey};
        }
        
        
        
        //send
        [EWServer AWSPush:pushMessage toUsers:@[person] onSuccess:^(SNSPublishResponse *response) {
            NSLog(@"Buzz sent via AWS: %@", response.messageId);
            [rootViewController.view showSuccessNotification:@"Sent"];
        } onFailure:^(NSException *exception) {
            NSLog(@"Failed to send Buzz: %@", exception.description);
            [rootViewController.view showFailureNotification:@"Failed"];
        }];
    }
    
    //save
    [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
        NSLog(@"*** Save buzz to task failed, retry...");
        [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:NULL];
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

#pragma mark - Send Voice tone
+ (void)pushMedia:(EWMediaItem *)m ForUser:(EWPerson *)person{
    
    EWMediaItem *media = [EWDataStore objectForCurrentContext:m];
    NSString *mediaId = media.ewmediaitem_id;
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:person];
    
    NSDictionary *pushMessage;
    
    //validate task
    if (task.completed || task.state == NO) {
        //something wrong, next task
        task = [[EWTaskStore sharedInstance] nextValidTaskForPerson:person];
    }
    
    //form push payload
    if ([[NSDate date] isEarlierThan:task.time]) {
        //early, silent message
        pushMessage = @{@"aps": @{@"badge": @1,
                                  @"alert": @"Someone has sent you an voice greeting",
                                  @"content-available": @1
                                  },
                        kPushTypeKey: kPushMediaKey,
                        kPushPersonKey: currentUser.username,
                        kPushMediaKey: mediaId};

    }else if([[NSDate date] timeIntervalSinceDate:task.time] < kMaxWakeTime){
        //struggle state
        pushMessage = @{@"aps": @{@"badge": @1,
                                  @"sound": @"media.caf",
                                  @"content-available": @1
                                  },
                        kPushTypeKey: kPushMediaKey,
                        kPushPersonKey: currentUser.username,
                        kPushMediaKey: mediaId};
        
    }else{
        //send silent push for next task
        
        pushMessage = @{@"aps": @{@"badge": @1,
                                  @"alert": @"Someone has sent you an voice greeting",
                                  @"content-available": @1
                                  },
                        kPushTypeKey: kPushMediaKey,
                        kPushPersonKey: currentUser.username,
                        kPushMediaKey: mediaId};
    }

    //push
    [EWServer AWSPush:pushMessage toUsers:@[person] onSuccess:^(SNSPublishResponse *response) {
        NSLog(@"Push media successfully sent to %@, message ID: %@", person.name, response.messageId);
        
        [rootViewController.view showSuccessNotification:@"Sent"];
        
        
    } onFailure:^(NSException *exception) {
        NSLog(@"Send push message about media %@ failed. Reason:%@", mediaId, exception.description);
        EWAlert(@"Server is unavailable, please try again.");
    }];
    
    [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
        NSLog(@"save voice media failed. Retry... Reason:%@", error.description);
        [[EWDataStore currentContext] saveAndWait:NULL];
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



//#pragma mark - Alert Delegate
///**
// action when user received push alert in active state
// 1. buzz: play the buzz (shouldn't be here)
// 2. media:
//    a. before woke: play voice
//    b. after woke or before timer: do nothing
// */
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
//    
//    NSString *type = alertView.userInfo[@"type"];
//    
//    if ([type isEqualToString:kPushTypeBuzzKey]) {
//        NSLog(@"Clicked OK on buzz");
//        
//    }else if ([type isEqualToString:kPushTypeMediaKey]) {
//        //got taskInAction
//        EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:alertView.userInfo[kPushTaskKey]];
//        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
//        controller.task = task;
//        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
//        EWAppDelegate * appDelegate = (EWAppDelegate *)[UIApplication sharedApplication].delegate;
//        [appDelegate.window.rootViewController presentViewController:navigationController animated:YES completion:NULL];
//    }
//
//}


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
            NSString *str = [NSString stringWithFormat:@"User (%@) doesn't have a valid push key to receive push", target.name];
            EWAlert(str);
            continue;
        }
        request.targetArn = target.aws_id;

        //NSLog(@"Push content: %@ \nTarget:%@", pushStr, currentUser.name);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @try {
                SNSPublishResponse *response = [snsClient publish:request];
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(response);
                });
            }
            @catch (NSException *exception) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(exception);
                });
            }
        });
    }

}

@end
