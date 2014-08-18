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
#import "EWMediaStore.h"
#import "EWMediaItem.h"


@implementation EWStatisticsManager
@synthesize person, tasks;

- (void)setPerson:(EWPerson *)p{
    person = p;
    if (p.isMe) {
        //newest on top
        tasks = [[EWTaskStore sharedInstance] pastTasksByPerson:p];
    }else{
        [self getStatsFromCache];
    }
}

- (void)getStatsFromCache{
    
    //load cached info
    NSDictionary *stats = self.person.cachedInfo[kStatsCache];
    self.aveWakingLength = stats[kAveWakeLength];
    self.aveWakeUpTime = stats[kAveWakeTime];
    self.successRate = stats[kSuccessRate];
    self.wakability = stats[kWakeability];
}

- (void)setStatsToCache{
    NSMutableDictionary *cache = self.person.cachedInfo.mutableCopy;
    NSMutableDictionary *stats = [cache[kStatsCache] mutableCopy]?:[NSMutableDictionary new];
    
    stats[kAveWakeLength] = self.aveWakingLength;
    stats[kAveWakeTime] = self.aveWakeUpTime;
    stats[kSuccessRate] = self.successRate;
    stats[kWakeability] = self.wakability;
    
    cache[kStatsCache] = stats;
    self.person.cachedInfo = cache;
    [EWDataStore save];
}

- (NSNumber *)aveWakingLength{
    if (_aveWakingLength) {
        return _aveWakingLength;
    }
    
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
        _aveWakingLength = [NSNumber numberWithInteger:aveTime];
        [self setStatsToCache];
        return _aveWakingLength;
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
    if (_successRate) {
        return _successRate;
    }
    
    if (tasks.count) {
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
        
        _successRate =  [NSNumber numberWithFloat:rate];
        [self setStatsToCache];
        return _successRate;
    }
    return 0;
}

- (NSString *)successString{
    float rate = self.successRate.floatValue;
    NSString *rateStr = [NSString stringWithFormat:@"%f%%", rate];
    return rateStr;
}

- (NSNumber *)wakability{
    if (_wakability) {
        return _wakability;
    }
    
    if (tasks.count) {
        double ratio = MIN(self.aveWakingLength.integerValue / kMaxWakabilityTime, 1);
        double level = 10 - ratio*10;
        _wakability = [NSNumber numberWithDouble:level];
        [self setStatsToCache];
        return _wakability;
    }
    return 0;
}

- (NSString *)wakabilityStr{
    double level = self.wakability.floatValue;
    NSString *lvString = [NSString stringWithFormat:@"%ld/10", (long)level];
    return lvString;
}

- (NSString *)aveWakeUpTime{
    if (_aveWakeUpTime) {
        return _aveWakeUpTime;
    }
    
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
        _aveWakeUpTime = time.date2String;
        [self setStatsToCache];
        return _aveWakeUpTime;
    }
    
    return @"-";
}


#pragma mark - Update Activity
+ (void)updateTaskActivityCache{
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWPerson *localMe = [EWPersonStore meInContext:localContext];
        NSArray *tasks = [[EWTaskStore sharedInstance] pastTasksByPerson:localMe];
        NSMutableDictionary *cache = localMe.cachedInfo.mutableCopy;
        NSMutableDictionary *activity = [cache[kTaskActivityCache] mutableCopy]?:[NSMutableDictionary new];
        
        for (NSInteger i =0; i<tasks.count; i++) {
            //start from the newest task
            EWTaskItem *task = tasks[i];
            
            NSDate *wakeTime;
            NSArray *wokeBy;
            NSArray *wokeTo;
            
            
            if (task.completed && [task.completed timeIntervalSinceDate:task.time] < kMaxWakeTime) {
                wakeTime = task.completed;
            }
            else{
                wakeTime = [task.time dateByAddingTimeInterval:kMaxWakeTime];
            }
            
            NSDate *eod = task.time.endOfDay;
            NSDate *bod = task.time.beginingOfDay;
            
            
            NSSet *myMedias = me.medias;
            NSMutableArray *myMediasTasks = [NSMutableArray new];
            for (EWMediaItem *m in myMedias) {
                for (EWTaskItem *t in m.tasks) {
                    if ([t.time isEarlierThan:eod] && [bod isEarlierThan:t.time]) {
                        [myMediasTasks addObject:t];
                    }
                }
            }
            
            wokeBy = (NSArray *)[task.medias valueForKeyPath:@"author.objectId"];
            wokeTo = (NSArray *)[myMediasTasks valueForKeyPath:@"owner.objectId"];
            
            NSDictionary *taskActivity = @{kTaskState: @(task.state),
                                           kTaskTime: task.time,
                                           kWokeTime: @(!!task.completed),
                                           kWokeBy: wokeBy.count?wokeBy:[NSNull null],
                                           kWokeTo: wokeTo.count?wokeTo:[NSNull null]};
            
            NSString *dateKey = task.time.date2YYMMDDString;
            activity[dateKey] = taskActivity;
        }
        
        cache[kTaskActivityCache] = [activity copy];
        localMe.cachedInfo = [cache copy];

    } completion:^(BOOL success, NSError *error) {
        //
    }];
    
}

+ (void)updateCacheWithFriendsAdded:(NSArray *)friendIDs{
    NSMutableDictionary *cache = me.cachedInfo.mutableCopy;
    NSMutableDictionary *activity = [cache[kActivitiesCache] mutableCopy]?:[NSMutableDictionary new];
    NSMutableDictionary *friendsActivityDic = [activity[kFriended] mutableCopy] ?:[NSMutableDictionary new];
    NSString *dateKey = [NSDate date].date2YYMMDDString;
    NSArray *friendedArray = friendsActivityDic[dateKey]?:[NSArray new];
    NSMutableSet *friendedSet = [NSMutableSet setWithArray:friendedArray];;
    
    [friendedSet addObjectsFromArray:friendIDs];
    
    friendsActivityDic[dateKey] = [friendedSet allObjects];
    activity[kFriended] = [friendsActivityDic copy];
    cache[kActivitiesCache] = [activity copy];
    me.cachedInfo = [cache copy];
    
    [EWDataStore save];
}

@end
