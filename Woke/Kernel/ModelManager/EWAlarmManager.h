//
//  EWAlarmManager.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-8.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kCachedAlarmTimes                @"alarm_schedule"
#define kCachedStatements                @"statements"


@class EWAlarmItem, EWPerson, EWTaskItem;

@interface EWAlarmManager : NSObject
@property BOOL alarmNeedToSetup;
@property BOOL isSchedulingAlarm;

// Singleton
+ (EWAlarmManager *)sharedInstance ;

// add
//- (EWAlarmItem *)newAlarm; //no direct call

// delete
- (void)deleteAllAlarms;

// Search
- (NSArray *)alarmsForUser:(EWPerson *)user;
+ (NSArray *)myAlarms;
- (NSDate *)nextAlarmTimeForPerson:(EWPerson *)person;
- (NSString *)nextStatementForPerson:(EWPerson *)person;

// schedule
- (NSArray *)scheduleAlarm;
- (NSArray *)scheduleNewAlarms;
- (void)updateCachedAlarmTime;
- (void)updateCachedStatement;

//check
+ (BOOL)validateAlarm:(EWAlarmItem *)alarm;

//KVO


//UTIL
- (NSDate *)getSavedAlarmTimeOnWeekday:(NSInteger)wkd;
- (void)setSavedAlarmTimes;

@end
