//
//  EWAlarmManager.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-8.
//  Copyright (c) 2013年 Shens. All rights reserved.
//
// Alarms schedule/delete/create in batch of 7. Notification of save sent out at saveAlarms

#import "EWAlarmManager.h"
#import "NSDate+Extend.h"
#import "NSString+Extend.h"
#import "EWIO.h"
#import "EWAlarmItem.h"
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWPerson.h"
#import "EWPersonStore.h"
//AppDelegate
#import "EWAppDelegate.h"
//backend
#import "StackMob.h"
//VC
#import "EWAlarmScheduleViewController.h"

@implementation EWAlarmManager
//@synthesize context;

+ (EWAlarmManager *)sharedInstance {
//    BOOL mainThread = [NSThread isMainThread];
//    if (!mainThread) {
//        NSLog(@"**** Alarm Store not on main thread ****");
//    }
    
    static EWAlarmManager *g_alarmManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_alarmManager = [[EWAlarmManager alloc] init];
    }); 
    
    return g_alarmManager;
}


#pragma mark - NEW
//add new alarm, save, add to current user, save user
- (EWAlarmItem *)newAlarm{
    NSLog(@"Create new Alarm");
    EWAlarmItem *a = [NSEntityDescription insertNewObjectForEntityForName:@"EWAlarmItem" inManagedObjectContext:[EWDataStore currentContext]];
    //assign id
    [a assignObjectId];
    
    //add relation
    a.owner = [EWDataStore user]; //also sets the reverse
    
    //save
    [[EWDataStore currentContext] saveAndWait:NULL];
    
    //notification
    //[[NSNotificationCenter defaultCenter] postNotificationName:kAlarmNewNotification object:self userInfo:@{@"alarm": a}];
    
    return a;
}

#pragma mark - SEARCH
- (NSArray *)alarmsForUser:(EWPerson *)user{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWAlarmItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"owner == %@", [EWDataStore user]];
    request.relationshipKeyPathsForPrefetching = @[@"tasks"];
    NSArray *alarms = [[EWDataStore currentContext] executeFetchRequestAndWait:request error:NULL];
    
    //sort
    NSArray *sortedAlarms = [alarms sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSInteger wkd1 = [(EWAlarmItem *)obj1 time].weekdayNumber;
        NSInteger wkd2 = [(EWAlarmItem *)obj2 time].weekdayNumber;
        if (wkd1 > wkd2) {
            return NSOrderedDescending;
        }else if (wkd1 < wkd2){
            return NSOrderedAscending;
        }else{
            return NSOrderedSame;
        }
    }];
    
    return sortedAlarms;
}

+ (NSArray *)myAlarms{
    return [[EWAlarmManager sharedInstance] alarmsForUser:[EWDataStore user]];
}

- (EWAlarmItem *)nextAlarm{
    EWAlarmItem *nextA;
    NSArray *alarms = [self alarmsForUser:[EWDataStore user]];
    //determine if the day need to be next week
    NSInteger dow = [[NSDate date] weekdayNumber];
    EWAlarmItem *a = alarms[dow];
    if ([a.time isEarlierThan:[NSDate date]]) {
        nextA = alarms[(dow+1)%7];
    }else{
        nextA = alarms[dow%7];
    }
    return nextA;
}

