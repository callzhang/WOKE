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
    
    [formatter setDateFormat:@"HH:mm a"];

    NSString *string = [formatter stringFromDate:self];
    return string;
}

- (NSString *)date2timeShort{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"HH:mm"];
    
    NSString *string = [formatter stringFromDate:self];
    return string;
}

- (NSString *)date2am{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"a"];
    
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

- (NSString *)date2numberDateString{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"YYYYMMddHHmm";
    return [parseFormatter stringFromDate:self];
}

- (NSString *)date2MMDD{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"M/DD";
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
    NSString *HHMM = [NSString stringWithFormat:@"%ld:%ld", (long)comp.hour, (long)comp.minute];
    return HHMM;
}

- (BOOL)isOutDated{
    if (self == nil) return YES;
    NSInteger timeElapsed = [[NSDate date] timeIntervalSinceReferenceDate]-[self timeIntervalSinceReferenceDate];
    BOOL outdated = timeElapsed > serverUpdateInterval;
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

- (NSDate *)timeByAddingMinutes:(NSInteger)minutes{
    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    deltaComps.minute = minutes;
    NSDate *time = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:self options:0];
    return time;
}

- (NSDate *)timeByAddingSeconds:(NSInteger)seconds{
    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    deltaComps.second = seconds;
    NSDate *time = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:self options:0];
    return time;
}

- (NSDate *)timeByMinutesFrom5am:(NSInteger)minutes{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* deltaComps = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:self];
    deltaComps.minute = minutes % 60;
    deltaComps.hour = 5 + (NSInteger)minutes/60;
    
    NSDate *time = [cal dateFromComponents:deltaComps];
    return time;
}

- (NSInteger)minutesFrom5am{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* deltaComps = [cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self];
    NSInteger min = deltaComps.hour * 60 + deltaComps.minute;
    if (min % 10 != 0) {
        NSLog(@"Something wrong with the time input: %@", self.date2detailDateString);
    }
    return min;
}

@end
