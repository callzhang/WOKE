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
    BOOL mainThread = [NSThread isMainThread];
    if (!mainThread) {
        NSLog(@"**** Task Store not on main thread ****");
    }
    
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
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(updateTaskMedia:) name:kNewMediaNotification object:nil];
        //watch alarm deletion
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(alarmRemoved:) name:kAlarmDeleteNotification object:nil];
        //task state change
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(updateTaskState:) name:kTaskStateChangedNotification object:nil];
    });
    return sharedTaskStore_;
}

- (id)init{
    self = [super init];
    if (self) {
        //NSLog(@"scheduled timely task checking");
        //[NSTimer timerWithTimeInterval:600 target:self selector:@selector(scheduleTasks) userInfo:nil repeats:YES];
    }
    return self;
}

#pragma mark - SETTER & GETTER
- (NSArray *)allTasks{

    //get from relationship
    _allTasks = [self getTasksByPerson:currentUser];
    
    
    return _allTasks;
}

- (void)setAllTasks:(NSMutableArray *)allTasks{
    NSLog(@"**** Please do not explicitly save all tasks to local ****");
}


#pragma mark - SEARCH
- (NSArray *)getTasksByPerson:(EWPerson *)person{
    NSArray *tasks = [person.tasks allObjects];
    BOOL fetch = YES;
    
    //check if person is outdated or task count is wrong
    if (![person.lastmoddate isOutDated]) {
        
        if (tasks.count == 7 * nWeeksToScheduleTask) {
            fetch = NO;
        }
    }
    
    if (fetch) {
        //this usually not happen
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWTaskItem"];
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"owner == %@", person];
        //NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"time >= %@", [NSDate date]];
        //request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
        request.predicate = predicate1;
        
        if (![NSThread isMainThread]) NSLog(@"**** Fetch on other thread");
        
        tasks = [[EWDataStore currentContext] executeFetchRequestAndWait:request error:NULL];
        Cannot retrieve referenceObject from an objectID that was not created by this store
    }
    //sort
    [tasks valueForKey:@"time"];
    tasks = [tasks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
    
    return tasks;
}

- (NSArray *)pastTasksByPerson:(EWPerson *)person{
    NSArray *tasks = [[NSArray alloc] init];
    if (![[EWDataStore sharedInstance].lastChecked isOutDated] && person.tasks) {
        tasks = [person.pastTasks allObjects];
    }else{
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWTaskItem"];
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"owner == %@", currentUser];
        NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"time < %@", [NSDate date]];
        NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"state == %@", @YES];
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2, predicate3]];
        //request.sortDescriptors = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES];
        tasks = [[EWDataStore currentContext] executeFetchRequestAndWait:request error:NULL];
        //save to person
        person.pastTasks = [NSSet setWithArray:tasks];
    }
    //sort
    tasks = [tasks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
    
    return tasks;
}

//for auto group
- (EWTaskItem *)nextTaskForPerson:(EWPerson *)person{
    return [self nextTaskAtDayCount:0 ForPerson:person];
}

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
    NSArray *tasks = [EWDataStore.currentContext executeFetchRequestAndWait:request error:&err];
    if (tasks.count != 1) {
        NSLog(@"Error getting task from ID: %@. Error: %@", taskID, err.description);
        return nil;
    }
    return tasks[0];
}


