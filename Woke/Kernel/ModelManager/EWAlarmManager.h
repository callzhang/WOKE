//
//  EWAlarmManager.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-8.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWSession.h"
#define kCachedAlarmTimes                @"alarm_schedule"
#define kCachedStatements                @"statements"


@class EWAlarm, EWPerson, EWTaskItem;

@interface EWAlarmManager : NSObject
@property BOOL isSchedulingAlarms;

// Singleton
+ (EWAlarmManager *)sharedInstance;


//TODO: discuss
//Get next alarm time from person's cachedInfo
- (NSDate *)nextAlarmTimeForPerson:(EWPerson *)person;
//TODO: discuss
//Get next alarm statement from person's cachedInfo
- (NSString *)nextStatementForPerson:(EWPerson *)person;

// schedule
- (NSArray *)scheduleAlarm;

//update cached info
- (void)updateCachedAlarmTimes;
- (void)updateCachedStatements;

//UTIL
- (NSDate *)getSavedAlarmTimeOnWeekday:(NSInteger)wkd;

//local notification
- (void)checkScheduledLocalNotifications;
- (void)scheduleSleepNotifications;
- (void)cancelSleepNotifications;

/*
 Use REST to create a notification on server
 when person is in his sleep mode
 */
#define kScheduledAlarmTimers       @"scheduled_alarm_timers"
- (void)scheduleNotificationOnServerForAlarm:(EWAlarm *)alarm;
@end
