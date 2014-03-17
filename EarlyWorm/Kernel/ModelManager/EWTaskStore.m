 //
//  EWTaskStore.m
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWTaskStore.h"
#import "EWPerson.h"
#import "EWMediaStore.h"
#import "EWTaskItem.h"
#import "EWAlarmItem.h"
#import "EWAlarmManager.h"
#import "NSDate+Extend.h"
#import "StackMob.h"
#import "EWDataStore.h"

@implementation EWTaskStore
//@synthesize context, model;
@synthesize allTasks = _allTasks;
//@synthesize context;

+(EWTaskStore *)sharedInstance{
    static EWTaskStore *sharedTaskStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTaskStore_ = [[EWTaskStore alloc] init];
        //Watch allAlarm change
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(updateTaskTime:) name:kAlarmTimeChangedNotification object:nil];
        //watch alarm state change
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(updateTaskState:) name:kAlarmStateChangedNotification object:nil];
        //watch tone change
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(updateNotifTone:) name:kAlarmToneChangedNotification object:nil];
        //watch for new alarm
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(scheduleTasks) name:kAlarmsAllNewNotification object:nil];
        //watch media change
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(updateTaskMedia:) name:kMediaNewNotification object:nil];
        //watch alarm deletion
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(alarmRemoved:) name:kAlarmDeleteNotification object:nil];
    });
    return sharedTaskStore_;
}

- (id)init{
    self = [super init];
    if (self) {
        NSLog(@"scheduled timely task checking");
        [NSTimer timerWithTimeInterval:600 target:self selector:@selector(scheduleTasks) userInfo:nil repeats:YES];
    }
    return self;
}

#pragma mark - SETTER & GETTER
- (NSArray *)allTasks{

    //get from relationship
    if (currentUser.tasks.count != 0 &&currentUser.tasks.count !=  7 * nWeeksToScheduleTask) {
        NSLog(@"Something wrong with local data of tasks on current user, start fetch from server");
        _allTasks = [[self getTasksByPerson:currentUser] mutableCopy];
        NSLog(@"After fetch, server returned %d tasks, current user has %d tasks.", _allTasks.count, currentUser.tasks.count);
    }else{
        _allTasks = [[currentUser.tasks allObjects] mutableCopy];
    }
    
    //sort
    @try {
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
        [_allTasks sortUsingDescriptors:@[sort]];
    }
    @catch (NSException *exception) {
        _allTasks = [[_allTasks sortedArrayUsingComparator:^NSComparisonResult(EWTaskItem *obj1, EWTaskItem *obj2) {
            NSInteger d1 = [obj1.time timeIntervalSince1970];
            NSInteger d2 = [obj2.time timeIntervalSince1970];
            if (d1 > d2) {
                return NSOrderedDescending;
            }else{
                return NSOrderedAscending;
            }
        }] mutableCopy];
    }
    
    
    
    return _allTasks;
}


#pragma mark - SEARCH
- (NSArray *)getTasksByPerson:(EWPerson *)person{
    NSArray *tasks = [[NSArray alloc] init];
    if (person.tasks.count == 7 * nWeeksToScheduleTask) {
        tasks = [person.tasks allObjects];
    }else{
        //this usually not happen
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWTaskItem"];
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"owner == %@", currentUser];
        //NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"time >= %@", [NSDate date]];
        //request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
        request.predicate = predicate1;
        tasks = [context executeFetchRequestAndWait:request error:NULL];
        //save to person
        if (tasks.count > 0) {
            person.tasks = [NSSet setWithArray:tasks];
        }
        
    }
    //sort
    tasks = [tasks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
    
    return tasks;
}

