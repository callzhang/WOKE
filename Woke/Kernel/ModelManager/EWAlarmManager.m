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
#import "EWAlarm.h"
#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWUserManagement.h"
#import "EWAppDelegate.h"
#import "EWAlarmScheduleViewController.h"

@implementation EWAlarmManager

+ (EWAlarmManager *)sharedInstance {
    //make sure core data stuff is always on main thread
    //NSParameterAssert([NSThread isMainThread]);
    static EWAlarmManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWAlarmManager alloc] init];
    }); 
    
    return manager;
}


#pragma mark - SEARCH
- (NSDate *)nextAlarmTimeForPerson:(EWPerson *)person{
    NSDate *nextTime;
    //first try to get it from cache
    NSDictionary *times = person.cachedInfo[kCachedAlarmTimes];
    if (!times && person.isMe) {
        [self updateCachedAlarmTimes];
    }
    
    for (NSDate *time in times.allValues) {
        NSDate *t = [time nextOccurTime:0];
        if (!nextTime || [t isEarlierThan:nextTime]) {
            nextTime = t;
        }
    }
    return nextTime;
}

- (NSString *)nextStatementForPerson:(EWPerson *)person{
    //first try to get it from cache
    NSDictionary *statements = person.cachedInfo[kCachedStatements];
    NSDictionary *times = person.cachedInfo[kCachedAlarmTimes];
    if (!statements && person.isMe) {
        [self updateCachedStatements];
    }
    if (!times && person.isMe) {
        [self updateCachedAlarmTimes];
    }
    
    __block NSString *nextWeekday;
    NSDate *nextTime;
    [times enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDate *time, BOOL *stop) {
        NSDate *t = [time nextOccurTime:0];
        if (!nextTime || [t isEarlierThan:nextTime]) {
            nextWeekday = key;
        }
    }];
    NSString *nextStatement = statements[nextWeekday];
    return nextStatement?:@"";
}

#pragma mark - SCHEDULE
//schedule according to alarms array. If array is empty, schedule according to default template.
- (NSArray *)scheduleAlarm{
    NSParameterAssert([NSThread isMainThread]);
    if ([EWSession sharedSession].isSchedulingAlarm) {
        DDLogVerbose(@"Skip scheduling alarm because it is scheduling already!");
        return nil;
    }
    [EWSession sharedSession].isSchedulingAlarm = YES;
    
    //get alarms
    NSMutableArray *alarms = [[EWPerson myAlarms] mutableCopy];
    
    
    BOOL hasChange = NO;
    
    //check from server for alarm with owner but lost relation
    if (alarms.count != 7 && [EWSync isReachable]) {
        //cannot check alarm for myself, which will cause a checking/schedule cycle
        
        DDLogVerbose(@"Alarm for me is less than 7, fetch from server!");
        PFQuery *alarmQuery = [PFQuery queryWithClassName:NSStringFromClass([EWAlarm class])];
        [alarmQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
        [alarmQuery whereKey:kParseObjectID notContainedIn:[alarms valueForKey:kParseObjectID]];
        NSArray *objects = [EWSync findServerObjectWithQuery:alarmQuery error:NULL];
        
        for (PFObject *a in objects) {
            EWAlarm *alarm = (EWAlarm *)[a managedObjectInContext:mainContext];;
            [alarm refresh];
            alarm.owner = [EWSession sharedSession].currentUser;
            if (![alarm validate]) {
                [alarm remove];
            }else if (![alarms containsObject:alarm]) {
                [alarms addObject:alarm];
                hasChange = YES;
                DDLogVerbose(@"Alarm found from server %@", alarm);
            }
        }
    }
    
    //Fill array with alarm, delete redundency
    NSMutableArray *newAlarms = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
    //check if alarm scheduled are duplicated
    for (EWAlarm *a in alarms) {
        
        //get the day alarm represents
        NSInteger i = [a.time weekdayNumber];
        
        //see if that day has alarm already
        if (![newAlarms[i] isEqual:@NO]){
            //remove duplicacy
            DDLogVerbose(@"@@@ Duplicated alarm found. Delete! %@", a.time.date2detailDateString);
            [a deleteEntity];
            hasChange = YES;
            continue;
        }else if (![a validate]){
            DDLogVerbose(@"%s Something wrong with alarm(%@) Delete!", __func__, a.objectId);
            continue;
        }
        
        
        //fill that day to the new alarm array
        newAlarms[i] = a;
    }
    
    //remove excess
    [alarms removeObjectsInArray:newAlarms];
    for (EWAlarm *a in alarms) {
        DDLogError(@"Corruped alarm found and deleted: %@", a.serverID);
        [a remove];
        hasChange = YES;
    }
    
    //start add alarm if blank
    for (NSInteger i=0; i<newAlarms.count; i++) {
        if (![newAlarms[i] isEqual:@NO]) {
            //skip if alarm exists
            continue;
        }
    
        DDLogVerbose(@"Alarm for weekday %ld missing, start add alarm", (long)i);
        EWAlarm *a = [EWAlarm newAlarm];
        
        //get time
        NSDate *time = [self getSavedAlarmTimeOnWeekday:i];
        //set alarm time
        a.time = time;
        //add to temp array
        newAlarms[i] = a;
        hasChange = YES;
        
    }
    
    //save
    if (hasChange) {
        //notification
        DDLogVerbose(@"Saving new alarms");
        [EWSync save];
        
        //notification
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //delay here to make sure the thread don't compete at the same time
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmChanged object:self userInfo:nil];
        });
        
    }
    
    [EWSession sharedSession].isSchedulingAlarm = NO;
    
    return newAlarms;
}

