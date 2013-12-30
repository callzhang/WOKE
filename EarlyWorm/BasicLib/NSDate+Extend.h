//
//  NSDate+Extend.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-9.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Extend)
/**
 Returns HH:MM
 */
- (NSString *)date2String;
/**
 Returns Weekday, date and time
 */
- (NSString *)date2detailDateString;
/**
 Returns Weekday and date
 */
- (NSString *)date2dayString;
/**
 Compares two dates
 */
- (BOOL)isEarlierThan:(NSDate *)date;
- (NSInteger)weekdayNumber;
/**
 Returns future time in n weeks
 */
- (NSDate *)nextOccurTime:(NSInteger)n;

/**
 Weekday in long format
 */
- (NSString *)weekday;

/**
 Time in string format HHMM
 */
- (NSString *)timeInString;

/**
 Tells if time interval since the receiver is larger than serverUpdateInterval
 */
- (BOOL)isOutDated;

/**
 In setting alarm, the interval is determined by alarmInterval. This method returns the time from the receiver with that interval.
 */
- (NSDate *)nextAlarmIntervalTime;

/**
 HHMM in interger format
 */
- (NSInteger)HHMM;

@end
