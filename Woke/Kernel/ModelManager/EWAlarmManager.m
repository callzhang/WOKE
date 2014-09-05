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
#import "EWUtil.h"
#import "EWAlarmItem.h"
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWPerson.h"
#import "EWPersonStore.h"
//#import "EWPersonStore.h"
#import "EWUserManagement.h"
//AppDelegate
#import "EWAppDelegate.h"
//backend
//VC
#import "EWAlarmScheduleViewController.h"

@implementation EWAlarmManager

+ (EWAlarmManager *)sharedInstance {
    //make sure core data stuff is always on main thread
    //NSParameterAssert([NSThread isMainThread]);
    static EWAlarmManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWAlarmManager alloc] init];
        manager.alarmNeedToSetup = NO;
        manager.isSchedulingAlarm = NO;
        //[[NSNotificationCenter defaultCenter] addObserver:manager selector:@selector(observedAlarmChange:) name:kAlarmChangedNotification object:nil];
    }); 
    
    return manager;
}


#pragma mark - NEW
//add new alarm, save, add to current user, save user
- (EWAlarmItem *)newAlarm{
    NSParameterAssert([NSThread isMainThread]);
    NSLog(@"Create new Alarm");
    
    //add relation
    EWAlarmItem *a = [EWAlarmItem createEntity];
    a.updatedAt = [NSDate date];
    a.owner = me;
    a.state = YES;
    a.tone = me.preference[@"DefaultTone"];
    
    return a;
}

#pragma mark - SEARCH
- (NSArray *)alarmsForUser:(EWPerson *)user{
    NSMutableArray *alarms = [[user.alarms allObjects] mutableCopy];
    
    NSComparator alarmComparator = ^NSComparisonResult(id obj1, id obj2) {
        NSInteger wkd1 = [(EWAlarmItem *)obj1 time].weekdayNumber;
        NSInteger wkd2 = [(EWAlarmItem *)obj2 time].weekdayNumber;
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

+ (NSArray *)myAlarms{
    NSParameterAssert([NSThread isMainThread]);
    return [[EWAlarmManager sharedInstance] alarmsForUser:me];
}

//- (EWAlarmItem *)nextAlarm{
//    EWAlarmItem *nextA;
//    NSArray *alarms = [self alarmsForUser:[EWPersonStore me]];
//    //determine if the day need to be next week
//    NSInteger dow = [[NSDate date] weekdayNumber];
//    EWAlarmItem *a = alarms[dow];
//    if ([a.time isEarlierThan:[NSDate date]]) {
//        nextA = alarms[(dow+1)%7];
//    }else{
//        nextA = alarms[dow%7];
//    }
//    return nextA;
//}

- (EWTaskItem *)firstTaskForAlarm:(EWAlarmItem *)alarm{
    if (alarm.tasks.count == 0) {
        return nil;
    }else if (alarm.tasks.count == 1){
        return alarm.tasks.anyObject;
    }
    NSMutableArray *tasks = [[alarm.tasks allObjects] mutableCopy];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES];
    [tasks sortUsingDescriptors:@[sort]];
    return tasks[0];
}

#pragma mark - SCHEDULE
- (NSArray *)scheduleNewAlarms{
    self.alarmNeedToSetup = YES;
    return [self scheduleAlarm];
}

//schedule according to alarms array. If array is empty, schedule according to default template.
- (NSArray *)scheduleAlarm{
    NSParameterAssert([NSThread isMainThread]);
    if (self.isSchedulingAlarm) {
        NSLog(@"Skip scheduling alarm because it is scheduling already!");
        return nil;
    }
    self.isSchedulingAlarm = YES;
    
    //get alarms
    NSMutableArray *alarms = [[self alarmsForUser:me] mutableCopy];
    
    
    BOOL hasChange = NO;
    
    //check from server for alarm with owner but lost relation
    if (alarms.count != 7 && [EWDataStore isReachable]) {
        //cannot check alarm for myself, which will cause a checking/schedule cycle
        
        NSLog(@"Alarm for me is less than 7, fetch from server!");
        PFQuery *alarmQuery = [PFQuery queryWithClassName:@"EWAlarmItem"];
        [alarmQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
        [alarmQuery whereKey:kParseObjectID notContainedIn:[alarms valueForKey:kParseObjectID]];
        NSArray *objects = [alarmQuery findObjects];
        
        for (PFObject *a in objects) {
            [EWDataStore setCachedParseObject:a];
            EWAlarmItem *alarm = (EWAlarmItem *)[a managedObjectInContext:mainContext];;
            [alarm refresh];
            alarm.owner = me;
            if (![EWAlarmManager validateAlarm:alarm]) {
                [self removeAlarm:alarm];
            }else if (![alarms containsObject:alarm]) {
                [alarms addObject:alarm];
                hasChange = YES;
                NSLog(@"Alarm found from server %@", alarm.time.weekday);
            }
        }
    }
    
    //check if need to check
    if (alarms.count==0) {
        if ([EWTaskStore myTasks].count == 0 && !_alarmNeedToSetup) {
            //initial state task==0, need another indicator to break the lock
            NSLog(@"Skip check alarm due to 0 tasks exists");
            self.isSchedulingAlarm = NO;
            return nil;
        }
    }
    
    //Fill array with alarm, delete redundency
    NSMutableArray *newAlarms = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
    //check if alarm scheduled are duplicated
    for (EWAlarmItem *a in alarms) {
        BOOL good = [EWAlarmManager validateAlarm:a];
        
        //check time
        if (!good) {
            NSLog(@"Something wrong with alarm %@. Deleted.",[a.time date2detailDateString]);
            [a deleteEntity];
            continue;
        }
        
        //get the day alarm represents
        NSInteger i = [a.time weekdayNumber];
        
        //see if that day has alarm already
        if (![newAlarms[i] isEqual:@NO]){
            //remove duplicacy
            NSLog(@"@@@ Duplicated alarm found. Deleted! %@", a.time.date2detailDateString);
            [a deleteEntity];
            hasChange = YES;
            continue;
        }
        //fill that day to the new alarm array
        newAlarms[i] = a;
    }
    
    //remove excess
    [alarms removeObjectsInArray:newAlarms];
    for (EWAlarmItem *a in alarms) {
        NSLog(@"Corruped alarm found and deleted: %@", [a.time date2detailDateString]);
        [self removeAlarm:a];
        hasChange = YES;
    }
    
    //start add alarm if blank
    for (NSInteger i=0; i<newAlarms.count; i++) {
        if (![newAlarms[i] isEqual:@NO]) {
            //skip if alarm exists
            continue;
        }
    
        NSLog(@"Alarm for weekday %ld missing, start add alarm", (long)i);
        EWAlarmItem *a = [self newAlarm];
        //set time
        NSDate *d = [NSDate date];
        NSInteger wkd = [d weekdayNumber];
        NSCalendar *cal = [NSCalendar currentCalendar];//TIMEZONE
        NSDateComponents *comp = [[NSDateComponents alloc] init];
        comp.day = i-wkd;
        NSDate *time = [cal dateByAddingComponents:comp toDate:d options:0];//set the weekday
        
        //get time
        a.time = time;//set the time first so we can get the saved time in next line
        NSDictionary *timeDic = [self getSavedAlarmTime:a];
        comp = [cal components: (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit |NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:time];
        comp.hour = [(NSNumber *)timeDic[@"hour"] intValue];
        comp.minute = [(NSNumber *)timeDic[@"minute"] intValue];
        time = [cal dateFromComponents:comp];//set time
        //set alarm time
        a.time = time;
        //add to temp array
        newAlarms[i] = a;
        hasChange = YES;
        
    }
    
    //save
    if (hasChange) {
        //notification
        NSLog(@"Saving new alarms");
        [EWDataStore save];
        [self setSavedAlarmTimes];
        
        //notification
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //delay here to make sure the thread don't compete at the same time
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmChangedNotification object:self userInfo:nil];
        });
        
    }
    
    self.isSchedulingAlarm = NO;
    self.alarmNeedToSetup = NO;
    return newAlarms;
}