#pragma mark - SCHEDULE
//schedule according to alarms array. If array is empty, schedule according to default template.
- (NSArray *)scheduleAlarm{
    NSArray *alarms = [self alarmsForUser:[EWDataStore user]];
    //check excess
    if (alarms.count > 7) {
        [self deleteAllAlarms];
        [[EWDataStore currentContext] saveAndWait:NULL];
    }
    
    //schedule alarm from Sunday to Saturday of current week
    NSMutableArray *newAlarms = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
    //check if alarm exsit
    for (EWAlarmItem *a in alarms) {
        NSInteger i = [a.time weekdayNumber];
        NSAssert([newAlarms[i] isEqual:@NO], @"Duplicated alarm!");
        newAlarms[i] = a;
    }
    //start add alarm if blank
    BOOL newAlarm = NO;
    for (NSInteger i=0; i<7; i++) {
        if ([newAlarms[i] isKindOfClass:[EWAlarmItem class]]) {
            continue;
        }else if ([newAlarms[i] isEqual:@NO]){
            NSLog(@"Alarm for weekday %ld missing, start add alarm", (long)i);
            EWAlarmItem *a = [self newAlarm];
            //set time
            NSDate *d = [NSDate date];
            NSInteger wkd = [d weekdayNumber];
            NSCalendar *cal = [NSCalendar currentCalendar];//TIMEZONE
            NSDateComponents *comp = [[NSDateComponents alloc] init];
            comp.day = i-wkd;
            NSDate *time = [cal dateByAddingComponents:comp toDate:d options:0];//set the weekday
            
            //set time
            comp = [cal components: (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit |NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:time];
            comp.hour = 8;
            comp.minute = 0;
            time = [cal dateFromComponents:comp];//set time
            //set alarm time
            a.time = time;
            a.state = @YES;
            a.tone = currentUser.preference[@"DefaultTone"];
            //add to temp array
            newAlarms[i] = a;
            newAlarm = YES;
        }else{
            [NSException raise:@"Unknown state" format:@"Check weekday: %ld", (long)i];
        }
    }
    if (newAlarm) {
        //notification
        NSLog(@"Post all new alarms");
        //[[NSNotificationCenter defaultCenter] postNotificationName:kAlarmsAllNewNotification object:self userInfo:nil];
    }
    //save all alarms
    [[EWDataStore currentContext] saveOnSuccess:^{
        //
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error in saving Alarms" format:@"Error:%@", error.description];
    }];
    
    return newAlarms;
}

#pragma mark - DELETE
- (void)removeAlarm:(EWAlarmItem *)alarm{
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmDeleteNotification object:self userInfo:@{@"tasks":alarm.tasks}];
    [[EWDataStore currentContext] deleteObject:alarm];
    for (EWTaskItem *t in alarm.tasks) {
        [[EWDataStore currentContext] deleteObject:t];
    }
    [[EWDataStore currentContext] saveOnSuccess:^{
        NSLog(@"Alarm deleted");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error in deleting Alarm" format:@"Alarm:%@", alarm];
    }];
}

- (void)deleteAllAlarms{
    NSArray *alarms = [self alarmsForUser:[EWDataStore user]];
    NSMutableArray *tasksToDelete = [[NSMutableArray alloc] initWithCapacity:alarms.count * nWeeksToScheduleTask];
    for (EWAlarmItem *alarm in alarms) {
        [tasksToDelete addObject:alarm.tasks];
        [[EWDataStore currentContext] deleteObject:alarm];
    }
    //notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmDeleteNotification object:self userInfo:@{@"tasks":tasksToDelete}];
    //save
    NSError *err;
    [[EWDataStore currentContext] saveAndWait:&err];
}

#pragma mark - CHECK
- (BOOL)checkAlarms{
    //YES means alarms are good
    NSArray *alarms = [self alarmsForUser:currentUser];
    
    if (alarms.count == 0) {
        //need set up later
        if (currentUser.tasks.count == 0) {
            return YES;
        }
        return NO;
    }else if (alarms.count == 7){
        return YES;
    }else{
        //something wrong
        NSLog(@"Something wrong with alarms (%lu), delete all", (unsigned long)alarms.count);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alarm incorrect" message:@"Please reschedule your alarm" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        //delete all alarms
        [self deleteAllAlarms];
        return NO;
    }
}

/*
- (void)loginCheck{
    NSLog(@"Alarm Manager: User logged in, start checking alarm");
    BOOL needSchedule = ![self checkAlarms];
    if (needSchedule) {
        //[self scheduleAlarm];
        NSLog(@"Alarm Manager: Alarm not good, need to schedule");
    }else{
        NSLog(@"Alarm Manager: Alarm good, stored in allAlarms");
        self.allAlarms = [currentUser.alarms mutableCopy];
    }
}

- (void)logOut{
    NSLog(@"Alarm Manager: Logged out, allAlarm = nil");
    self.allAlarms = nil;
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[EWAlarmItem class]]) {
        if ([keyPath isEqualToString:@"state"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmStateChangedNotification object:object userInfo:@{@"alarm": object}];
        }else if ([keyPath isEqualToString:@"time"]){
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmTimeChangedNotification object:object userInfo:@{@"alarm": object}];
        }
    }
}
*/


/*
- (NSCalendarUnit)string2CalendarUnit:(NSString *)repeatString{
    if ([repeatString isEqual:@"Everyday"]) {
        return NSDayCalendarUnit;
    }else if ([repeatString isEqual:@"Weekday"]){
        return NSWeekCalendarUnit;
    }
    
    //NSArray *repeatArray = [repeatString repeatArray];
    //TODO
    return 0;
}*/
@end
