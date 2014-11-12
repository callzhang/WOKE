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

NSString *const EWActivityTypeAlarm = @"alarm";
NSString *const EWActivityTypeFriendship = @"friendship";
NSString *const EWActivityTypeMedia = @"media";

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
        _currentAlarmActivity = [activities bk_match:^BOOL(EWActivity *obj) {
            return [obj.type isEqualToString:EWActivityTypeAlarm] ? YES : NO;
        }];
        
    }
    
    EWAlarm *nextAlarm = [EWPerson myNextAlarm];
    if (_currentAlarmActivity && fabs([_currentAlarmActivity.time timeIntervalSinceDate: nextAlarm.time.nextOccurTime])<1) {
        //the last activity is the current activity
        return _currentAlarmActivity;
    }
    else {
        _currentAlarmActivity = [EWActivity newActivity];
        _currentAlarmActivity.owner = [EWSession sharedSession].currentUser;
        _currentAlarmActivity.type = EWActivityTypeAlarm;
        _currentAlarmActivity.time = nextAlarm.time.nextOccurTime;
    }

    return _currentAlarmActivity;
}

+ (void)completeActivity:(EWActivity *)activity{
    //TODO
}

@end