#pragma mark - Get/Set alarm to UserDefaults
- (NSDate *)getSavedAlarmTimeOnWeekday:(NSInteger)targetDay{
    //set weekday
    NSDate *today = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];//TIMEZONE
    NSDateComponents *comp = [NSDateComponents new];//used as a dic to hold time diff
    comp.day = targetDay - today.weekdayNumber;
    NSDate *time = [cal dateByAddingComponents:comp toDate:today options:0];//set the weekday
    comp = [cal components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:time];//get the target date
    NSArray *alarmTimes = [self getSavedAlarmTimes];
    double number = [(NSNumber *)alarmTimes[targetDay] doubleValue];
    NSInteger hour = floor(number);
    NSInteger minute = round((number - hour)*100);
    comp.hour = hour;
    comp.minute = minute;
    time = [cal dateFromComponents:comp];
    DDLogVerbose(@"Get saved alarm time %@", time);
    return time;
}



//Get saved time in user defaults
- (NSArray *)getSavedAlarmTimes{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *alarmTimes = [defaults valueForKey:kSavedAlarms];
    //create if not exsit
    if (!alarmTimes) {
        //if asking saved value, the alarm is not scheduled
        DDLogInfo(@"=== Saved alarm time not found, use default values!");
        alarmTimes = defaultAlarmTimes;
        [defaults setObject:alarmTimes forKey:kSavedAlarms];
        [defaults synchronize];
    }
    return alarmTimes;
}



#pragma mark - Alarm timer local notofication
- (void)checkScheduledLocalNotifications{
	NSParameterAssert([NSThread isMainThread]);
	NSMutableArray *allNotification = [[[UIApplication sharedApplication] scheduledLocalNotifications] mutableCopy];
	NSLog(@"There are %ld scheduled local notification", (long)allNotification.count);
	
	//delete redundant alarm notif
	for (EWAlarm *alarm in [EWSession sharedSession].currentUser.alarms) {
		[alarm scheduleTimerAndSleepLocalNotification];
		NSArray *notifs= [alarm localNotifications];
		[allNotification removeObjectsInArray:notifs];
	}
	
	for (UILocalNotification *aNotif in allNotification) {
		
		NSLog(@"===== Deleted %@ (%@) =====", aNotif.userInfo[kLocalNotificationTypeKey], aNotif.fireDate.date2detailDateString);
		[[UIApplication sharedApplication] cancelLocalNotification:aNotif];
		
	}
	
	if (allNotification.count > 0) {
		//make sure the redundent notif didn't prevent scheduling of new notification
		[self checkScheduledLocalNotifications];
	}
	
}

@end
