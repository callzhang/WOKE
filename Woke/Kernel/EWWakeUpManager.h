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
 *Individual method to handle alarm time up event
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
