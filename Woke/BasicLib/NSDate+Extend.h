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
 Returns HH:MM AM
 */
- (NSString *)date2String;

/**
 Returns HH:MM
 */
- (NSString *)date2timeShort;

/**
 Return AM or PM
 */
- (NSString *)date2am;

/**
 Returns Weekday, date and time
 */
- (NSString *)date2detailDateString;
/**
 Returns Weekday and date
 */
- (NSString *)date2dayString;

/**
 Returns string YYMMDD
 */
- (NSString *)date2YYMMDDString;
/**
 return YYYYMMddHHmm
 */
- (NSString *)date2numberDateString;
/**
 return YYYYMMddHHmmssSSSS
 */
- (NSString *)date2numberLongString;

//
-(NSString *)dateToParseDateString;
/**
 Compares two dates
 */
- (BOOL)isEarlierThan:(NSDate *)date;
- (NSInteger)weekdayNumber;
/**
 Returns a future time in n weeks from now that has the same weekday and time of the input date.
 */
- (NSDate *)nextOccurTime:(NSInteger)n;

/**
 Weekday in long format
 */
- (NSString *)weekday;

/**
 Weekday in short format
 */
- (NSString *)weekdayShort;

/**
 Time in string format HHMM
 */
- (NSString *)timeInString;

/**
 Tells if time interval since the receiver is less than serverUpdateInterval
 */
- (BOOL)isUpToDated;

/**
 In setting alarm, the interval is determined by alarmInterval. This method returns the time from the receiver with that interval.
 */
- (NSDate *)nextAlarmIntervalTime;

/**
 HHMM in interger format
 */
- (NSInteger)HHMM;

/**
 
 */
- (NSString *)time2HMMSS;

/**
 add minutes to the receiver
 */
- (NSDate *)timeByAddingMinutes:(NSInteger)minutes;
- (NSDate *)timeByAddingSeconds:(NSInteger)seconds;

/**
 get time from minutes from 5AM
 */
- (NSDate *)timeByMinutesFrom5am:(NSInteger)minutes;

/**
 Get minutes distance from 5AM to now
 */
- (NSInteger)minutesFrom5am;
/**
 Return MM/DD format
 */
- (NSString *)date2MMDD;

- (NSDateComponents *)dateComponents;

/**
 Time left to next alarm
 */
- (NSString *)timeLeft;


/**
 *
 *  Jan.27
 *
 */
-(NSString *)time2MonthDotDate;

/**
 Time elapsed since last update
 */
- (double)timeElapsed;

- (NSDate *)beginingOfDay;
- (NSDate *)endOfDay;
@end
