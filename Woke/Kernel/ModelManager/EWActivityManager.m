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
    return [activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.updatedAt ascending:NO]]];
}

- (EWActivity *)createMediaActivityWithMedia:(EWMedia *)media{
    EWActivity *activity = [EWActivity newActivity];
    activity.type = EWActivityType.media;
    [activity addMediasObject:media];
    
    return activity;
}

- (EWActivity *)createFriendshipActivityWithPerson:(EWMedia *)media friended:(BOOL)friended{
    EWActivity *activity = [EWActivity newActivity];
    activity.type = EWActivityType.friendship;
    
}

@end
