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
            NSTimeInterval t2;
            if (t.completed) {
                t2 = [t.completed timeIntervalSinceReferenceDate];
            }else{
                t2 = t1 + 600;
            }
            
            totalTime = totalTime + (t2 - t1);
        }
        return [NSNumber numberWithDouble:totalTime];
    }
    return nil;
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
