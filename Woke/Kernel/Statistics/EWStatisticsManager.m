//
//  EWStatisticsManager.m
//  EarlyWorm
//
//  Created by Lei on 1/8/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWStatisticsManager.h"
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWUIUtil.h"

#define kMaxWakabilityTime      600

@implementation EWStatisticsManager
@synthesize person, tasks;

- (void)setPerson:(EWPerson *)p{
    person = p;
    tasks = p.pastTasks.allObjects;
}

- (NSNumber *)aveWakingLength{
    if (tasks.count) {
        NSInteger totalTime = 0;
        NSUInteger wakes = 0;
        
        for (EWTaskItem *t in self.tasks) {
            if (!t.state) continue;
            
            wakes++;
            NSInteger length;
            if (t.completed) {
                length = MAX([t.completed timeIntervalSinceDate:t.time], kMaxWakeTime);
            }else{
                length = kMaxWakeTime;
            }
            
            totalTime += length;
        }
        NSInteger aveTime = totalTime / wakes;
        return [NSNumber numberWithInteger:aveTime];
    }
    return 0;
}

- (NSString *)aveWakingLengthString{
    NSInteger aveT = self.aveWakingLength.integerValue;
    if (aveT == 0) {
        return @"-";
    }
    NSString *str = [EWUIUtil getStringFromTime:aveT];
    return str;
}

- (NSNumber *)successRate{
    float rate = 0.0;
    float wakes = 0;
    float validTasks = 0;
    
    for (EWTaskItem *task in self.tasks) {
        if (task.state == YES) {
            validTasks++;
            if (task.completed && [task.completed timeIntervalSinceDate:task.time] < kMaxWakeTime) {
                wakes++;
            }
        }
    }
    rate = wakes / validTasks;
    
    return [NSNumber numberWithFloat:rate];
}

- (NSString *)successString{
    float rate = self.successRate.floatValue;
    NSString *rateStr = [NSString stringWithFormat:@"%f%%", rate];
    return rateStr;
}

- (NSInteger)wakability{
    NSInteger ratio = MIN(self.aveWakingLength.integerValue / kMaxWakabilityTime, 1);
    NSInteger level = 10 - ratio*10;
    return level;
    
}

- (NSString *)wakabilityStr{
    NSInteger level = self.wakability;
    NSString *lvString = [NSString stringWithFormat:@"%ld/10", (long)level];
    return lvString;
}

- (NSString *)aveWakeUpTime{
    if (tasks.count) {
        NSInteger totalTime = 0;
        NSUInteger wakes = 0;
        
        for (EWTaskItem *t in self.tasks) {
            if (t.state == NO) continue;
            
            wakes++;
            totalTime += t.time.minutesFrom5am;
        }
        NSInteger aveTime = totalTime / wakes;
        NSDate *time = [[NSDate date] timeByMinutesFrom5am:aveTime];
        return time.date2String;
    }
    return @"-";
}

@end
