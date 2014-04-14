//
//  EWWakeUpManager.h
//  EarlyWorm
//
//  Created by Lei on 3/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWWakeUpManager : NSObject
/**
 *Handles push notifications in varies mode
 @Discuss
 *1. Buzz
 *   active: sound + wakeupView
 *   suspend: not handle
 *
 *2. Media
 *   active:
 *       alarm time passed but not woke(struggle): play media
 *       before alarm: download
 *       woke: alert with no name
 *   suspend: background download
 *
 *3. Timer
 *   active: alert -> WakeupView
 *   suspend: background audio
 */
+ (void)handlePushNotification:(NSDictionary *)notification;

/**
 Handle alarm time up event
 1. Get next task
 2. Try to download all medias for task
 3. If there is no media, create a pesudo media
 4. After download
    a. cancel local notif
    b. fire silent alarm
    c. present wakeupVC and start play in 30s
 */
+ (void)handleAlarmTimerEvent;

/**
 Handle the information passed in when app is launched
 1. Local notification: UILocalNotification
 2. Remote Notification: NSDictionary
 a. buzz: TBD
 
 b. media: TBD
 */
+ (void)handleAppLaunchNotification:(id)notification;

/**
 Detect if root view is presenting EWWakeUpViewController
 */
+ (BOOL)isRootPresentingWakeUpView;
@end
