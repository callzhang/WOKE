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
#import "EWDataStore.h"
#import "EWUserManagement.h"


@implementation EWTaskStore

+(EWTaskStore *)sharedInstance{
    
    //make sure core data stuff is always on main thread
    //NSParameterAssert([NSThread isMainThread]);
    
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
        self.isSchedulingTask = NO;
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
    //filter
    //[tasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"time >= %@", [[NSDate date] timeByAddingMinutes:-kMaxWakeTime]]];
    //check past task
    if ([person isMe]) {
        //check past task, move it to pastTasks and remove it from the array
        [self checkPastTasks:tasks];
    }
    
    //sort
    return [tasks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
    
}

+ (NSArray *)myTasks{
    return [[EWTaskStore sharedInstance] getTasksByPerson:me];
}

- (NSArray *)pastTasksByPerson:(EWPerson *)person{
    //because the pastTask is not a static relationship, i.e. the set of past tasks need to be updated timely, we try to pull data from Query first and save them to person
    
    NSMutableArray *tasks;

    //get from local cache if self or time elapsed since last update is shorter than predefined interval
    if (person.isMe || !person.isOutDated) {
        tasks = [[person.pastTasks allObjects] mutableCopy];
        [tasks sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]]];
    }else{
        //get from server
        NSLog(@"Fetch past task from server for %@", person.name);
        PFQuery *query = [PFQuery queryWithClassName:@"EWTaskItem"];
        [query whereKey:@"time" lessThan:[[NSDate date] timeByAddingMinutes:-kMaxWakeTime]];
        [query whereKey:@"state" equalTo:@YES];
        PFUser *user = [PFUser objectWithoutDataWithClassName:@"PFUser" objectId:person.objectId];
        [query whereKey:@"owner" equalTo:user];
        [query orderBySortDescriptor:[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]];
        query.limit = 10;
        tasks = [[query findObjects] mutableCopy];
        //assign back to person.tasks
        for (PFObject *task in tasks) {
            EWTaskItem *taskMO = (EWTaskItem *)[task managedObject];
            [person addPastTasksObject:taskMO];
        }
        [EWDataStore save];
    }
    
    
    return tasks;
}

#pragma mark - Next task
- (NSDate *)nextWakeUpTimeForPerson:(EWPerson *)person{
    EWTaskItem *t = [self nextValidTaskForPerson:person];
    NSDate *time;
    if (t) {
        time = t.time;
    }else{
        NSLog(@"Didn't get next task for %@, use catched info", person.name);
        time = person.cachedInfo[kNextTaskTime];
    }
    
    return time;
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
    
    EWTaskItem *task = [EWTaskItem findFirstByAttribute:kParseObjectID withValue:taskID];
    
    if (!task) {
        PFQuery *q = [PFQuery queryWithClassName:@"EWTaskItem"];
        [q whereKey:kParseObjectID equalTo:taskID];
        PFObject *PO = [q getFirstObject];
        task = (EWTaskItem *)PO.managedObject;
        [task refreshInBackgroundWithCompletion:NULL];
    }
    return task;
}

- (EWTaskItem *)getTaskByLocalID:(NSString *)localID{
    NSManagedObjectID *taskID = [[NSManagedObjectContext contextForCurrentThread].persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:localID]];
    EWTaskItem *task = (EWTaskItem *)[[NSManagedObjectContext contextForCurrentThread] objectWithID:taskID];
    return task;
}

