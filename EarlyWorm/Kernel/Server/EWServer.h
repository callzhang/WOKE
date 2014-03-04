//
//  EWServer.h
//  EarlyWorm
//
//  Created by Lee on 2/21/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"

@interface EWServer : NSObject <UIAlertViewDelegate>
+ (void)getPersonWakingUpForTime:(NSDate *)timeSince1970 location:(SMGeoPoint *)geoPoint callbackBlock:(SMFullResponseSuccessBlock)successBlock;

/**
 Send buzz
 */
+ (void)buzz:(NSArray *)users;

/**
 Send push notification for media
 @params mediaId: mediaId
 @params users: array of EWPerson
 @params taskId: taskId
 */
+ (void)pushMedia:(NSString *)mediaId ForUsers:(NSArray *)users ForTask:(NSString *)taskId;

/**
 Handles push notifications in varies mode
 @Discuss
 1. Buzz
    active: sound + wakeupView
    suspend: not handle
 
 2. Media
    active:
        alarm time passed but not woke(struggle): play media
        before alarm: download
        woke: alert with no name
    suspend: background download
 
 3. Timer
    active: alert -> WakeupView
    suspend: background audio
 */
+ (void)handlePushNotification:(NSDictionary *)notification;

/**
 Handle the information passed in when app is launched
 1. Local notification: UILocalNotification
 2. Remote Notification: NSDictionary
    a. buzz: TBD
 
    b. media: TBD
 */
+ (void)handleAppLaunchNotification:(id)notification;
+ (BOOL)isRootPresentingWakeUpView;
@end
