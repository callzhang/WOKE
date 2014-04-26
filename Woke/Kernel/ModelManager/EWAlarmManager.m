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
//AppDelegate
#import "EWAppDelegate.h"
//backend
#import "StackMob.h"
//VC
#import "EWAlarmScheduleViewController.h"

@implementation EWAlarmManager
//@synthesize context;

+ (EWAlarmManager *)sharedInstance {
    static EWAlarmManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWAlarmManager alloc] init];
        manager.alarmNeedToSetup = NO;
        //[[NSNotificationCenter defaultCenter] addObserver:manager selector:@selector(observedAlarmChange:) name:kAlarmChangedNotification object:nil];
    }); 
    
    return manager;
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
    a.state = YES;
    a.tone = currentUser.preference[@"DefaultTone"];
    
    //save
//    [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
//        NSError *err;
//        [[EWDataStore currentContext] saveAndWait:&err];
//        if (err) {
//            NSLog(@"Save alarm failed: %@", err.description);
//        }
//    }];
    
    //notification
    //[[NSNotificationCenter defaultCenter] postNotificationName:kAlarmNewNotification object:self userInfo:@{@"alarm": a}];
    
    return a;
}

#pragma mark - SEARCH
- (NSArray *)alarmsForUser:(EWPerson *)user{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWAlarmItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"owner == %@", [EWDataStore user]];
    request.relationshipKeyPathsForPrefetching = @[@"tasks"];
    NSError *err;
    SMRequestOptions *options;
    if ([user.username isEqualToString:currentUser.username]) {
        options = [EWDataStore optionFetchCacheElseNetwork];
    }else{
        options = [EWDataStore optionFetchNetworkElseCache];
    }
    NSArray *alarms = [[EWDataStore currentContext] executeFetchRequestAndWait:request returnManagedObjectIDs:NO options:options error:&err];
    if (err) {
        NSLog(@"*** Failed to fetch alarm for user %@", user.name);
    }
    
    //check
    if (!alarms) {
        NSLog(@"*** Didn't get alarms, please check code!");
    }
    
    
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
- (NSArray *)scheduleNewAlarms{
    self.alarmNeedToSetup = YES;
    return [self scheduleAlarm];
}

//schedule according to alarms array. If array is empty, schedule according to default template.
- (NSArray *)scheduleAlarm{
    BOOL hasChange = NO;
    
    //get alarms
    NSMutableArray *alarms = [[self alarmsForUser:currentUser] mutableCopy];
    
    //check if need to check
    if (alarms.count==0) {
        if ([EWTaskStore myTasks].count == 0 && !self.alarmNeedToSetup) {
            NSLog(@"Skip check alarm due to 0 tasks exists");
            return nil;
        }
    }
    
    //Fill array with alarm, delete redundency
    NSMutableArray *newAlarms = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
    //check if alarm scheduled are duplicated
    for (EWAlarmItem *a in alarms) {
        
        //check time
        if (!a.time) {
            [self removeAlarm:a];
            NSLog(@"Something wrong with alarm. Deleted. %@",[a.time date2detailDateString]);
            continue;
        }
        
        //get the day alarm represents
        NSInteger i = [a.time weekdayNumber];
        
        //see if that day has alarm already
        if (![newAlarms[i] isEqual:@NO]){
            //remove duplicacy
            NSLog(@"@@@ Duplicated alarm on %@ found. Deleted!", a.time.weekday);
            [self removeAlarm:a];
            hasChange = YES;
            continue;
        }
        
        //check tone
        if (!a.tone) {
            NSLog(@"Tone not set");
            a.tone = currentUser.preference[@"DefaultTone"];
        }
        
        //fill that day to the new alarm array
        newAlarms[i] = a;
        
    }
    
    //remove excess
    for (EWAlarmItem *a in alarms) {
        if (![newAlarms containsObject:a]) {
            NSLog(@"Corruped alarm found and deleted: %@", [a.time date2detailDateString]);
            [self removeAlarm:a];
            hasChange = YES;
        }
    }
    
    //start add alarm if blank
    for (NSInteger i=0; i<newAlarms.count; i++) {
        if ([newAlarms[i] isKindOfClass:[EWAlarmItem class]]) {
            //skip if alarm exists
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
            
            //get time
            a.time = time;//set the time first so we can get the saved time in next line
            NSDictionary *timeDic = [self getSavedAlarmTime:a];
            comp = [cal components: (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit |NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:time];
            comp.hour = [(NSNumber *)timeDic[@"hour"] intValue];
            comp.minute = [(NSNumber *)timeDic[@"minute"] intValue];
            time = [cal dateFromComponents:comp];//set time
            //set alarm time
            a.time = time;
            a.state = YES;
            a.tone = currentUser.preference[@"DefaultTone"];
            //add to temp array
            newAlarms[i] = a;
            hasChange = YES;
        }else{
            [NSException raise:@"Unknown state" format:@"Check weekday: %ld", (long)i];
        }
    }
    
    //save
    if (hasChange) {
        //notification
        NSLog(@"Saving new alarms");
        
        //save all changes
        NSError *err;
        [[EWDataStore currentContext] saveAndWait:&err];
        if (err) {
            [NSException raise:@"Error in saving Alarms" format:@"Error:%@", err.description];
        }
        
        //check
        NSArray *myAlarms = [EWAlarmManager myAlarms];
        NSInteger retry = 3;
        while (myAlarms.count != newAlarms.count && retry >0) {
            myAlarms = [EWAlarmManager myAlarms];
            [NSThread sleepForTimeInterval:0.5];
            retry--;
        }
        
        //notification
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmChangedNotification object:self userInfo:nil];
    }
    
    self.alarmNeedToSetup = NO;
    return newAlarms;
}

