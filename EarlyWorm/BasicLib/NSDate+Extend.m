//
//  NSDate+Extend.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-9.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "NSDate+Extend.h"
#import "EWDefines.h"

@implementation NSDate (Extend)

- (NSString *)date2String {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"HH:mm"];

    NSString *string = [formatter stringFromDate:self];
    return string;
}

- (NSString *)date2detailDateString{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm";
    return [parseFormatter stringFromDate:self];
}

- (NSString *)date2dayString{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"EEE, dd MMM yyyy";
    return [parseFormatter stringFromDate:self];

}

- (BOOL)isEarlierThan:(NSDate *)date{
    NSTimeInterval t1 = [self timeIntervalSinceReferenceDate];
    NSTimeInterval t2 = [date timeIntervalSinceReferenceDate];
    if (t1<t2) {
        return TRUE;
    }else{
        return FALSE;
    }
}

- (NSInteger)weekdayNumber{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSInteger weekdayOfDate = [cal ordinalityOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:self];
    return weekdayOfDate - 1; //0:sunday ... 6:saturday
}

- (NSDate *)nextOccurTime:(NSInteger)n{
    NSDate *time = self;
    //bring to now
    while ([time isEarlierThan:[NSDate date]]) {
        time = [time nextWeekTime];
    }
    //future
    for (unsigned i=1; i<n; i++) {
        time = [time nextWeekTime];
    }
    return time;
}

- (NSDate *)nextWeekTime{
    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    deltaComps.day = 7;
    NSDate *time = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:self options:0];
    return time;
}

- (NSString *)weekday{
    NSArray *weekdayArray = weekdays;
    return weekdayArray[self.weekdayNumber];
}

- (NSString *)timeInString{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSWeekdayCalendarUnit) fromDate:self];
    NSString *HHMM = [NSString stringWithFormat:@"%d:%d", comp.hour, comp.minute];
    return HHMM;
}

- (BOOL)isOutDated{
    BOOL outdated = ([[NSDate date] timeIntervalSinceReferenceDate]-[self timeIntervalSinceReferenceDate]) > serverUpdateInterval;
    return outdated;
}

- (NSDate *)nextAlarmIntervalTime{
    NSDateComponents* delta = [[NSDateComponents alloc] init];
    delta.second = alarmInterval;
    return [[NSCalendar currentCalendar] dateByAddingComponents:delta toDate:self options:0];
}

- (NSInteger)HHMM{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSWeekdayCalendarUnit) fromDate:self];
    NSInteger hhmm = comp.hour*100 + comp.minute;
    return hhmm;
}

@end
