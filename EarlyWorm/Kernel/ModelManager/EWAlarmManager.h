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

@class EWAlarmItem, EWPerson;

@interface EWAlarmManager : NSObject//EWStore

@property (nonatomic, retain) NSMutableArray *allAlarms;

// Singleton
+ (EWAlarmManager *)sharedInstance ;

// add
//- (EWAlarmItem *)newAlarm; //no direct call

// delete
- (void)deleteAllAlarms;

// Search
- (NSArray *)allAlarmsForUser:(EWPerson *)user;
//- (EWAlarmItem *)getAlarmAtWeekday:(NSInteger)dayIndex;
- (EWAlarmItem *)nextAlarm;

// change
//- (void)setAlarm:(EWAlarmItem *)alarm;
//- (void)setAlarmState:(BOOL)state atIndex:(NSUInteger)index;
- (NSArray *)scheduleAlarm;


//check
/**
 Check if alarm for current user is 0 or 7. Otherwise delete all alarm.
 */
- (BOOL)checkAlarms;
//KVO

@end