#pragma mark - SCHEDULE
//schedule new task in the future
- (NSArray *)scheduleTasks{
    NSLog(@"Start scheduling tasks");
    
    //check necessity
    NSMutableArray *tasks = [self.allTasks mutableCopy];
    if (EWAlarmManager.sharedInstance.allAlarms.count == 0 && tasks.count == 0) {
        NSLog(@"Forfeit sccheduling task due to no alarm and task exists");
        return nil;
    }
    
    //for each alarm, find matching task, or create new task
    BOOL newTaskNotify = NO;
    NSArray *alarms = [[NSArray alloc] initWithArray:EWAlarmManager.sharedInstance.allAlarms];
    NSMutableArray *goodTasks = [[NSMutableArray alloc] init];
    
    for (EWAlarmItem *a in alarms){//loop through alarms
        
        for (unsigned i=0; i<nWeeksToScheduleTask; i++) {//loop for week
            
            //next time for alarm, this is what the time should be there
            NSDate *time = [a.time nextOccurTime:i];
            
            //loop through the tasks to verify the target time has been scheduled
            for (EWTaskItem *t in tasks) {
                if ([t.time isEqualToDate:time]) {
                    //find the task, move to good task
                    [goodTasks addObject:t];
                    [tasks removeObject:t];
                    //break here to avoid creating new task
                    break;
                }
            }
            
            //start scheduling task
            NSLog(@"Task with time: %@ has not been found, creating!", time);
            //new task
            EWTaskItem *t = [self newTask];
            t.time = time;
            t.alarm = a;
            t.owner = a.owner;
            t.state = a.state;
            [goodTasks addObject:t];
            //localNotif
            [self scheduleNotificationForTask:t];
            //prepare to broadcast
            newTaskNotify = YES;
        }
    }
    if (newTaskNotify) {
        //notification of new task (to interface)
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskNewNotification object:nil userInfo:nil];
        });
        
    }
    
    
    //nullify old task's relation to alarm
    
    NSPredicate *old = [NSPredicate predicateWithFormat:@"time < %@", [NSDate date]];
    NSArray *outDatedTasks = [tasks filteredArrayUsingPredicate:old];
    for (EWTaskItem *t in outDatedTasks) {
        t.alarm = NULL;
        t.pastOwner = currentUser;
        
    }
    
    //save to _allTasks
    _allTasks = tasks;
    
    //save
    [[EWDataStore currentContext] saveOnSuccess:^{
        //NSLog(@"Scheduled new tasks");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Unable to save new tasks" format:@"Error:%@", error.description];
    }];
    
    //last checked
    [EWDataStore sharedInstance].lastChecked = [NSDate date];
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
    [[EWDataStore currentContext] saveOnSuccess:^{
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
    id alarm = notif.userInfo[@"alarm"];
    id task = notif.userInfo[@"task"];
    if([alarm isKindOfClass:[EWAlarmItem class]]){
        [self updateTaskStateForAlarm:(EWAlarmItem *)alarm];
    }else if([task isKindOfClass:[EWTaskItem class]]){
        [self scheduleNotificationForTask:(EWTaskItem *)task];
    }else{
        [NSException raise:@"No alarm/task info" format:@"Check notification"];
    }
    
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
        [[EWDataStore currentContext] saveOnSuccess:^{
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
        //[a.managedObjectContext refreshObject:a mergeChanges:YES];
        [EWDataStore refreshObjectWithServer:a];
        NSLog(@"Alarm's tasks not fetched, refresh from server. New tasks relation has %lu tasks", (unsigned long)a.tasks.count);
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
            //[[NSNotificationCenter defaultCenter] postNotificationName:kTaskChangedNotification object:t userInfo:@{@"task": t}];
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskTimeChangedNotification object:t userInfo:@{@"task": t}];
            
        }
    }
    [[EWDataStore currentContext] saveOnSuccess:^{
        NSLog(@"Task time updated");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Task time update error" format:@"Reason: %@", error.description];
    }];
}

- (void)updateNotifTone:(NSNotification *)notif{
    EWAlarmItem *a = notif.userInfo[@"alarm"];
    
    if (!a.tasks.count){
        NSLog(@"alarm's task not fetched, refresh it from server");
        //[a.managedObjectContext refreshObject:a mergeChanges:YES];
        [EWDataStore refreshObjectWithServer:a];
    }
    
    for (EWTaskItem *t in a.tasks) {
        [self cancelNotificationForTask:t];
        [self scheduleNotificationForTask:t];
        NSLog(@"Notification on %@ tone updated to: %@", t.time.date2String, a.tone);
    }
}