#pragma mark - SCHEDULE
//schedule new task in the future
- (NSArray *)scheduleTasks{
    if (self.isSchedulingTask) {
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
    
    //start check
    NSLog(@"Start check/scheduling tasks");
    self.isSchedulingTask = YES;
    
    BOOL newTask = NO;
    
    //Check task from server if not desired number
    if (tasks.count != 7 * nWeeksToScheduleTask) {
        //cannot check my task from server, which will cause checking / schedule cycle
        NSLog(@"My task count is %lu, checking from server!", (unsigned long)tasks.count);
        //this approach is a last resort to fetch task by owner
        PFQuery *taskQuery= [PFQuery queryWithClassName:@"EWTaskItem"];
        [taskQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
        NSArray *objects = [taskQuery findObjects];
        for (PFObject *t in objects) {
            EWTaskItem *task = (EWTaskItem *)t.managedObject;
            task.owner = me;
            if (![tasks containsObject:task]) {
                [tasks addObject:task];
                newTask = YES;
                NSLog(@"New task found from server: %@(%@)", task.time.weekday, t.objectId);
            }
        }
    }

    if (alarms.count == 0 && tasks.count == 0) {
        NSLog(@"Forfeit sccheduling task due to no alarm and task exists");
        self.isSchedulingTask = NO;
        return nil;
    }

    //FIRST check past tasks
    BOOL hasOutDatedTask = [self checkPastTasks:tasks];
    
    //for each alarm, find matching task, or create new task
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
                    if (!t.alarm) {
                        t.alarm = a;
                        newTask = YES;
                    }
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
                t.state = a.state;
                [goodTasks addObject:t];
                //localNotif
                [self scheduleNotificationForTask:t];
                //prepare to broadcast
                newTask = YES;
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
    if (hasOutDatedTask || newTask) {
        
        [self updateNextTaskTime];
        [EWDataStore save];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskNewNotification object:nil userInfo:nil];
        });
        
    }
    
    //last checked
    [EWDataStore sharedInstance].lastChecked = [NSDate date];
    
    self.isSchedulingTask = NO;
    return goodTasks;
}


- (BOOL)checkPastTasks:(NSMutableArray *)tasks{
    //nullify old task's relation to alarm
    BOOL taskOutDated = NO;
    NSPredicate *old = [NSPredicate predicateWithFormat:@"time < %@", [[NSDate date] timeByAddingSeconds:-kMaxWakeTime]];
    NSArray *outDatedTasks = [tasks filteredArrayUsingPredicate:old];
    for (EWTaskItem *t in outDatedTasks) {
        t.alarm = nil;
        t.owner = nil;
        t.pastOwner = [EWPersonStore me];
        [tasks removeObject:t];
        NSLog(@"====== Task on %@ moved to past ======", [t.time date2dayString]);
        [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDeleteNotification object:t];
        taskOutDated = YES;
    }
    
    if (taskOutDated) {
        [EWDataStore save];
    }
    
    return taskOutDated;
}

#pragma mark - NEW
- (EWTaskItem *)newTask{
    
    EWTaskItem *t = [EWTaskItem createEntity];
    //relation
    t.owner = [EWPersonStore me];
    //others
    t.createdAt = [NSDate date];
    //[EWDataStore save];
    
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
    [self updateNextTaskTime];
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
    EWAlarmItem *alarm = (EWAlarmItem *)[EWDataStore objectForCurrentContext:a];
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
    [self updateNextTaskTime];
    [EWDataStore save];
}

//Tone
- (void)updateNotifTone:(NSNotification *)notif{
    EWAlarmItem *a = notif.userInfo[@"alarm"];
    EWAlarmItem *alarm = (EWAlarmItem *)[EWDataStore objectForCurrentContext:a];
    
    for (EWTaskItem *t in alarm.tasks) {
        [self cancelNotificationForTask:t];
        [self scheduleNotificationForTask:t];
        NSLog(@"Notification on %@ tone updated to: %@", t.time.date2String, a.tone);
    }
}

//update task when new media available
//- (void)updateTaskMedia:(NSNotification *)notif{
//    //NSString *mediaID = [notif userInfo][kPushMediaKey];
//    NSString *taskID = [notif userInfo][kPushTaskKey];
//    if ([taskID isEqualToString:@""]) return;
//    EWTaskItem *task = [self getTaskByID:taskID];
//    //EWMediaItem *media = [[EWMediaStore sharedInstance] getMediaByID:mediaID];
//    //NSAssert([task.medias containsObject:media], @"Media and Task should have relation");
//    dispatch_async(dispatch_get_main_queue(), ^{
//        //[task.managedObjectContext refreshObject:task mergeChanges:YES];
//        //[EWDataStore refreshObjectWithServer:task];
//        EWTaskItem *task_ = (EWTaskItem *)[EWDataStore objectForCurrentContext:task];
//        [[NSNotificationCenter defaultCenter] postNotificationName:kTaskChangedNotification object:self userInfo:@{kPushTaskKey: task_}];
//    });
//}

- (void)alarmRemoved:(NSNotification *)notif{
    id objects = notif.object;
    NSArray *alarms;
    if ([objects isKindOfClass:[NSArray class]]) {
        alarms = objects;
    }else if ([objects isKindOfClass:[EWAlarmItem class]]){
        alarms = @[objects];
    }
    for (EWAlarmItem *alarm in alarms) {
        while (alarm.tasks.count > 0) {
            EWTaskItem *t = alarm.tasks.anyObject;
            NSLog(@"Delete task on %@ due to alarm deleted", t.time.weekday);
            [self removeTask:t];
        }
    }
    
    [EWDataStore save];
}

