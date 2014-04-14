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

@implementation EWStatisticsManager
@synthesize person, tasks;

- (void)setPerson:(EWPerson *)p{
    person = p;
    tasks = [[EWTaskStore sharedInstance] pastTasksByPerson:p];
}

- (NSNumber *)aveWakeupTime{
    if (tasks.count) {
        NSInteger totalTime = 0;
        for (EWTaskItem *t in self.tasks) {
            NSInteger length;
            if (t.completed) {
                length = [t.completed timeIntervalSinceDate:t.time];
            }else{
                length = kMaxWakeTime;
            }
            
            totalTime = totalTime + length;
        }
        NSInteger aveTime = totalTime / tasks.count;
        return [NSNumber numberWithDouble:aveTime];
    }
    return 0;
}

- (NSNumber *)successRate{
    float rate = 0.0;
    if (self.tasks) {
        NSInteger total = tasks.count;
        NSInteger sCount = 0;
        for (EWTaskItem *t in tasks) {
            if (t.completed) {
                sCount++;
            }
        }
        rate = (float)sCount/total;
    }
    return [NSNumber numberWithFloat:rate];
}

@end