- (NSArray *)pastTasksByPerson:(EWPerson *)person{
    NSArray *tasks = [[NSArray alloc] init];
    if (![lastChecked isOutDated] && person.tasks) {
        tasks = [person.pastTasks allObjects];
    }else{
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWTaskItem"];
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"owner == %@", currentUser];
        NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"time < %@", [NSDate date]];
        NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"state == %@", @YES];
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2, predicate3]];
        //request.sortDescriptors = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES];
        tasks = [context executeFetchRequestAndWait:request error:NULL];
        //save to person
        person.pastTasks = [NSSet setWithArray:tasks];
    }
    //sort
    tasks = [tasks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
    
    return tasks;
}

//for auto group
- (EWTaskItem *)nextTaskAtDayCount:(NSInteger)n ForPerson:(EWPerson *)person{
    NSArray *tasks = [self getTasksByPerson:person];
    if (tasks.count >= n+1) {
        return tasks[n];
    }
    return nil;
    
}

- (EWTaskItem *)getTaskByID:(NSString *)taskID{
    if (!taskID) return nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EWTaskItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"ewtaskitem_id == %@", taskID];
    NSError *err;
    NSArray *tasks = [[EWDataStore sharedInstance].currentContext executeFetchRequestAndWait:request error:&err];
    if (tasks.count != 1) NSLog(@"Error getting task from ID: %@. Error: %@", taskID, err.description);
    return tasks[0];
}


#pragma mark - SCHEDULE
//schedule new task in the future
- (NSArray *)scheduleTasks{
    NSLog(@"Start scheduling tasks");
    //forfeit if no alarm scheduled
    if (EWAlarmManager.sharedInstance.allAlarms.count == 0 && _allTasks.count == 0) {
        return nil;
    }
    NSMutableArray *tasks = _allTasks;
    //need to schedule tasks
    NSDate *lastTime;
    if (tasks.count == 0) {
        lastTime = [NSDate date];
        tasks = [[NSMutableArray alloc] init];
    } else {
        tasks = [[tasks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]] mutableCopy];
        EWTaskItem *lastTask = [tasks lastObject];
        lastTime = lastTask.time;
    }
    //for each alarm, find matching task, or create new task
    BOOL newTaskNotify = NO;
    NSArray *alarms = [[NSArray alloc] initWithArray:EWAlarmManager.sharedInstance.allAlarms];
    for (EWAlarmItem *a in alarms){
        for (unsigned i=0; i<nWeeksToScheduleTask; i++) {//loop for week
            NSDate *time = [a.time nextOccurTime:i];//next time for alarm
            if ([lastTime isEarlierThan:time]) {//if last task is out dated
                //new task
                EWTaskItem *t = [self newTask];
                t.time = time;
                t.alarm = a;
                t.owner = a.owner;
                t.state = a.state;
                [tasks addObject:t];
                //localNotif
                [self scheduleNotificationForTask:t];
                //prepare to broadcast
                newTaskNotify = YES;
                
                //check receiprocal relationship
                if (![a.tasks containsObject:t]) {
                    [context refreshObject:a mergeChanges:YES];
                    NSLog(@"====Alarm->Task relation was not fetched. After refresh, alarm has %d tasks=====", a.tasks.count);
                }
            }
        }
    }
    if (newTaskNotify) {
        //notification of new task (to interface)
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskNewNotification object:nil userInfo:nil];
        });
        
    }
    
    
    //nullify old task's relation to alarm
    /*
    NSPredicate *old = [NSPredicate predicateWithFormat:@"time < %@", [NSDate date]];
    NSArray *outDatedTasks = [_allTasks filteredArrayUsingPredicate:old];
    for (EWTaskItem *t in outDatedTasks) {
        t.alarm = NULL;
    }*/
    
    //save to _allTasks
    _allTasks = tasks;
    
    //save
    [context saveOnSuccess:^{
        //NSLog(@"Scheduled new tasks");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Unable to save new tasks" format:@"Error:%@", error.description];
    }];
    
    //last checked
    lastChecked = [NSDate date];
    return tasks;
}

