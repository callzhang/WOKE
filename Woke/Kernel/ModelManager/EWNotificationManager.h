//
//  EWNotificationManager.h
//  Woke
//
//  Created by Lei on 4/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNotificationCompleted      @"notification_completed"


@class EWNotification;

@interface EWNotificationManager : NSObject <UIAlertViewDelegate>

+ (EWNotificationManager *)sharedInstance;

+ (NSArray *)myNotifications;//unread notification
+ (NSArray *)allNotifications;//all notifications
/**
 When new notification received, handle it
 1. Decide weather to alert user
 2. Check if is in the notification queue
 */
+ (void)handleNotification:(NSString *)notificationID;

/**
 check if store notification is the same state as server
 */
+ (EWNotification *)getNotificationByID:(NSString *)notificationID;

/**
 Tells the manager that user clicked the notice and ask for appropreate action
 */
+ (void)clickedNotification:(EWNotification *)notification;

//Create
+ (EWNotification *)newNotification;

//delete
+ (void)deleteNotification:(EWNotification *)notice;

//Send
+ (void)sendFriendRequestNotificationToUser:(EWPerson *)person;
+ (void)sendFriendAcceptNotificationToUser:(EWPerson *)person;
@end
