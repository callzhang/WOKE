//
//  EWWakeUpManager.h
//  EarlyWorm
//
//  Created by Lei on 3/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EWTaskItem;

@interface EWWakeUpManager : NSObject

+ (EWWakeUpManager *)sharedInstance;

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
+ (void)handleAlarmTimerEvent:(NSDictionary *)pushInfo;

/**
 Detect if root view is presenting EWWakeUpViewController
 */
+ (BOOL)isRootPresentingWakeUpView;

/**
 Present EWWakeUpViewController on rootView.
 Also it will register the presented wake up view controller as a retained value to prevent premature deallocation in ARC.
 @discussion If rootView is displaying anything else, it will dismiss other view first.
 */
+ (void)presentWakeUpView;
+ (void)presentWakeUpViewWithTask:(EWTaskItem *)task;

/**
 Release the reference to wakeupVC
 Post notification: kWokeNotification
 */
+ (void)woke;

/**
 Timely alarm timer check task
 Will schedule an alarm if the time left is within the service update interval
 Call handle alarm timer method when time is up
 */
+ (void) alarmTimerCheck;
@end
