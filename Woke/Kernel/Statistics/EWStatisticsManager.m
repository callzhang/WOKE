//
//  EWStatisticsManager.m
//  EarlyWorm
//
//  Created by Lei on 1/8/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWStatisticsManager.h"
//#import "EWActivity.h"
//#import "EWTaskManager.h"
#import "EWUIUtil.h"
#import "EWMediaManager.h"
#import "EWMedia.h"
#import "EWActivity.h"
#import "EWActivityManager.h"


@implementation EWStatisticsManager

- (void)setPerson:(EWPerson *)p{
    _person = p;
    if (p.isMe) {
        //newest on top
        _activities = [EWPerson myActivities];
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
    [EWSync save];
}

- (NSNumber *)aveWakingLength{
    if (_aveWakingLength) {
        return _aveWakingLength;
    }
    
    if (_activities.count) {
        NSInteger totalTime = 0;
        NSUInteger wakes = 0;
        
        for (EWActivity *activity in self.activities) {
            
            wakes++;
            NSInteger length;
            if (activity.completed) {
                length = MAX([activity.completed timeIntervalSinceDate:activity.time], kMaxWakeTime);
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
    NSString *str = [NSDate getStringFromTime:aveT];
    return str;
}

- (NSNumber *)successRate{
    if (_successRate) {
        return _successRate;
    }
    
    if (_activities.count) {
        float rate = 0.0;
        float wakes = 0;
        float validTasks = 0;
//        
//        for (EWActivity *_activity in self.tasks) {
//            if (ac.state == YES) {
//                validTasks++;
//                if (task.completed && [task.completed timeIntervalSinceDate:task.time] < kMaxWakeTime) {
//                    wakes++;
//                }
//            }
//        }
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
    
    if (_activities.count) {
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
    
    if (_activities.count) {
        NSInteger totalTime = 0;
        NSUInteger wakes = 0;
        
        for (EWActivity *activity in self.activities) {
            
            wakes++;
            totalTime += activity.time.minutesFrom5am;
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
+ (void)updateActivityCacheWithCompletion:(void (^)(void))block{
    //test
    //return
    /*
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWPerson *localMe = [[EWSession sharedSession].currentUser inContext:localContext];
        [[EWTaskManager sharedInstance] checkPastTasks];
        NSArray *tasks = [[EWTaskManager sharedInstance] pastTasksByPerson:localMe];//newest on top
        NSMutableDictionary *cache = localMe.cachedInfo.mutableCopy;
        NSMutableDictionary *activity = [cache[kTaskActivityCache] mutableCopy]?:[NSMutableDictionary new];
        if (activity.count == tasks.count) {
            NSLog(@"=== cached _activity activities count is same as past _activity count (%ld)", (long)tasks.count);
            return;
        }
        
        for (NSInteger i =0; i<tasks.count; i++) {
            //start from the newest task
            EWActivity *_activity = tasks[i];
            
            NSDate *wakeTime;
            NSArray *wokeTo;
            
            
            if (task.completed && [task.completed timeIntervalSinceDate:task.time] < kMaxWakeTime) {
                wakeTime = task.completed;
            }else{
                wakeTime = [task.time dateByAddingTimeInterval:kMaxWakeTime];
            }
            
            NSDate *eod = task.time.endOfDay;
            NSDate *bod = task.time.beginingOfDay;
            
            //woke to receivers
            NSMutableArray *receivers = [NSMutableArray new];
            for (EWMedia *m in [EWSession sharedSession].currentUser.medias.copy) {
				if (![mainContext existingObjectWithID:m.objectID error:NULL]) return;
                for (EWActivity *t in m.activity.copy) {
					if (![mainContext existingObjectWithID:t.objectID error:NULL]) return;
                    if ([t.time isEarlierThan:eod] && [bod isEarlierThan:t.time]) {
                        NSString *receiver = t.owner.objectId;
                        if (receiver) {
                            [receivers addObject:receiver];
                        }
                    }
                }
            }
            wokeTo = receivers.copy;
            
            
            //woke by sender
            NSArray *wokeBy;
            NSMutableArray *senders = [NSMutableArray new];
            for (EWMedia *m in task.medias) {
                NSString *sender = m.author.objectId;
                if (!sender) continue;
                [senders addObject:sender];
            }
            wokeBy = senders.copy;
            
            @try {
                NSDictionary *taskActivity = @{kTaskState: @(task.state),
                                               kTaskTime: task.time,
                                               kWokeTime: wakeTime,
                                               kWokeBy: wokeBy.count?wokeBy:@0,
                                               kWokeTo: wokeTo.count?wokeTo:@0};
                
                NSString *dateKey = task.time.date2YYMMDDString;
                activity[dateKey] = taskActivity;
            }
            @catch (NSException *exception) {
                NSLog(@"*** Failed to generate _activity activity: %@", exception.description);
            }
            
        }
        
        cache[kTaskActivityCache] = [activity copy];
        localMe.cachedInfo = [cache copy];
        
        NSLog(@"_activity activity cache updated with %d records", activity.count);

    } completion:^(BOOL success, NSError *error) {
        NSLog(@"Finished updating _activity activity cache");
        if (block) {
            block();
        }
    }];
    */
}

+ (void)updateCacheWithFriendsAdded:(NSArray *)friendIDs{
    NSMutableDictionary *cache = [EWSession sharedSession].currentUser.cachedInfo.mutableCopy;
    NSMutableDictionary *activity = [cache[kActivitiesCache] mutableCopy]?:[NSMutableDictionary new];
    NSMutableDictionary *friendsActivityDic = [activity[kFriended] mutableCopy] ?:[NSMutableDictionary new];
    NSString *dateKey = [NSDate date].date2YYMMDDString;
    NSArray *friendedArray = friendsActivityDic[dateKey]?:[NSArray new];
    NSMutableSet *friendedSet = [NSMutableSet setWithArray:friendedArray];;
    
    [friendedSet addObjectsFromArray:friendIDs];
    
    friendsActivityDic[dateKey] = [friendedSet allObjects];
    activity[kFriended] = [friendsActivityDic copy];
    cache[kActivitiesCache] = [activity copy];
    [EWSession sharedSession].currentUser.cachedInfo = [cache copy];
    
    [EWSync save];
}

@end
