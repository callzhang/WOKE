 //
//  EWTaskStore.m
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWTaskStore.h"
#import "EWPerson.h"
#import "EWMediaItem.h"
#import "EWMediaStore.h"
#import "EWTaskItem.h"
#import "EWAlarmItem.h"
#import "EWAlarmManager.h"
#import "NSDate+Extend.h"
#import "EWDataStore.h"
#import "EWDefines.h"
#import "EWUserManagement.h"

@interface EWTaskStore(){
    BOOL isCheckingTask;
}

@end

@implementation EWTaskStore

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
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(scheduleTasks) name:kAlarmChangedNotification object:nil];
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
        //
    }
    return self;
}

- (void)setAllTasks:(NSMutableArray *)allTasks{
    NSLog(@"**** Please do not explicitly save all tasks to local ****");
}


#pragma mark - SEARCH
- (NSArray *)getTasksByPerson:(EWPerson *)p{
    EWPerson *person = [EWDataStore objectForCurrentContext:p];
    NSMutableArray *tasks = [[person.tasks allObjects] mutableCopy];
    [tasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"time >= %@", [[NSDate date] timeByAddingMinutes:-kMaxWakeTime]]];
    
    if ([person.username isEqualToString:currentUser.username]) {
        //check past task, move it to pastTasks and remove it from the array
        [self checkPastTasks:tasks];
    }
    
    //update if necessary
    if (tasks.count != 7 * nWeeksToScheduleTask) {
        NSLog(@"Only %lu tasks found, check from server", (unsigned long)tasks.count);
        [EWDataStore refreshManagedObjectAndWait:p];
        tasks = [[p.tasks allObjects] mutableCopy];
    }
    
    
    //sort
    return [tasks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
    
}

+ (NSArray *)myTasks{
    return [[EWTaskStore sharedInstance] getTasksByPerson:currentUser];
}

- (NSArray *)pastTasksByPerson:(EWPerson *)person{
    //because the pastTask is not a static relationship, i.e. the set of past tasks need to be updated timely, we try to pull data from Query first and save them to
    
    NSMutableArray *tasks;

    //get from local cache if self or time elapsed since last update is shorter than predefined interval
    if ([person.username isEqualToString:currentUser.username] || -[person.updatedAt timeIntervalSinceNow] < kTaskUpdateInterval) {
        tasks = [[person.pastTasks allObjects] mutableCopy];
        [tasks sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]]];
    }else{
        //sort
        [tasks sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]]];
        //get from server
        PFQuery *query = [PFQuery queryWithClassName:@"EWTaskItem"];
        [query whereKey:@"time" lessThan:[[NSDate date] timeByAddingMinutes:-kMaxWakeTime]];
        [query whereKey:@"state" equalTo:@YES];
        [query whereKey:@"owner" equalTo:person];
        [query orderBySortDescriptor:[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]];
        query.limit = 10;
        tasks = [[query findObjects] mutableCopy];
        //assign back to person.tasks
        person.tasks = nil;
        for (PFObject *task in tasks) {
            EWTaskItem *taskMO = (EWTaskItem *)[EWDataStore findOrCreateManagedObjectWithEntityName:@"EWTaskItem" withParseObject:task];
            [person addTasksObject:taskMO];
        }
        [EWDataStore save];
    }
    
    
    return tasks;
}

//next valid task
- (EWTaskItem *)nextValidTaskForPerson:(EWPerson *)person{
    return [self nextNth:0 validTaskForPerson:person];
}

- (EWTaskItem *)nextNth:(NSInteger)n validTaskForPerson:(EWPerson *)person{
    NSArray *tasks = [self getTasksByPerson:[EWDataStore objectForCurrentContext:person]];
    EWTaskItem *nextTask;
    for (unsigned i=0; i<tasks.count; i++) {
        nextTask = tasks[i];
        
        //Task shoud be On AND not finished AND has less than the default max voices
        if (nextTask.state == YES && !nextTask.completed) {
            NSInteger nVoice = [self numberOfVoiceInTask:nextTask];
            if (nVoice < kMaxVoicePerTask) {
                n--;
                if (n < 0) {
                    //find the task
                    return nextTask;
                }
            }
            
        }
    }
    return nil;
}

//next task
- (EWTaskItem *)nextTaskAtDayCount:(NSInteger)n ForPerson:(EWPerson *)person{
    
    NSArray *tasks = [self getTasksByPerson:[EWDataStore objectForCurrentContext:person]];
    if (tasks.count > n) {
        return tasks[n];
    }
    return nil;
    
}

- (EWTaskItem *)getTaskByID:(NSString *)taskID{
    if (!taskID) return nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EWTaskItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"ewtaskitem_id == %@", taskID];
    NSError *err;
    NSArray *tasks = [EWDataStore.currentContext executeFetchRequest:request error:&err];
    if (tasks.count != 1) {
        NSLog(@"Error getting task from ID: %@. Error: %@", taskID, err.description);
        return nil;
    }
    return tasks[0];
}


