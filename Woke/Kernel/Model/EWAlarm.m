//
//  EWAlarmItem.m
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWAlarm.h"
#import "EWPersonManager.h"

@implementation EWAlarm


#pragma mark - NEW
//add new alarm, save, add to current user, save user
+ (EWAlarm *)newAlarm{
    NSParameterAssert([NSThread isMainThread]);
    DDLogVerbose(@"Create new Alarm");
    
    //add relation
    EWAlarm *a = [EWAlarm createEntity];
    a.updatedAt = [NSDate date];
    a.owner = [EWSession sharedSession].currentUser;
    a.state = @YES;
    a.tone = [EWSession sharedSession].currentUser.preference[@"DefaultTone"];
    
    return a;
}

#pragma mark - DELETE
- (void)remove{
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmDeleteNotification object:self userInfo:nil];
    [self deleteEntity];
    [EWSync save];
}

+ (void)deleteAll{
    //delete
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (EWAlarm *alarm in [EWSession sharedSession].currentUser.alarms) {
            EWAlarm *localAlarm = [alarm inContext:localContext];
            [localAlarm remove];
        }
    }];
}

#pragma mark - Validate alarm
- (BOOL)validate{
    BOOL good = YES;
    if (!self.owner) {
        DDLogError(@"Alarm（%@）missing owner", self.serverID);
        self.owner = [[EWSession sharedSession].currentUser inContext:self.managedObjectContext];
    }
    if (!self.tasks || self.tasks.count == 0) {
        DDLogError(@"Alarm（%@）missing task", self.serverID);
        good = NO;
    }
    if (!self.time) {
        DDLogError(@"Alarm（%@）missing time", self.serverID);
        good = NO;
    }
    //check tone
    if (!self.tone) {
        DDLogError(@"Tone not set, fixed!");
        self.tone = [EWSession sharedSession].currentUser.preference[@"DefaultTone"];
    }
    
    if (!good) {
        DDLogError(@"Alarm failed validation: %@", self);
    }
    return good;
}

+ (NSArray *)alarmsForUser:(EWPerson *)user{
    NSMutableArray *alarms = [[user.alarms allObjects] mutableCopy];
    
    NSComparator alarmComparator = ^NSComparisonResult(id obj1, id obj2) {
        NSInteger wkd1 = [(EWAlarm *)obj1 time].weekdayNumber;
        NSInteger wkd2 = [(EWAlarm *)obj2 time].weekdayNumber;
        if (wkd1 > wkd2) {
            return NSOrderedDescending;
        }else if (wkd1 < wkd2){
            return NSOrderedAscending;
        }else{
            return NSOrderedSame;
        }
    };
    
    //sort
    NSArray *sortedAlarms = [alarms sortedArrayUsingComparator:alarmComparator];
    
    return sortedAlarms;
}
@end
