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
#import "NSDate+Extend.h"

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
    NSDictionary *stats = [[NSDictionary alloc] init];
    NSArray *pTasks = [[EWTaskStore sharedInstance] pastTasksByPerson:person];
    NSInteger nTask = pTasks.count;
    if (nTask == 0) {
        return nil;
    }
    NSInteger totalWakeUpTime = 0;
    NSInteger success = 0;
    NSInteger totalWakeUpLength = 0;
    for (EWTaskItem *task in pTasks) {
        totalWakeUpLength += [task.length integerValue];
        totalWakeUpTime += [task.time timeIntervalSinceReferenceDate];
        success += (NSInteger)task.success;
    }
    [stats setValue:[NSNumber numberWithInt:totalWakeUpLength/nTask] forKey:@"AverageWakeUpLength"];
    [stats setValue:[NSDate dateWithTimeIntervalSinceReferenceDate:totalWakeUpTime/nTask] forKey:@"AverageWakeUpTime"];
    [stats setValue:[NSNumber numberWithInt:success/nTask] forKey:@"SuccessRate"];
    
    return stats;
}

@end
