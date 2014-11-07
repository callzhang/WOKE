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

#pragma mark - response to changes
- (void)setState:(NSNumber *)state {
    [self willChangeValueForKey:EWAlarmAttributes.state];
    [self setPrimitiveState:state];
	//update cached time in person
    [EWPerson updateMyCachedInfoForAlarm:self];
	//update saved time in user defaults
	[self setSavedAlarmTimes];
	//schedule local notification
	if (state.boolValue == YES) {
		//schedule local notif
		[self scheduleNotificationForTask:t];
	} else {
		//cancel local notif
		[self cancelNotificationForTask:t];
	}
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


#pragma mark - Tools
//update saved time in user defaults
- (void)setSavedAlarmTimes{
	NSInteger wkd = [self.time weekdayNumber];
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSDateComponents *comp = [cal components: (NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self.time];
	double hour = comp.hour;
	double minute = comp.minute;
	double number = round(hour*100 + minute)/100.0;
	[alarmTimes setObject:[NSNumber numberWithDouble:number] atIndexedSubscript:wkd];
	[[NSUserDefaults standardUserDefaults] setObject:alarmTimes.copy forKey:kSavedAlarms];

}

//Get saved time in user defaults
+ (NSArray *)getSavedAlarmTimes{
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

#pragma mark - Local Notification
- (void)scheduleNotification{
	//check state
	if (task.state == NO) {
		[self cancelNotification];
		return;
	}
	
	//check existing
	NSMutableArray *notifications = [[self localNotificationForTask:task] mutableCopy];
	
	//check missing
	for (unsigned i=0; i<nLocalNotifPerTask; i++) {
		//get time
		NSDate *time_i = [task.time dateByAddingTimeInterval: i * 60];
		BOOL foundMatchingLocalNotif = NO;
		for (UILocalNotification *notification in notifications) {
			if ([time_i isEqualToDate:notification.fireDate]) {
				//found matching notification
				foundMatchingLocalNotif = YES;
				[notifications removeObject:notification];
				break;
			}
		}
		if (!foundMatchingLocalNotif) {
			
			//make task objectID perminent
			if (task.objectID.isTemporaryID) {
				[task.managedObjectContext obtainPermanentIDsForObjects:@[task] error:NULL];
			}
			//schedule
			UILocalNotification *localNotif = [[UILocalNotification alloc] init];
			EWAlarm *alarm = task.alarm;
			//set fire time
			localNotif.fireDate = time_i;
			localNotif.timeZone = [NSTimeZone systemTimeZone];
			if (alarm.statement) {
				localNotif.alertBody = [NSString stringWithFormat:LOCALSTR(alarm.statement)];
			}else{
				localNotif.alertBody = @"It's time to get up!";
			}
			
			localNotif.alertAction = LOCALSTR(@"Get up!");//TODO
			localNotif.soundName = alarm.tone;
			localNotif.applicationIconBadgeNumber = i+1;
			
			//======= user information passed to app delegate =======
			localNotif.userInfo = @{kLocalTaskKey: task.objectID.URIRepresentation.absoluteString,
									kLocalNotificationTypeKey: kLocalNotificationTypeAlarmTimer};
			//=======================================================
			
			if (i == nWeeksToScheduleTask - 1) {
				//if this is the last one, schedule to be repeat
				localNotif.repeatInterval = NSWeekCalendarUnit;
			}
			
			[[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
			NSLog(@"Local Notif scheduled at %@", localNotif.fireDate.date2detailDateString);
		}
	}
	
	//delete remaining alarm timer
	for (UILocalNotification *ln in notifications) {
		if ([ln.userInfo[kLocalNotificationTypeKey] isEqualToString:kLocalNotificationTypeAlarmTimer]) {
			
			NSLog(@"Unmatched alarm notification deleted (%@) ", ln.fireDate.date2detailDateString);
			[[UIApplication sharedApplication] cancelLocalNotification:ln];
		}
		
	}
	
	//schedule sleep timer
	[EWTaskManager scheduleSleepNotificationForTask:task];
	
}


@end
