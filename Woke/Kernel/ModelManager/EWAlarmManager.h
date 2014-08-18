//
//  EWAlarmManager.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-8.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "EWStore.h"
//#define KEY_ID          @"alarm_ID"

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
//- (EWAlarmItem *)nextAlarm;
- (EWTaskItem *)firstTaskForAlarm:(EWAlarmItem *)alarm;

// change
//- (void)setAlarm:(EWAlarmItem *)alarm;
//- (void)setAlarmState:(BOOL)state atIndex:(NSUInteger)index;
- (NSArray *)scheduleAlarm;
- (NSArray *)scheduleNewAlarms;


//check
/**
 Check if alarm for current user is 0 or 7. Otherwise delete all alarm.
 */
//- (BOOL)checkAlarms;

//KVO


//UTIL
- (NSDictionary *)getSavedAlarmTime:(EWAlarmItem *)alarm;
- (void)setSavedAlarmTime:(EWAlarmItem *)alarm;

@end
