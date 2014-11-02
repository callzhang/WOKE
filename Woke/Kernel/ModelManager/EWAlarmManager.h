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

// Singleton
+ (EWAlarmManager *)sharedInstance ;


// Search
- (NSArray *)alarmsForUser:(EWPerson *)user;
+ (NSArray *)myAlarms;
+ (EWAlarm *)myNextAlarm;

//Get next alarm time from person's cachedInfo
- (NSDate *)nextAlarmTimeForPerson:(EWPerson *)person;
//Get next alarm statement from person's cachedInfo
- (NSString *)nextStatementForPerson:(EWPerson *)person;

// schedule
- (NSArray *)scheduleAlarm;
- (void)updateCachedAlarmTime;
- (void)updateCachedStatement;

//UTIL
- (NSDate *)getSavedAlarmTimeOnWeekday:(NSInteger)wkd;
- (void)setSavedAlarmTimes;

@end