#pragma mark - SCHEDULE
//schedule new task in the future
- (NSArray *)scheduleTasks{
    if (isCheckingTask) {
        NSLog(@"@@@ It is already checking task, skip!");
        return nil;
    }
    
    //check necessity
    NSMutableArray *tasks = [[EWTaskStore myTasks] mutableCopy];//avoid using 'getTaskByPerson:' method to cycle calling
    NSArray *alarms = [EWAlarmManager myAlarms];
    if (!alarms) {
        NSLog(@"Something wrong with my alarms, get nil");
        return nil;
    }
    if (alarms.count == 0 && tasks.count == 0) {
        NSLog(@"Forfeit sccheduling task due to no alarm and task exists");
        return nil;
    }
    
    //start check
    NSLog(@"Start check/scheduling tasks");
    isCheckingTask = YES;
    
    //FIRST check past tasks
    BOOL hasOutDatedTask = [self checkPastTasks:tasks];
    
    //for each alarm, find matching task, or create new task
    BOOL newTaskNotify = NO;
    NSMutableArray *goodTasks = [NSMutableArray new];
    
    for (EWAlarmItem *a in alarms){//loop through alarms
        
        for (unsigned i=0; i<nWeeksToScheduleTask; i++) {//loop for week
            
            //next time for alarm, this is what the time should be there
            NSDate *time = [a.time nextOccurTime:i];
            BOOL taskMatched = NO;
            //loop through the tasks to verify the target time has been scheduled
            for (EWTaskItem *t in tasks) {
                if ([t.time isEqualToDate:time]) {
                    //find the task, move to good task
                    [goodTasks addObject:t];
                    [tasks removeObject:t];
                    taskMatched = YES;
                    //break here to avoid creating new task
                    break;
                }
            }
            
            if (!taskMatched) {
                //start scheduling task
                NSLog(@"Task on %@ has not been found, creating!", time.weekday);
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
    }
   
    //check data integrety
    if (tasks.count > 0) {
        NSLog(@"*** After removing valid task and past task, there are still %lu tasks left", (unsigned long)tasks.count);
        for (EWTaskItem *t in tasks) {
            [self removeTask:t];
        }
    }
    
    //save
    if (hasOutDatedTask || newTaskNotify) {
        
        [EWDataStore save];
        [[NSNotificationCenter defaultCenter] postNotificationName:kTaskNewNotification object:nil userInfo:nil];
        
    }
    
    //last checked
    [EWDataStore sharedInstance].lastChecked = [NSDate date];
    
    isCheckingTask = NO;
    return goodTasks;
}


- (BOOL)checkPastTasks:(NSMutableArray *)tasks{
    //nullify old task's relation to alarm
    BOOL isOutDated = NO;
    NSPredicate *old = [NSPredicate predicateWithFormat:@"time < %@", [[NSDate date] timeByAddingSeconds:-kMaxWakeTime]];
    NSArray *outDatedTasks = [tasks filteredArrayUsingPredicate:old];
    for (EWTaskItem *t in outDatedTasks) {
        if (![t.owner.username isEqualToString:currentUser.username]) {
            NSLog(@"@@@ Passed in tasks are not for current user");
            return NO;
        }
        t.alarm = nil;
        t.owner = nil;
        t.pastOwner = [EWUserManagement currentUser];
        [tasks removeObject:t];
        NSLog(@"====== Task on %@ moved to past ======", [t.time date2dayString]);
        [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDeleteNotification object:t];
        isOutDated = YES;
    }
    
    if (isOutDated) {
        [EWDataStore updateToServerAndSave];
    }
    
    return isOutDated;
}

#pragma mark - NEW
- (EWTaskItem *)newTask{
    
    EWTaskItem *t = [EWTaskItem createEntity];
    //relation
    t.owner = [EWUserManagement currentUser];
    //others
    t.added = [NSDate date];
    
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


//state
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
            
            if (t.state == YES) {
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
        [EWDataStore save];
    }
}

//time
- (void)updateTaskTime:(NSNotification *)notif{
    EWAlarmItem *a = notif.userInfo[@"alarm"];
    if (!a) [NSException raise:@"No alarm info" format:@"Check notification"];
    [self updateTaskTimeForAlarm:a];
}

- (void)updateTaskTimeForAlarm:(EWAlarmItem *)a{
    EWAlarmItem *alarm = (EWAlarmItem *)[[EWDataStore currentContext] objectWithID:a.objectID];
    if (!alarm.tasks.count) {
        //[a.managedObjectContext refreshObject:a mergeChanges:YES];
        //[EWDataStore refreshObjectWithServer:a];
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
    [EWDataStore save];
}

//Notifications
- (void)updateNotifTone:(NSNotification *)notif{
    EWAlarmItem *a = notif.userInfo[@"alarm"];
    EWAlarmItem *alarm = (EWAlarmItem *)[EWDataStore objectForCurrentContext:a];
    
    for (EWTaskItem *t in alarm.tasks) {
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
        //[EWDataStore refreshObjectWithServer:task];
        EWTaskItem *task_ = (EWTaskItem *)[EWDataStore objectForCurrentContext:task];
        [[NSNotificationCenter defaultCenter] postNotificationName:kTaskChangedNotification object:self userInfo:@{kPushTaskKey: task_}];
    });
}

- (void)alarmRemoved:(NSNotification *)notif{
    NSArray *alarms;
    if (![notif.object isKindOfClass:[NSArray class]]) {
        alarms = @[notif.userInfo];
    }else{
        alarms = (NSArray *)notif.object;
    }
    
    for (EWAlarmItem *a in alarms) {
        for (EWTaskItem *t in a.tasks) {
            
            NSLog(@"Delete task on %@ due to alarm deleted", t.time.weekday);
            [self removeTask:t];
        }
        
    }
    [EWDataStore updateToServerAndSave];
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
    [EWDataStore save];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDeleteNotification object:task userInfo:@{kPushTaskKey: task}];
}

- (void)deleteAllTasks{
    NSLog(@"*** Deleting all tasks");
    
    for (EWTaskItem *t in [self getTasksByPerson:[EWUserManagement currentUser]]) {
        //post notification
        [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDeleteNotification object:t userInfo:@{kPushTaskKey: t}];
        //cancel local notif
        [self cancelNotificationForTask:t];
        //delete
        [[EWDataStore currentContext] deleteObject:t];
    }
    [EWDataStore save];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskNewNotification object:self userInfo:nil];
   
}