- (void)updateTaskMedia:(NSNotification *)notif{
    //NSString *mediaID = [notif userInfo][kPushMediaKey];
    NSString *taskID = [notif userInfo][kPushTaskKey];
    if ([taskID isEqualToString:@""]) return;
    EWTaskItem *task = [self getTaskByID:taskID];
    //EWMediaItem *media = [[EWMediaStore sharedInstance] getMediaByID:mediaID];
    //NSAssert([task.medias containsObject:media], @"Media and Task should have relation");
    dispatch_async(dispatch_get_main_queue(), ^{
        //[task.managedObjectContext refreshObject:task mergeChanges:YES];
        [EWDataStore refreshObjectWithServer:task];
        [[NSNotificationCenter defaultCenter] postNotificationName:kTaskChangedNotification object:self userInfo:@{kPushTaskKey: task}];
    });
}

- (void)alarmRemoved:(NSNotification *)notif{
    NSLog(@"Delete task due to alarm deleted");
    NSArray *tasks = notif.userInfo[@"tasks"];
    for (EWTaskItem *t in tasks) {
        [[EWDataStore currentContext] deleteObject:t];
    }
    [[EWDataStore currentContext] saveOnSuccess:^{
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
    [[EWDataStore currentContext] deleteObject:task];
    [[EWDataStore currentContext] saveOnSuccess:^{
        NSLog(@"Task deleted");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Task deletion error" format:@"Reason: %@", error.description];
    }];
}

- (void)deleteAllTasks{
    for (EWTaskItem *t in self.allTasks) {
        [self cancelNotificationForTask:t];
        [[EWDataStore currentContext] deleteObject:t];
    }
    //save
    [[EWDataStore currentContext] saveOnSuccess:^{
        NSLog(@"All tasks has been purged");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Unable to delete all tasks" format:@"Reason: %@", error.description];
    }];
}

#pragma mark - Local Notification
- (void)scheduleNotificationForTask:(EWTaskItem *)task{
    //check state
    if ([task.state  isEqual: @NO]) {
        NSLog(@"Skip checking task (%@) with state: OFF", task.time.weekday);
        return;
    }
    
    //check existing
    NSMutableArray *notifications = [[self localNotificationForTask:task] mutableCopy];
    
    //check missing
    for (unsigned i=0; i<nLocalNotifPerTask; i++) {
        //get time
        NSDate *time_i = [task.time timeByAddingSeconds: i * 30];
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
            //time_i need to be alarmed
            //schedule
            UILocalNotification *localNotif = [[UILocalNotification alloc] init];
            EWAlarmItem *alarm = task.alarm;
            //set fire time
            localNotif.fireDate = time_i;
            localNotif.timeZone = [NSTimeZone systemTimeZone];
            if (alarm.alarmDescription) {
                localNotif.alertBody = [NSString stringWithFormat:LOCALSTR(alarm.alarmDescription)];
            }else{
                localNotif.alertBody = @"It's time to get up!";
            }
            
            localNotif.alertAction = LOCALSTR(@"Get up!");//TODO
            localNotif.soundName = alarm.tone;
            localNotif.applicationIconBadgeNumber = 1;
            //user information passed to app delegate
            localNotif.userInfo = @{kPushTaskKey: task.ewtaskitem_id};
            if (nWeeksToScheduleTask == 1) {
                localNotif.repeatInterval = NSWeekCalendarUnit; //TODO: if last one
            }
            
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
            NSLog(@"Local Notification scheduled at %@", localNotif.fireDate);
        }
    }
    
    //delete remaining
    if (notifications.count > 0) {
        NSLog(@"Remaining tasks (%lu) deleted", (unsigned long)notifications.count);
        for (UILocalNotification *ln in notifications) {
            [[UIApplication sharedApplication] cancelLocalNotification:ln];
        }
    }
    
}

- (void)cancelNotificationForTask:(EWTaskItem *)task{
    NSArray *notifications = [self localNotificationForTask:task];
    for(UILocalNotification *aNotif in notifications) {
        NSLog(@"Local Notification cancelled for:%@", aNotif.fireDate);
        [[UIApplication sharedApplication] cancelLocalNotification:aNotif];
    }
}

- (NSArray *)localNotificationForTask:(EWTaskItem *)task{
    NSMutableArray *notifArray = [[NSMutableArray alloc] init];
    for(UILocalNotification *aNotif in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if([aNotif.userInfo[kPushTaskKey] isEqualToString:task.ewtaskitem_id]) {
            [notifArray addObject:aNotif];
        }
    }
    if (notifArray.count != nLocalNotifPerTask) {
        NSLog(@"**** There is only %u local notifications for task on %@, expecting %d", (unsigned)notifArray.count, task.time.weekday, nLocalNotifPerTask);
    }
    return notifArray;
}


- (void)fireSilentAlarmForTask:(EWTaskItem *)task{
    UILocalNotification *silentAlarm = [[UILocalNotification alloc] init];
    silentAlarm.alertBody = @"It's time to wake up";
    silentAlarm.alertAction = @"Wake up!";
    silentAlarm.userInfo = @{kPushTaskKey: task.ewtaskitem_id};
    [[UIApplication sharedApplication] scheduleLocalNotification:silentAlarm];
}


- (void)checkScheduledNotifications{
    NSInteger nNotification = [[[UIApplication sharedApplication] scheduledLocalNotifications] count];
    NSInteger nTask = self.allTasks.count;
    NSLog(@"There are %ld scheduled local notification and %ld stored task info", (long)nNotification, (long)nTask);
    
    //delete redundant alarm notif
    for(UILocalNotification *aNotif in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        BOOL del = YES;
        for (EWTaskItem *t in _allTasks) {
            if([aNotif.userInfo[kPushTaskKey] isEqualToString:t.ewtaskitem_id]){
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
        [self scheduleNotificationForTask:t];
    }
    
}

#pragma mark - check
- (BOOL)checkTasks{
    //time stemp for last check
    [EWDataStore sharedInstance].lastChecked = [NSDate date];
    NSLog(@"Checking tasks");
    NSMutableArray *tasks = [[self getTasksByPerson:currentUser] mutableCopy];

    
    //check if any task has past
    NSDate *time = [[NSDate date] timeByAddingMinutes:-120];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"time < %@", time];
    NSArray *pastTasks = [tasks filteredArrayUsingPredicate:predicate];
    if (pastTasks.count > 0) {
        //change task relationship
        if ([currentUser isFault]) {
            //[currentUser.managedObjectContext refreshObject:currentUser mergeChanges:YES];
            [EWDataStore refreshObjectWithServer:currentUser];
            NSLog(@"fetched user info from server");
        }
        for (EWTaskItem *t in pastTasks) {
            t.owner = nil;
            t.pastOwner = currentUser;
            t.alarm = nil;
            [tasks removeObject:t];
            NSLog(@"Task has been moved to past tasks: %@", [t.time date2detailDateString]);
        }
        //[self scheduleTasks];
        //return NO;
        [[EWDataStore currentContext] saveOnSuccess:^{
            //
        } onFailure:^(NSError *error) {
            NSLog(@"Failed to save psat task");
        }];
    }
    
    
    if(tasks.count == 0){
        //initial state
        NSLog(@"Task has not been setup yet");
        if (currentUser.alarms.count == 0) return YES;
        return NO;
    }else if (tasks.count >  7 * nWeeksToScheduleTask) {
        NSLog(@"Something is wrong with scheduled task: excessive tasks(%luu), please check.",(unsigned long) (unsigned long)tasks.count);
        
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




@end
