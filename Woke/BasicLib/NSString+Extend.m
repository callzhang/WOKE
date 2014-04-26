//
//  NSString+Extend.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-9.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "NSString+Extend.h"

@implementation NSString (Extend)

- (NSDate *)string2Date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"HH:mm"];
    
    NSDate *date = [formatter dateFromString:self];
    return date;
}

- (NSDate *)coredataString2Date{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
    NSDate *date = [parseFormatter dateFromString:self];
    return date;
}

- (NSMutableArray *)repeatArray{
    
    
    if ([self isEqual:@"Everyday"]) {
        return [NSMutableArray arrayWithObjects:@"YES",@"YES",@"YES",@"YES",@"YES",@"YES",@"YES", nil];
    } else if([self isEqual:@"Weekday"]) {
        return [NSMutableArray arrayWithObjects:@"YES",@"YES",@"YES",@"YES",@"YES", @"NO", @"NO", nil];
    }
    
    NSArray *weekdaysString = weekdays;
    NSMutableArray *repeatDays = [NSMutableArray arrayWithObjects:@"NO", @"NO", @"NO", @"NO", @"NO", @"NO", @"NO", nil];
    
    NSArray *days = [self componentsSeparatedByString:@", "];
    
    for (NSInteger i=0; i<days.count; i++) {
        NSString *dayToFind = [days objectAtIndex:i];
        NSInteger j = [weekdaysString indexOfObject:dayToFind];
        if (j==NSNotFound) {
            return repeatDays;
        }
        [repeatDays setObject:@"YES" atIndexedSubscript:j];
    }
    return repeatDays;
}

- (NSString *)initial{
    NSArray *nameArray = [self componentsSeparatedByString:@" "];
    NSString *first;
    NSString *last;
    @try {
        first = [[(NSString *)nameArray[0] substringToIndex:1] uppercaseString];
        last = [[(NSString *)nameArray[1] substringToIndex:1] uppercaseString];
    }
    @catch (NSException *exception) {
        NSString *alphabet  = @"ABCDEFGHIJKLMNOPQRSTUVWXZY";
        NSInteger i = arc4random_uniform((unsigned)alphabet.length);
        last = [NSString stringWithFormat:@"%C", [alphabet characterAtIndex:i]];
    }
    return [NSString stringWithFormat:@"%@ %@", first, last];
}


@end


@implementation NSString (Color)

- (UIColor *)string2Color {
    NSString *hexString = self;
    if ([hexString characterAtIndex:0] == '#') {
        hexString = [self substringFromIndex:1];
    }
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    
    unsigned int baseColor;
    [scanner setCharactersToBeSkipped:[NSCharacterSet symbolCharacterSet]];
    [scanner scanHexInt:&baseColor];
    CGFloat red = ((baseColor & 0xFF0000) >> 16)/255.0f;
    CGFloat green = ((baseColor & 0xFF00) >> 8)/255.0f;
    CGFloat blue = (baseColor & 0xFF)/255.0f;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
}

@end
