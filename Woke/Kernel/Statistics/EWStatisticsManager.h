//
//  EWStatisticsManager.h
//  EarlyWorm
//
//  Created by Lei on 1/8/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"

#define kMaxWakabilityTime      600


#define kStatsCache         @"stats_cache"
#define kAveWakeLength      @"ave_wake_length"
#define kAveWakeTime        @"ave_wake_time"
#define kSuccessRate        @"ave_success_rate"
#define kWakeability        @"wakeability"

#define kTaskActivityCache  @"task_activity_cache"
#define kTaskState          @"state"
#define kTaskTime           @"time"
#define kWokeTime           @"wake"
#define kWokeBy             @"woke_by"
#define kWokeTo             @"woke_to"

#define kActivitiesCache    @"activities_cache"
#define kFriended           @"friended"
#define kChallengesFinished @"challenges_finished"
#define kTasksFinished      @"task_finished"
#define kAchievements       @"achievements"

@interface EWStatisticsManager : NSObject

@property (nonatomic) EWPerson *person;
@property (nonatomic) NSArray *tasks;
@property (nonatomic) NSNumber *aveWakingLength;
@property (nonatomic) NSString *aveWakingLengthString;
@property (nonatomic) NSString *aveWakeUpTime;
@property (nonatomic) NSNumber *successRate;
@property (nonatomic) NSString *successString;
@property (nonatomic) NSNumber *wakability;
@property (nonatomic) NSString *wakabilityStr;

+ (void)updateTaskActivityCache;
+ (void)updateCacheWithFriendsAdded:(NSArray *)friendIDs;

@end
