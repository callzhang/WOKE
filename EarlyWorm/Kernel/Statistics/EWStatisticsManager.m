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
    if (self.tasks) {
        NSInteger totalTime = 0;
        for (EWTaskItem *t in self.tasks) {
            NSTimeInterval t1 = [t.time timeIntervalSinceReferenceDate];
            NSInteger int1 = t1;
            NSTimeInterval t2;
            if (t.completed) {
                t2 = [t.completed timeIntervalSinceReferenceDate];
            }else{
                t2 = int1 + 600;
            }
            NSInteger int2 = t2;
            
            totalTime = totalTime + (int2 - int1);
        }
        NSInteger aveTime = totalTime / self.tasks.count;
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
            if ([t.success boolValue]) {
                sCount++;
            }
        }
        rate = (float)sCount/total;
    }
    return [NSNumber numberWithFloat:rate];
}

@end
