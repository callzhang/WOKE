//
//  EWTaskItem.m
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

//#import "EWTaskItem.h"
#import "EWAlarm.h"
#import "EWMedia.h"
#import "EWPerson.h"


@implementation EWTaskItem
@dynamic state;

#pragma mark - Preference
//- (NSDictionary *)buzzers{
//    if (self.buzzers_string) {
//        NSData *buzzersData = [self.buzzers_string dataUsingEncoding:NSUTF8StringEncoding];
//        NSError *err;
//        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:buzzersData options:0 error:&err];
//        return json;
//    }
//    return @{};
//}
//
//- (void)setBuzzers:(NSDictionary *)b{
//    NSError *err;
//    NSData *buzzerData = [NSJSONSerialization dataWithJSONObject:b options:NSJSONWritingPrettyPrinted error:&err];
//    NSString *buzzerStr = [[NSString alloc] initWithData:buzzerData encoding:NSUTF8StringEncoding];
//    self.buzzers_string = buzzerStr;
//}
//
//- (void)addBuzzer:(EWPerson *)person atTime:(NSDate *)time{
//    NSNumber *t = [NSNumber numberWithInteger:[time timeIntervalSince1970]];
//    NSMutableDictionary *dic = [self.buzzers mutableCopy];
//    [dic setObject:t forKey:person.username];
//    self.buzzers = dic;
//}

@end
