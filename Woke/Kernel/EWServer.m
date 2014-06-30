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
+ (NSArray *)getPersonAlarmAtTime:(NSDate *)time location:(PFGeoPoint *)geoPoint{
    NSLog(@"%s", __func__);
    
    PFQuery *geoQuery = [PFQuery queryWithClassName:@"EWPerson"];
    [geoQuery whereKey:@"lastLocation" nearGeoPoint:geoPoint withinKilometers:100];
    NSArray *parsePeople = [geoQuery findObjects];
    NSMutableArray *people = [NSMutableArray new];
    
    for (PFObject *object in parsePeople) {
        NSManagedObject *person = [object managedObject];
        [people addObject:person];
    }
    
    return people;
}


//Get person with task time and with location in async mode and a completion block
+ (void)getPersonAlarmAtTime:(NSDate *)time location:(PFGeoPoint *)geoPoint completion: (void (^)(NSArray *results))successBlock{
    __block NSArray *result;
    dispatch_async([EWDataStore sharedInstance].coredata_queue, ^{
        //get people from server
        //result = [EWServer getPersonAlarmAtTime:time location:geoPoint];
        result = [[EWPersonStore sharedInstance] everyone];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *mainResult = [NSMutableArray new];
            for (EWPerson *p in result) {
                EWPerson *p_ = [EWDataStore objectForCurrentContext:p];
                [mainResult addObject:p_];
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
        [buzz addReceiversObject:person];
        //add sound
        NSString *sound = me.preference[@"buzzSound"]?:@"default";
        buzz.buzzKey = sound;
        
        //push payload
        NSDictionary *pushMessage;
        
        
        if ([[NSDate date] isEarlierThan:task.time]) {
            //before wake up
            //silent push
            pushMessage = @{@"alert": @"Someone has sent you an buzz",
                            @"content-available": @1,
                            @"badge": @"Increment",
                            kPushMediaKey: buzz.objectId,
                            kPushTypeKey: kPushTypeBuzzKey};

            
        }else if (!task.completed || [[NSDate date] timeIntervalSinceDate:task.time] < kMaxWakeTime){
            //struggle state
            //send push notification, The payload can consist of the alert, badge, and sound keys.
            
            NSString *buzzType = buzz.buzzKey;
            NSDictionary *sounds = buzzSounds;
            NSString *buzzSound = sounds[buzzType];
            
            pushMessage = @{@"alert": @"Someone has sent you an buzz",
                            @"content-available": @1,
                            @"badge": @"Increment",
                            @"sound": buzzSound,
                            kPushMediaKey: buzz.objectId,
                            kPushTypeKey: kPushTypeBuzzKey};

        }else{
            
            //tomorrow's task
            //silent push
            pushMessage = @{@"alert": @"Someone has sent you an buzz",
                            @"content-available": @1,
                            @"badge": @"Increment",
                            kPushMediaKey: buzz.objectId,
                            kPushTypeKey: kPushTypeBuzzKey};
        }
        
        //send
        [EWServer parsePush:pushMessage toUsers:@[person] completion:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"Buzz sent to %@", person.name);
            }else{
                NSLog(@"Failed to send push: %@", error.description);
            }
        }];
        
        
        //send
//        [EWServer AWSPush:pushMessage toUsers:@[person] onSuccess:^(SNSPublishResponse *response) {
//            NSLog(@"Buzz sent via AWS: %@", response.messageId);
//            [rootViewController.view showSuccessNotification:@"Sent"];
//        } onFailure:^(NSException *exception) {
//            NSLog(@"Failed to send Buzz: %@", exception.description);
//            [rootViewController.view showFailureNotification:@"Failed"];
//        }];
    }
    
    //save media and update to server
    [EWDataStore save];
    
}

