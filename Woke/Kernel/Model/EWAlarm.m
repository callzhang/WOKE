//
//  EWAlarmItem.m
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWAlarm.h"
#import "EWPersonStore.h"

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
- (BOOL)validateAlarm{
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


@end
