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
@property (nonatomic) NSManagedObjectContext *context;

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
- (BOOL)checkAlarms;
//KVO

@end
