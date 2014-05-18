//
//  EWStatsManager.m
//  EarlyWorm
//
//  Created by Lei on 10/11/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWStatsManager.h"
#import "EWPerson.h"
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWAlarmItem.h"

@implementation EWStatsManager

+(EWStatsManager *)sharedInstance{
    static EWStatsManager *sharedInstance_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance_ = [[EWStatsManager alloc] init];
    });
    return sharedInstance_;
}



-(NSDictionary *)statsForPerson:(EWPerson *)person{
    NSMutableDictionary *stats = [[NSMutableDictionary alloc] init];
    [person refresh];
    NSArray *pTasks = [[EWTaskStore sharedInstance] pastTasksByPerson:person];
    NSInteger nTask = pTasks.count;
    if (nTask == 0) {
        return nil;
    }
    NSInteger totalWakeUpTime = 0;
    double success = 0;
    NSInteger totalWakeUpLength = 0;
    for (EWTaskItem *task in pTasks) {
        NSInteger wakeupTime;
        if (task.completed) {
            wakeupTime = [task.completed timeIntervalSinceDate:task.time];
        }else{
            wakeupTime = kMaxWakeTime;
        }
        totalWakeUpLength += wakeupTime;
        totalWakeUpTime += [task.time timeIntervalSinceReferenceDate];
        success += task.completed?1.0:0;
    }
    stats[kAverageWakeUpLength] = [NSNumber numberWithInteger:totalWakeUpLength/nTask];
    stats[kAverageWakeUpTime] = [NSDate dateWithTimeIntervalSinceReferenceDate:totalWakeUpTime/nTask];
    stats[kSuccessRate] = [NSNumber numberWithDouble:success/(double)nTask];
    
    return stats;
}

@end