#pragma mark - DELETE
- (void)removeAlarm:(EWAlarmItem *)alarm{
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmDeleteNotification object:alarm userInfo:nil];
    [alarm.managedObjectContext deleteObject:alarm];
    [EWDataStore save];
}

- (void)deleteAllAlarms{
    //NSArray *alarmIDs = [me.alarms valueForKey:@"objectID"];
    
    //notification
    //[[NSNotificationCenter defaultCenter] postNotificationName:kAlarmDeleteNotification object:alarms userInfo:@{@"alarms": alarms}];
    
    //delete
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (EWAlarmItem *alarm in me.alarms) {
            EWAlarmItem *localAlarm = [alarm inContext:localContext];
            [self removeAlarm:localAlarm];
        }
    }];
}


#pragma mark - Get/Set alarm to UserDefaults
- (NSDictionary *)getSavedAlarmTime:(EWAlarmItem *)alarm{
    NSArray *alarmTimes = [self getSavedAlarmTimes];
    NSInteger wkd = [alarm.time weekdayNumber];
    double number = [(NSNumber *)alarmTimes[wkd] doubleValue];
    NSDictionary *dic = [EWUtil timeFromNumber:number];
    return dic;
}

- (void)setSavedAlarmTimes{
    NSMutableArray *alarmTimes = [[self getSavedAlarmTimes] mutableCopy];
    NSArray *alarms = [EWAlarmManager myAlarms];
    
    for (EWAlarmItem *alarm in alarms) {
        NSInteger wkd = [alarm.time weekdayNumber];
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *comp = [cal components: (NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:alarm.time];
        double hour = comp.hour;
        double minute = comp.minute;
        double number = round(hour*100 + minute)/100.0;
        [alarmTimes setObject:[NSNumber numberWithDouble:number] atIndexedSubscript:wkd];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:alarmTimes.copy forKey:kSavedAlarms];
}

- (NSArray *)getSavedAlarmTimes{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *alarmTimes = [defaults valueForKey:kSavedAlarms];
    //create if not exsit
    if (!alarmTimes) {
        //if asking saved value, the alarm is not scheduled
        
        alarmTimes = defaultAlarmTimes;
        [defaults setObject:alarmTimes forKey:kSavedAlarms];
        [defaults synchronize];
    }
    return alarmTimes;
}


#pragma mark - NOTIFICATION & KVO
//- (void)observedAlarmChange:(NSNotification *)notification{
//    alarm change is handled in schedule alarm view controoler
//}


//KVO not recommended cause it doesn't preserve the observing state between app launches, which makes it a complex process to observe-remove etc..
/*
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

#pragma mark - Validate alarm
+ (BOOL)validateAlarm:(EWAlarmItem *)alarm{
    BOOL good = YES;
    if (!alarm.owner) {
        NSLog(@"Alarm（%@）missing owner", alarm.serverID);
        alarm.owner = [me inContext:alarm.managedObjectContext];
    }
    if (!alarm.tasks || alarm.tasks.count == 0) {
        good = NO;
    }
    if (!alarm.time) {
        good = NO;
    }
    //check tone
    if (!alarm.tone) {
        NSLog(@"Tone not set");
        alarm.tone = me.preference[@"DefaultTone"];
    }
    return good;
}

@end
