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
#import "EWNotification.h"
#import "EWNotificationManager.h"
#import "EWWakeUpManager.h"

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



#pragma mark - Handle Push Notification
+ (void)handlePushNotification:(NSDictionary *)pushInfo{
    NSString *type = pushInfo[kPushTypeKey];
    BOOL isBuzz = [type isEqualToString:kPushTypeBuzzKey];
    BOOL isVoice = [type isEqualToString:kPushTypeMediaKey];
    BOOL isNotification = [type isEqualToString:kPushTypeNotificationKey];
    BOOL isAlarmTimer = [type isEqualToString:kPushTypeTimerKey];
    if (isNotification) {
        [EWNotificationManager handleNotification: pushInfo[kPushNofiticationIDKey]];
    }else if(isBuzz || isVoice){
        [EWWakeUpManager handlePushNotification:pushInfo];
    }else if (isAlarmTimer){
        [EWWakeUpManager handlePushNotification:pushInfo];
    }else{
        NSString *str = [NSString stringWithFormat:@"Unknown push: %@", pushInfo];
        EWAlert(str);
    }
}

#pragma mark - Handle Local Notification
+ (void)handleLocalNotification:(UILocalNotification *)notification{
    NSString *type = notification.userInfo[kLocalNotificationTypeKey];
    NSLog(@"Received local notification: %@", type);
    
    if ([type isEqualToString:kLocalNotificationTypeAlarmTimer]) {
        [EWWakeUpManager handleAlarmTimerEvent:notification.userInfo];
    }else if([type isEqualToString:kLocalNotificationTypeReactivate]){
        NSLog(@"==================> Reactivated Woke <======================");
        EWAlert(@"You brought me back to life!");
    }else if ([type isEqualToString:kLocalNotificationTypeSleepTimer]){
        EWAlert(@"Entering sleep mode...");
    }
    else{
        NSLog(@"Unexpected Local Notification Type. Detail: %@", notification);
    }

}

#pragma mark - Push buzz

+ (void)buzz:(NSArray *)users{
    //delayed hide
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
    });
    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    
    for (EWPerson *person in users) {
        //get next wake up time
        NSDate *time = [[EWTaskStore sharedInstance] nextWakeUpTimeForPerson:person];
        //create buzz
        EWMediaItem *buzz = [[EWMediaStore sharedInstance] createBuzzMedia];
        //add receiver: single direction
        [buzz addReceiversObject:person];
        //add sound
        NSString *sound = me.preference[@"buzzSound"]?:@"default";
        buzz.buzzKey = sound;
        
        [EWDataStore saveWithCompletion:^{
            NSParameterAssert(buzz.objectId);
            
            //push payload
            NSMutableDictionary *pushMessage = [@{@"content-available": @1,
                                          @"badge": @"Increment",
                                          kPushMediaKey: buzz.objectId,
                                          kPushTypeKey: kPushTypeBuzzKey} mutableCopy];
            
            
            if ([[NSDate date] isEarlierThan:time]) {
                //before wake up
                //silent push
                
                
            }else if (time.timeElapsed < kMaxWakeTime){
                //struggle state
                //send push notification, The payload can consist of the alert, badge, and sound keys.
                
                NSString *buzzType = buzz.buzzKey;
                NSDictionary *sounds = buzzSounds;
                NSString *buzzSound = sounds[buzzType];
                
                pushMessage[@"alert"] = @"Someone has sent you an buzz";
                pushMessage[@"sound"] = buzzSound;
                
            }else{
                
                //tomorrow's task
                //silent push
            }
            
            //send
            [EWServer parsePush:pushMessage toUsers:@[person] completion:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [rootViewController.view showSuccessNotification:@"Sent"];
                }else{
                    NSLog(@"Send push message about media %@ failed. Reason:%@", buzz.objectId, error.description);
                    [rootViewController.view showFailureNotification:@"Failed"];
                }
            }];
        }];
        
    }
    
}

#pragma mark - Send Voice tone
+ (void)pushMedia:(EWMediaItem *)media ForUser:(EWPerson *)person{
    
    NSString *mediaId = media.objectId;
    NSDate *time = [[EWTaskStore sharedInstance] nextWakeUpTimeForPerson:person];
    
    NSMutableDictionary *pushMessage = [@{@"badge": @"Increment",
                                 @"alert": @"Someone has sent you an voice greeting",
                                 @"content-available": @1,
                                 kPushTypeKey: kPushTypeMediaKey,
                                 kPushPersonKey: me.objectId,
                                 kPushMediaKey: mediaId} mutableCopy];
    
    //form push payload
    if ([[NSDate date] isEarlierThan:time]) {
        //early, silent message

    }else if(time.timeElapsed < kMaxWakeTime){
        //struggle state
        pushMessage[@"sound"] = @"media.caf";
        pushMessage[@"alert"] = @"Someone has sent you an voice greeting";
        
    }else{
        //send silent push for next task
        
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
    
}



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
    
    NSArray *userIDs = [users valueForKey:kUsername];
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:kUsername containedIn:userIDs];
    PFPush *push = [PFPush new];
    [push setQuery:pushQuery];
    [push setData:pushPayload];
    block = block?:NULL;
    //[push sendPushInBackgroundWithBlock:block];
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        block(succeeded, error);
    }];
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
