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

//TODO: [LEI] send notification, move update cacedinto to EWPerson, remove methods related in EWAlarmManager.
- (void)setState:(NSNumber *)state {
    [self willChangeValueForKey:EWAlarmAttributes.state];
    [self setPrimitiveState:state];
    [EWPerson updateMyCachedInfoForAlarm:self];
    [self didChangeValueForKey:EWAlarmAttributes.state];
}

- (void)setTime:(NSDate *)time {
    [self willChangeValueForKey:EWAlarmAttributes.time];
    [self setPrimitiveTime:time];
    [self didChangeValueForKey:EWAlarmAttributes.time];
}

- (void)setTone:(NSString *)tone {
    [self willChangeValueForKey:EWAlarmAttributes.tone];
    [self setPrimitiveTone:tone];
    [self didChangeValueForKey:EWAlarmAttributes.tone];
}

- (void)setStatement:(NSString *)statement {
    [self willChangeValueForKey:EWAlarmAttributes.statement];
    [self setPrimitiveStatement:statement];
    [self didChangeValueForKey:EWAlarmAttributes.statement];
}
#pragma mark -

@end