#pragma mark - NEW
- (EWTaskItem *)newTask{
    
    EWTaskItem *t = [NSEntityDescription insertNewObjectForEntityForName:@"EWTaskItem" inManagedObjectContext:context];
    //assign id
    [t assignObjectId];
    //relation
    t.owner = currentUser;
    //others
    t.added = [NSDate date];
    //save
    [context saveOnSuccess:^{
        //NSLog(@"New task saved");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Failed in creating task" format:@"error: %@",error.description];
    }];
    NSLog(@"Created new Task");
    return t;
}

#pragma mark - KVO & NOTIFICATION
/*
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[EWAlarmItem class]]) {
        if ([keyPath isEqualToString:@"state"]) {
            [self updateTaskStateForAlarm:object];
        }else if ([keyPath isEqualToString:@"time"]){
            [self updateTaskTimeForAlarm:object];
        }
    }
}*/

- (void)updateTaskState:(NSNotification *)notif{
    EWAlarmItem *a = notif.userInfo[@"alarm"];
    if (!a) [NSException raise:@"No alarm info" format:@"Check notification"];
    [self updateTaskStateForAlarm:a];
}

- (void)updateTaskStateForAlarm:(EWAlarmItem *)a{
    BOOL updated = NO;
    for (EWTaskItem *t in a.tasks) {
        if (t.state != a.state) {
            updated = YES;
            
            t.state = a.state;
            
            if ([t.state isEqual:@YES]) {
                //schedule local notif
                [self scheduleNotificationForTask:t];
            } else {
                //cancel local notif
                [self cancelNotificationForTask:t];
            }
            
            //notification
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskStateChangedNotification object:t userInfo:@{@"task": t}];
        }
    }
    if (updated) {
        [context saveOnSuccess:^{
            NSArray *wd = weekdays;
            NSLog(@"Updated alarm's state on %@", wd[a.time.weekdayNumber]);
        } onFailure:^(NSError *error) {
            [NSException raise:@"Task update failed" format:@"Reason: %@", error.description];
        }];
    }
}

- (void)updateTaskTime:(NSNotification *)notif{
    EWAlarmItem *a = notif.userInfo[@"alarm"];
    if (!a) [NSException raise:@"No alarm info" format:@"Check notification"];
    [self updateTaskTimeForAlarm:a];
}

- (void)updateTaskTimeForAlarm:(EWAlarmItem *)a{
    if (!a.tasks.count) {
        [context refreshObject:a mergeChanges:YES];
        NSLog(@"Alarm's tasks not fetched, refresh from server. New tasks relation has %d tasks", a.tasks.count);
    }
    NSSortDescriptor *des = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
    NSArray *sortedTasks = [a.tasks sortedArrayUsingDescriptors:@[des]];
    for (unsigned i=0; i<nWeeksToScheduleTask; i++) {
        EWTaskItem *t = sortedTasks[i];
        NSDate *nextTime = [a.time nextOccurTime:i];
        if (![t.time isEqual:nextTime]) {
            t.time = nextTime;
            //local notif
            [self cancelNotificationForTask:t];
            [self scheduleNotificationForTask:t];
            //Notification
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskChangedNotification object:t userInfo:@{@"task": t}];
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskTimeChangedNotification object:t userInfo:@{@"task": t}];
            
        }
    }
    [context saveOnSuccess:^{
        NSLog(@"Task time updated");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Task time update error" format:@"Reason: %@", error.description];
    }];
}

- (void)updateNotifTone:(NSNotification *)notif{
    EWAlarmItem *a = notif.userInfo[@"alarm"];
    
    if (!a.tasks.count){
        NSLog(@"alarm's task not fetched, refresh it from server");
        [context refreshObject:a mergeChanges:YES];
    }
    
    for (EWTaskItem *t in a.tasks) {
        [self cancelNotificationForTask:t];
        [self scheduleNotificationForTask:t];
        NSLog(@"Notification on %@ tone updated to: %@", t.time.date2String, a.tone);
    }
}