#pragma mark - Local Notification
- (void)scheduleNotificationForTask:(EWTaskItem *)task{
    //check state
    if (task.state == NO) {
        [self cancelNotificationForTask:task];
        return;
    }
    
    //check existing
    NSMutableArray *notifications = [[self localNotificationForTask:task] mutableCopy];
    
    //check missing
    for (unsigned i=0; i<nLocalNotifPerTask; i++) {
        //get time
        NSDate *time_i = [task.time timeByAddingSeconds: i * 60];
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
            if (alarm.statement) {
                localNotif.alertBody = [NSString stringWithFormat:LOCALSTR(alarm.statement)];
            }else{
                localNotif.alertBody = @"It's time to get up!";
            }
            
            localNotif.alertAction = LOCALSTR(@"Get up!");//TODO
            localNotif.soundName = alarm.tone;
            localNotif.applicationIconBadgeNumber = i+1;
            
            //======= user information passed to app delegate =======
            localNotif.userInfo = @{kPushTaskKey: task.objectID.URIRepresentation.absoluteString};
            //=======================================================
            
            if (i == nWeeksToScheduleTask - 1) {
                //if this is the last one, schedule to be repeat
                localNotif.repeatInterval = NSWeekCalendarUnit;
            }
            
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
            NSLog(@"Local Notif scheduled at %@", localNotif.fireDate.date2detailDateString);
        }
    }
    
    //delete remaining
    if (notifications.count > 0) {
        NSLog(@"Unmatched tasks deleted (%@) ", task.time.date2detailDateString);
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
        if([aNotif.userInfo[kPushTaskKey] isEqualToString:task.objectID.URIRepresentation.absoluteString]) {
            [notifArray addObject:aNotif];
        }
    }

    return notifArray;
}


- (void)checkScheduledNotifications{
    NSMutableArray *allNotification = [[[UIApplication sharedApplication] scheduledLocalNotifications] mutableCopy];
    NSArray *tasks = [self getTasksByPerson:[EWUserManagement currentUser]];

    NSLog(@"There are %ld scheduled local notification and %ld stored task info", (long)allNotification.count, (long)tasks.count);
    
    //delete redundant alarm notif
    for (EWTaskItem *task in tasks) {
        [self scheduleNotificationForTask:task];
        NSArray *notifs= [self localNotificationForTask:task];
        [allNotification removeObjectsInArray:notifs];
    }
    
    
    for (UILocalNotification *aNotif in allNotification) {

        NSLog(@"===== Deleted Local Notif on %@ (%@) =====", aNotif.fireDate, aNotif.userInfo[kPushTaskKey]);
        [[UIApplication sharedApplication] cancelLocalNotification:aNotif];

    }
    
}


- (void)fireAlarmForTask:(EWTaskItem *)task{
    NSLog(@"Firing alarm");
    UILocalNotification *alarm = [[UILocalNotification alloc] init];
    alarm.alertBody = [NSString stringWithFormat:@"It's time to wake up (%@)", [task.time date2String]];
    alarm.alertAction = @"Wake up!";
    alarm.soundName = task.alarm.tone;
    alarm.userInfo = @{kPushTaskKey: task.objectID.URIRepresentation.absoluteString};
    [[UIApplication sharedApplication] scheduleLocalNotification:alarm];
}

#pragma mark - check

- (NSInteger)numberOfVoiceInTask:(EWTaskItem *)task{
    NSInteger nMedia = 0;
    for (EWMediaItem *m in task.medias) {
        if ([m.type isEqualToString: kMediaTypeVoice]) {
            nMedia++;
        }
    }
    return nMedia;
}

@end
