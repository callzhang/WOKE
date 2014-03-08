//
//  EWTaskItem.m
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWTaskItem.h"
#import "EWAlarmItem.h"
#import "EWMediaItem.h"
#import "EWPerson.h"
#import "StackMob.h"

@implementation EWTaskItem

@dynamic added;
@dynamic aws_sns_topic_id;
@synthesize buzzers;
@dynamic buzzers_string;
@dynamic completed;
@dynamic createddate;
@dynamic ewtaskitem_id;
@dynamic lastmoddate;
@dynamic length;
@dynamic state;
@dynamic statement;
@dynamic success;
@dynamic time;
@dynamic alarm;
@dynamic medias;
@dynamic messages;
@dynamic owner;
@dynamic waker;
@dynamic pastOwner;

- (EWTaskItem *)init{
    self = [super init];
    if (self) {
        [self setValue:[self assignObjectId] forKey:[self primaryKeyField]];
    }
    return self;
}

#pragma mark - Preference
- (NSDictionary *)buzzers{
    if (self.buzzers_string) {
        NSData *buzzersData = [self.buzzers_string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:buzzersData options:0 error:&err];
        return json;
    }
    NSLog(@"No buzzer yet");
    return @{};
}

- (void)setBuzzers:(NSDictionary *)b{
    NSError *err;
    NSData *buzzerData = [NSJSONSerialization dataWithJSONObject:b options:NSJSONWritingPrettyPrinted error:&err];
    NSString *buzzerStr = [[NSString alloc] initWithData:buzzerData encoding:NSUTF8StringEncoding];
    self.buzzers_string = buzzerStr;
}

- (void)addBuzzer:(EWPerson *)person atTime:(NSDate *)time{
    NSNumber *t = [NSNumber numberWithInteger:[time timeIntervalSince1970]];
    NSMutableDictionary *dic = [self.buzzers mutableCopy];
    [dic setObject:t forKey:person.username];
    self.buzzers = dic;
}

@end