#pragma mark - DELETE
- (void)removeAlarm:(EWAlarmItem *)alarm{
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmDeleteNotification object:self userInfo:@{@"alarm": alarm}];
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
    
    //notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmDeleteNotification object:self userInfo:@{@"alarm":alarms}];
    
    //delete
    for (EWAlarmItem *alarm in alarms) {
        [[EWDataStore currentContext] deleteObject:alarm];
    }
    
    //save
    NSError *err;
    [[EWDataStore currentContext] saveAndWait:&err];
}

#pragma mark - CHECK
//- (BOOL)checkAlarms{
//    //YES means alarms are good
//    NSArray *alarms = [self alarmsForUser:currentUser];
//    
//    if (alarms.count == 0) {
//        //need set up later
//        if ([EWTaskStore myTasks].count == 0) {
//            return YES;
//        }
//        return NO;
//    }else if (alarms.count == 7){
//        //need to check into alarms to prevent data corrupt
//        BOOL dataCorrupted = NO;
//        
//        for (EWAlarmItem *a in alarms) {
//            if (!a.time) {
//                dataCorrupted = YES;
//                [self removeAlarm:a];
//                NSLog(@"Something wrong with alarm. Need to reschedule alarm.\n%@",a);
//                break;
//            }
//            if (!a.tone) {
//                NSLog(@"Tone not set");
//                a.tone = currentUser.preference[@"DefaultTone"];
//            }
//        }
//        
//        if (dataCorrupted) {
//            return NO;
//        }else{
//            return YES;
//        }
//        
//        
//    }else{
//        //something wrong
//        NSLog(@"Something wrong with alarms (%lu), need to schedule alarm", (unsigned long)alarms.count);
//        [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
//        //delete all alarms
//        //[self deleteAllAlarms];
//        return NO;
//    }
//}

#pragma mark - Utility
- (NSDictionary *)getSavedAlarmTime:(EWAlarmItem *)alarm{
    NSArray *alarmTimes = [self getSavedAlarmTimes];
    NSInteger wkd = [alarm.time weekdayNumber];
    double number = [(NSNumber *)alarmTimes[wkd] doubleValue];
    NSDictionary *dic = [EWUtil timeFromNumber:number];
    return dic;
}

- (void)setSavedAlarmTime:(EWAlarmItem *)alarm{
    NSMutableArray *alarmTimes = [[self getSavedAlarmTimes] mutableCopy];
    NSInteger wkd = [alarm.time weekdayNumber];
    NSDateComponents *comp = [[NSDateComponents alloc] init];
    NSCalendar *cal = [NSCalendar currentCalendar];
    comp = [cal components: (NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:alarm.time];
    double hour = comp.hour;
    double minute = comp.minute;
    double number = hour + minute/100;
    [alarmTimes setObject:[NSNumber numberWithDouble:number] atIndexedSubscript:wkd];
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

@end