/* add task by alarm, this function is replaced by scheduleTask
- (void)alarmAdded:(NSNotification *)notif{
    EWAlarmItem *alarm = notif.userInfo[@"alarm"];
    NSLog(@"Add task for alarm %@", [alarm.time date2detailDateString]);
    for (NSInteger i=0; i<nWeeksToScheduleTask; i++) {
        EWTaskItem *task = [self newTask];
        
    }
}*/

//Update next task time
- (void)updateNextTaskTime{
    EWTaskItem *task = [self nextValidTaskForPerson:me];
    NSMutableDictionary *cache = [me.cachedInfo mutableCopy];
    if (!cache) {
        cache = [NSMutableDictionary new];
    }
    if (![cache[kNextTaskTime] isEqual: task.time]) {
        [cache setValue:task.time forKey:kNextTaskTime];
        [cache setValue:task.statement forKeyPath:kNextTaskStatement];
        me.cachedInfo = [cache copy];
        NSLog(@"Saved next task time: %@ to cacheInfo", task.time.date2detailDateString);
        [EWDataStore save];
    }
}

#pragma mark - DELETE
- (void)removeTask:(EWTaskItem *)task{
    NSLog(@"Task on %@ deleted", task.time.date2detailDateString);
    [self cancelNotificationForTask:task];
    [[EWDataStore currentContext] deleteObject:task];
    [EWDataStore save];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDeleteNotification object:task userInfo:@{kLocalTaskKey: task}];
}

- (void)deleteAllTasks{
    NSLog(@"*** Deleting all tasks");
    
    for (EWTaskItem *t in [self getTasksByPerson:[EWPersonStore me]]) {
        //post notification
        [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDeleteNotification object:t userInfo:@{kLocalTaskKey: t}];
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
        NSLog(@"Local Notification cancelled for:%@", aNotif.fireDate.date2detailDateString);
        [[UIApplication sharedApplication] cancelLocalNotification:aNotif];
    }
}

- (NSArray *)localNotificationForTask:(EWTaskItem *)task{
    NSMutableArray *notifArray = [[NSMutableArray alloc] init];
    for(UILocalNotification *aNotif in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if([aNotif.userInfo[kLocalTaskKey] isEqualToString:task.objectID.URIRepresentation.absoluteString]) {
            [notifArray addObject:aNotif];
        }
    }

    return notifArray;
}


- (void)checkScheduledNotifications{
    NSMutableArray *allNotification = [[[UIApplication sharedApplication] scheduledLocalNotifications] mutableCopy];
    NSArray *tasks = [self getTasksByPerson:[EWPersonStore me]];

    NSLog(@"There are %ld scheduled local notification and %ld stored task info", (long)allNotification.count, (long)tasks.count);
    
    //delete redundant alarm notif
    for (EWTaskItem *task in tasks) {
        [self scheduleNotificationForTask:task];
        NSArray *notifs= [self localNotificationForTask:task];
        [allNotification removeObjectsInArray:notifs];
    }
    
    
    for (UILocalNotification *aNotif in allNotification) {

        NSLog(@"===== Deleted Local Notif (%@) =====", aNotif.fireDate.date2detailDateString);
        [[UIApplication sharedApplication] cancelLocalNotification:aNotif];

    }
    
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

+ (BOOL)validateTask:(EWTaskItem *)task{
    BOOL completed = [[NSDate date] timeIntervalSinceDate: task.time] > kMaxWakeTime || task.completed;
    if (completed) {
        NSParameterAssert(!task.alarm);
        if (task.owner) {
            task.owner = nil;
            NSLog(@"*** task (%@) completed, shoundn't have owner", task.serverID);
        }
        if (!task.pastOwner) {
            task.pastOwner = [EWPersonStore me];
            NSLog(@"*** task (%@) missing pastOwner", task.serverID);
        }
    }else{
        NSParameterAssert(task.alarm);
        if (task.pastOwner) {
            task.pastOwner = nil;
            NSLog(@"*** task (%@) incomplete, shoundn't have past owner", task.serverID);
        }
        if (!task.owner) {
            task.owner = [EWPersonStore me];
            NSLog(@"*** task (%@) missing owner", task.serverID);
        }
    }
    NSParameterAssert(task.time);
    return YES;
}

@end