#pragma mark - Send Voice tone
+ (void)pushMedia:(EWMediaItem *)media ForUser:(EWPerson *)person{
    
    NSString *mediaId = media.objectId;
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextValidTaskForPerson:person];
    
    NSDictionary *pushMessage;
    
    //form push payload
    if ([[NSDate date] isEarlierThan:task.time]) {
        //early, silent message
        pushMessage = @{@"badge": @"Increment",
                        @"alert": @"Someone has sent you an voice greeting",
                        @"content-available": @1,
                        kPushTypeKey: kPushTypeMediaKey,
                        kPushPersonKey: me.username,
                        kPushMediaKey: mediaId};

    }else if([[NSDate date] timeIntervalSinceDate:task.time] < kMaxWakeTime){
        //struggle state
        pushMessage = @{@"badge": @"Increment",
                        @"sound": @"media.caf",
                        @"alert": @"Someone has sent you an voice greeting",
                        @"content-available": @1,
                        kPushTypeKey: kPushTypeMediaKey,
                        kPushPersonKey: me.username,
                        kPushMediaKey: mediaId};
        
    }else{
        //send silent push for next task
        
        pushMessage = @{@"badge": @"Increment",
                        @"alert": @"Someone has sent you an voice greeting",
                        @"content-available": @1,
                        kPushTypeKey: kPushTypeMediaKey,
                        kPushPersonKey: me.username,
                        kPushMediaKey: mediaId};
    }
    
    //push
    [EWServer parsePush:pushMessage toUsers:@[person] completion:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [rootViewController.view showSuccessNotification:@"Sent"];
        }else{
            NSLog(@"Send push message about media %@ failed. Reason:%@", mediaId, error.description);
            [rootViewController.view showFailureNotification:@"Failed"];
        }
    }];
    
    //save
    [EWDataStore save];
    

    //push
//    [EWServer AWSPush:pushMessage toUsers:@[person] onSuccess:^(SNSPublishResponse *response) {
//        NSLog(@"Push media successfully sent to %@, message ID: %@", person.name, response.messageId);
//        
//        [rootViewController.view showSuccessNotification:@"Sent"];
//        
//        
//    } onFailure:^(NSException *exception) {
//        NSLog(@"Send push message about media %@ failed. Reason:%@", mediaId, exception.description);
//        EWAlert(@"Server is unavailable, please try again.");
//    }];
//    
//    [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
//        NSLog(@"save voice media failed. Retry... Reason:%@", error.description);
//        [[EWDataStore currentContext] saveAndWait:NULL];
//    }];
//    
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
//
//+ (void)AWSPush:(NSDictionary *)pushDic toUsers:(NSArray *)users onSuccess:(void (^)(SNSPublishResponse *))successBlock onFailure:(void (^)(NSException *))failureBlock{
//    NSString *pushStr = [EWUIUtil toString:pushDic];
//    pushStr = [pushStr stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
//    pushStr = [NSString stringWithFormat:@"{\"APNS_SANDBOX\":\"%@\", \"default\":\"You got a new push from AWS\"}", pushStr];
//    SNSPublishRequest *request = [[SNSPublishRequest alloc] init];
//    request.message = pushStr;
//    request.messageStructure = @"json";
//    
//    for (EWPerson *target in users) {
//        if (!target.aws_id) {
//            NSString *str = [NSString stringWithFormat:@"User (%@) doesn't have a valid push key to receive push", target.name];
//            EWAlert(str);
//            continue;
//        }
//        request.targetArn = target.aws_id;
//
//        //NSLog(@"Push content: %@ \nTarget:%@", pushStr, me.name);
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            @try {
//                SNSPublishResponse *response = [snsClient publish:request];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    successBlock(response);
//                });
//            }
//            @catch (NSException *exception) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    failureBlock(exception);
//                });
//            }
//        });
//    }
//
//}


+ (void)broadcastMessage:msg onSuccess:(void (^)(void))block onFailure:(void (^)(void))failureBlock{
    
    NSDictionary *payload = @{@"alert": msg};
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKeyExists:@"username"];
    PFPush *push = [PFPush new];
    [push setQuery:pushQuery];
    [push setData:payload];
    block = block?:NULL;
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded && block) {
            block();
        }else if (failureBlock){
            NSLog(@"Failed to broadcast push message: %@", error.description);
            failureBlock();
        }
    }];
}


#pragma mark - Parse Push
+ (void)parsePush:(NSDictionary *)pushPayload toUsers:(NSArray *)users completion:(PFBooleanResultBlock)block{
    
    NSArray *parseIDs = [users valueForKey:kParseObjectID];
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:kParseObjectID containedIn:parseIDs];
    PFPush *push = [PFPush new];
    [push setQuery:pushQuery];
    [push setData:pushPayload];
    block = block?:NULL;
    [push sendPushInBackgroundWithBlock:block];
}


#pragma mark - PUSH

+ (void)registerAPNS{
    //push
#if TARGET_IPHONE_SIMULATOR
    //Code specific to simulator
#else
    //pushClient = [[SMPushClient alloc] initWithAPIVersion:@"0" publicKey:kStackMobKeyDevelopment privateKey:kStackMobKeyDevelopmentPrivate];
    //register everytime in case for events like phone replacement
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeNewsstandContentAvailability | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
#endif
}

+ (void)registerPushNotificationWithToken:(NSData *)deviceToken{
    
    //Parse: Store the deviceToken in the current Installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
    
    
    
}

@end