- (void)updateTaskMedia:(NSNotification *)notif{
    EWTaskItem *task = [notif object];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [context refreshObject:task mergeChanges:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:kTaskChangedNotification object:self userInfo:@{@"task": task}];
    });
}

- (void)alarmRemoved:(NSNotification *)notif{
    NSLog(@"Delete task due to alarm deleted");
    NSArray *tasks = notif.userInfo[@"tasks"];
    for (EWTaskItem *t in tasks) {
        [context deleteObject:t];
    }
    [context saveOnSuccess:^{
        NSLog(@"Task removed due to alarm deleted");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error in deleting task after alarm deleted" format:@"Error: %@", error.description];
    }];
}

/* add task by alarm, this function is replaced by scheduleTask
- (void)alarmAdded:(NSNotification *)notif{
    EWAlarmItem *alarm = notif.userInfo[@"alarm"];
    NSLog(@"Add task for alarm %@", [alarm.time date2detailDateString]);
    for (NSInteger i=0; i<nWeeksToScheduleTask; i++) {
        EWTaskItem *task = [self newTask];
        
    }
}*/

#pragma mark - DELETE
- (void)removeTask:(EWTaskItem *)task{
    [self cancelNotificationForTask:task];
    [context deleteObject:task];
    [context saveOnSuccess:^{
        NSLog(@"Task deleted");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Task deletion error" format:@"Reason: %@", error.description];
    }];
}

- (void)deleteAllTasks{
    for (EWTaskItem *t in self.allTasks) {
        [self cancelNotificationForTask:t];
        [context deleteObject:t];
    }
    //save
    [context saveOnSuccess:^{
        NSLog(@"All tasks has been purged");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Unable to delete all tasks" format:@"Reason: %@", error.description];
    }];
}

#pragma mark - Local Notification
- (void)scheduleNotificationForTask:(EWTaskItem *)task{
    //check state
    if ([task.state  isEqual: @NO]) {
        return;
    }
    //check existing
    for(UILocalNotification *aNotif in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if ([aNotif.userInfo[kLocalNotificationUserInfoKey] isEqualToString: task.ewtaskitem_id]) {
            NSLog(@"Task %@ already scheduled local notification", task.ewtaskitem_id);
            return;
        }
    }
    //schedule
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    NSDate *time = task.time;
    EWAlarmItem *alarm = task.alarm;
    //set fire time
    localNotif.fireDate = time;
    localNotif.timeZone = [NSTimeZone defaultTimeZone];
    if (alarm.alarmDescription) {
        localNotif.alertBody = [NSString stringWithFormat:LOCALSTR(alarm.alarmDescription)];
    }else{
        localNotif.alertBody = @"It's time to get up!";
    }
    
    localNotif.alertAction = LOCALSTR(@"Get up!");//TODO
    localNotif.soundName = alarm.tone;
    localNotif.applicationIconBadgeNumber = 1;
    //user information passed to app delegate
    localNotif.userInfo = @{kLocalNotificationUserInfoKey: task.ewtaskitem_id};
    if (nWeeksToScheduleTask == 1) {
        localNotif.repeatInterval = NSWeekCalendarUnit; //TODO: if last one
    }
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    
    //local time
    NSLog(@"Local notification scheduled at %@", localNotif.fireDate);
}

- (void)cancelNotificationForTask:(EWTaskItem *)task{
    for(UILocalNotification *aNotif in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if([aNotif.userInfo[kLocalNotificationUserInfoKey] isEqualToString:task.ewtaskitem_id]) {
            NSLog(@"Local Notification cancelled for weekday: %d", [aNotif.fireDate weekdayNumber]);
            [[UIApplication sharedApplication] cancelLocalNotification:aNotif];
            return;
        }
    }
    NSLog(@"No local notification found matching task id: %@", task.ewtaskitem_id);
}

