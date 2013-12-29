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
@synthesize allAlarms = _allAlarms;
@synthesize context;

+ (EWAlarmManager *)sharedInstance {
    static EWAlarmManager *g_alarmManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_alarmManager = [[EWAlarmManager alloc] init];
    }); 
    
    return g_alarmManager;
}

- (id)init{
    self = [super init];
    if (self) {
        context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
        NSLog(@"Context for Alarm Store is %@", context);
        //[self checkAlarms];
    }
    return self;
}

#pragma mark - Setter & Getter

- (NSMutableArray *)allAlarms{
    _allAlarms = [[[EWPersonStore sharedInstance].currentUser.alarms allObjects] mutableCopy];
    //sort
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
    [_allAlarms sortUsingDescriptors:@[sort]];
    return _allAlarms;
}

#pragma mark - NEW
//add new alarm, save, add to current user, save user
- (EWAlarmItem *)newAlarm{
    NSLog(@"Create new Alarm");
    //NSManagedObjectContext *context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
    EWAlarmItem *a = [NSEntityDescription insertNewObjectForEntityForName:@"EWAlarmItem" inManagedObjectContext:context];
    //assign id
    [a assignObjectId];
    
    //add relation
    a.owner = [EWPersonStore sharedInstance].currentUser; //also sets the reverse
    
    //save
    [context saveOnSuccess:^{
        //NSLog(@"EWAlarmItem saved successfully");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error saving EWAlarmItem" format:@"Reason: %@", error.description];
    }];
    
    //notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmNewNotification object:self userInfo:@{@"alarm": a}];
    
    return a;
}

#pragma mark - SEARCH
- (NSArray *)allAlarmsForUser:(EWPerson *)user{
    //NSManagedObjectContext *context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWAlarmItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"owner == %@", [EWPersonStore sharedInstance].currentUser];
    request.relationshipKeyPathsForPrefetching = @[@"tasks"];
    NSArray *alarms = [context executeFetchRequestAndWait:request error:NULL];
    //user.alarms = [NSSet setWithArray:alarms];
    return alarms;
}


- (EWAlarmItem *)nextAlarm{
    EWAlarmItem *nextA;
    //determine if the day need to be next week
    NSInteger dow = [[NSDate date] weekdayNumber];
    EWAlarmItem *a = _allAlarms[dow];
    if ([a.time isEarlierThan:[NSDate date]]) {
        nextA = _allAlarms[(dow+1)%7];
    }else{
        nextA = _allAlarms[dow%7];
    }
    return nextA;
}

#pragma mark - SCHEDULE
//schedule according to alarms array. If array is empty, schedule according to default template.
- (NSArray *)scheduleAlarm{
    //NSManagedObjectContext *context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
    //schedule alarm from Sunday to Saturday of current week
    NSMutableArray *newAlarms = [[NSMutableArray alloc] initWithCapacity:7];
    for (NSInteger i=0; i<7; i++) {
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
        a.tone = [EWPersonStore sharedInstance].currentUser.preference[@"DefaultTone"];
        //add to temp array
        [newAlarms addObject:a];
    }
    //save all alarms
    [context saveOnSuccess:^{
        //
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error in saving Alarms" format:@"Error:%@", error.description];
    }];
    
    return newAlarms;
}

#pragma mark - DELETE
- (void)removeAlarm:(EWAlarmItem *)alarm{
    //NSManagedObjectContext *context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
    [context deleteObject:alarm];
    [context saveOnSuccess:^{
        NSLog(@"Deleting successful");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error in deleting Alarm" format:@"Alarm:%@", alarm];
    }];
}

- (void)deleteAllAlarms{
    //NSManagedObjectContext *context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
    for (EWAlarmItem *a in self.allAlarms) {
        [context deleteObject:a];
    }
    [context saveOnSuccess:^{
        NSLog(@"Deleting successful");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error in deleting Alarm" format:@"Reason: %@", error.description];
    }];
}

#pragma mark - CHECK
- (BOOL)checkAlarms{
    //fetch again
    NSArray *alarms = [self allAlarmsForUser:[EWPersonStore sharedInstance].currentUser];
    
    return (alarms.count == 7) ? YES: NO;
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
