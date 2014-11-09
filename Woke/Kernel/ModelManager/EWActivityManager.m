//
//  EWActivityManager.m
//  Woke
//
//  Created by Lei Zhang on 10/29/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWActivityManager.h"
#import "EWPerson.h"
#import "EWActivity.h"
#import "EWAlarm.h"

@implementation EWActivityManager

+ (EWActivityManager *)sharedManager{
    static EWActivityManager *manager;
    if (!manager) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            manager = [[EWActivityManager alloc] init];
        });
    }
    return manager;
}

+ (NSArray *)myActivities{
    NSArray *activities = [EWSession sharedSession].currentUser.activities.allObjects;
    return [activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWActivityAttributes.time ascending:NO]]];
}

- (EWActivity *)currentAlarmActivity{
    if (!_currentAlarmActivity) {
        NSArray *activities = [EWActivityManager myActivities];
        EWActivity *lastActivity = [activities bk_match:^BOOL(EWActivity *obj) {
            return [obj.type isEqualToString:EWActivityTypeAlarm] ? YES : NO;
        }];
        
        EWAlarm *nextAlarm = [EWPerson myNextAlarm];
        if (lastActivity && fabs([lastActivity.time timeIntervalSinceDate: nextAlarm.time.nextOccurTime])<1) {
            //the last activity is the current activity
            return lastActivity;
        }
        else {
            lastActivity = [EWActivity newActivity];
            lastActivity.owner = [EWSession sharedSession].currentUser;
            lastActivity.type = EWActivityTypeAlarm;
            lastActivity.time = nextAlarm.time.nextOccurTime;
        }
        _currentAlarmActivity = lastActivity;
    }
    return _currentAlarmActivity;
}

@end