#pragma mark - check
- (BOOL)checkTasks{
    //time stemp for last check
    lastChecked = [NSDate date];
    NSLog(@"Checking tasks");
    NSMutableArray *tasks = [[self getTasksByPerson:currentUser] mutableCopy];

    
    //check if any task has past
    NSDate *time = [[NSDate date] timeByAddingMinutes:-120];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"time < %@", time];
    NSArray *pastTasks = [tasks filteredArrayUsingPredicate:predicate];
    if (pastTasks.count > 0) {
        //change task relationship
        if ([currentUser isFault]) {
            [context refreshObject:currentUser mergeChanges:YES];
            NSLog(@"fetched user info from server");
        }
        for (EWTaskItem *t in pastTasks) {
            t.owner = nil;
            t.pastOwner = currentUser;
            t.alarm = nil;
            [tasks removeObject:t];
            NSLog(@"Task %@ has been moved to past tasks", [t.time date2detailDateString]);
        }
        //[self scheduleTasks];
        //return NO;
        [context saveOnSuccess:^{
            //
        } onFailure:^(NSError *error) {
            //
        }];
    }
    
    
    if(tasks.count == 0){
        //initial state
        NSLog(@"Task has not been setup yet");
        if (currentUser.alarms.count == 0) return YES;
        return NO;
    }else if (tasks.count >  7 * nWeeksToScheduleTask) {
        NSLog(@"Something is wrong with scheduled task: excessive tasks(%d), please check.", tasks.count);
        
        [self deleteAllTasks];
        return NO;
    }
    
    //check orphan
    for (EWTaskItem *t in tasks) {
        if (!t.alarm) {
            NSLog(@"Something wrong with tasks");
            [self deleteAllTasks];
            return NO;
        }
    }
    
    if (tasks.count == currentUser.alarms.count * nWeeksToScheduleTask) {
        return YES;
    }
    
    NSLog(@"#### task is between 1 ~ 7n ####");
    
    return NO;
}


- (void)checkScheduledNotifications{
    NSInteger nNotification = [[[UIApplication sharedApplication] scheduledLocalNotifications] count];
    NSInteger nTask = self.allTasks.count;
    NSLog(@"There are %d scheduled local notification and %d stored task info", nNotification, nTask);
    //delete redundant alarm notif
    for(UILocalNotification *aNotif in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        BOOL del = YES;
        for (EWTaskItem *t in _allTasks) {
            if([aNotif.userInfo[kLocalNotificationUserInfoKey] isEqualToString:t.ewtaskitem_id] && [aNotif.fireDate isEqualToDate:t.time]){
                del=NO;
                break;
            }
        }
        if (del) {
            NSLog(@"========Local Notification on %@ will be deleted due to no paired stored info========", aNotif.fireDate.weekday);
            [[UIApplication sharedApplication] cancelLocalNotification:aNotif];
        }
    }
    //schedule necessary alarm notif
    for (EWTaskItem *t in _allTasks) {
        BOOL createNotif = YES;
        //stop if task not on
        if ([t.state  isEqual: @NO]) {
            createNotif = NO;
            //break;
        }else{
            //stop if matching notif is found
            for (UILocalNotification *aNotif in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
                if ([[aNotif.userInfo objectForKey:kLocalNotificationUserInfoKey] isEqualToString:t.ewtaskitem_id]) {
                    //NSLog(@"Found matching notif:%@ for task:%@", aNotif.userInfo[kLocalNotificationUserInfoKey], t.ewtaskitem_id);
                    //found matching notif
                    if ([aNotif.fireDate isEqualToDate:t.time]) {
                        //indeed matching
                        createNotif = NO;
                        break;
                    }else{
                        //something wrong, need reschedule notif
                        [self cancelNotificationForTask:t];
                        break;
                    }
                    
                }
            }
            
            if (createNotif) {
                NSLog(@"No notification found for task at weekday:%d", [t.time weekdayNumber]);
                [self scheduleNotificationForTask:t];
            }

        }
        
    }
    
    //if no alarm, ask for schedule
}

@end
