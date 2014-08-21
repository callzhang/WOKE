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
#import "EWPersonStore.h"
#import "AFNetworking.h"
#import "EWStatisticsManager.h"

@implementation EWTaskStore

+(EWTaskStore *)sharedInstance{
    
    //make sure core data stuff is always on main thread
    //NSParameterAssert([NSThread isMainThread]);
    
    static EWTaskStore *sharedTaskStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTaskStore_ = [[EWTaskStore alloc] init];
        //Watch Alarm change
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(updateTaskTime:) name:kAlarmTimeChangedNotification object:nil];
        //watch alarm state change
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(updateTaskState:) name:kAlarmStateChangedNotification object:nil];
        //watch tone change
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(updateNotifTone:) name:kAlarmToneChangedNotification object:nil];
        //watch for new alarm
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(scheduleTasks) name:kAlarmChangedNotification object:nil];
        //watch alarm deletion
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(alarmRemoved:) name:kAlarmDeleteNotification object:nil];
        //task state change
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(updateTaskState:) name:kTaskStateChangedNotification object:nil];
        //watch media change
        [[NSNotificationCenter defaultCenter] addObserver:sharedTaskStore_ selector:@selector(updateTaskMedia:) name:kNewMediaNotification object:nil];
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



#pragma mark - SEARCH
- (NSArray *)getTasksByPerson:(EWPerson *)person{
    NSMutableArray *tasks = [[person.tasks allObjects] mutableCopy];
    //filter
    //[tasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"time >= %@", [[NSDate date] timeByAddingMinutes:-kMaxWakeTime]]];
    //check past task
//    if ([person isMe]) {
//        //check past task, move it to pastTasks and remove it from the array
//        [self checkPastTasks:tasks];
//    }
    
    //sort
    return [tasks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
    
}

+ (NSArray *)myTasks{
    NSParameterAssert([NSThread isMainThread]);
    return [[EWTaskStore sharedInstance] getTasksByPerson:me];
}

- (NSArray *)pastTasksByPerson:(EWPerson *)person{
    
    //because the pastTask is not a static relationship, i.e. the set of past tasks need to be updated timely, we try to pull data from Query first and save them to person
    //get from local cache if self or time elapsed since last update is shorter than predefined interval
    if (!person.isMe) {
        return [NSArray new];
    }
    NSMutableArray *tasks = [[person.pastTasks allObjects] mutableCopy];
    [tasks sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]]];
    
    return [tasks copy];
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
    NSArray *tasks = [self getTasksByPerson:person];
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
    
    NSArray *tasks = [self getTasksByPerson:person];
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
        task = (EWTaskItem *)[PO managedObjectInContext:nil];
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
- (NSArray *)scheduleTasks{
    NSParameterAssert([NSThread isMainThread]);
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        [self scheduleTasksInContext:localContext];
    }];
    NSArray *myTasks = [self getTasksByPerson:me];
    return myTasks;
}


- (void)scheduleTasksInBackground{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [self scheduleTasksInContext:localContext];
    }];
}


//schedule new task in the future
- (NSArray *)scheduleTasksInContext:(NSManagedObjectContext *)context{
    NSParameterAssert(context);
    if (self.isSchedulingTask) {
        NSLog(@"It is already checking task, skip!");
        return nil;
    }
    
    //check necessity
    NSError *err;
    EWPerson *localPerson = (EWPerson *)[context existingObjectWithID:me.objectID error:&err];
    NSMutableArray *tasks = [[[EWTaskStore sharedInstance] getTasksByPerson:localPerson] mutableCopy];
    NSArray *alarms = [[EWAlarmManager sharedInstance] alarmsForUser:localPerson];
    if (!alarms) {
        NSLog(@"Something wrong with my alarms, get nil");
        return nil;
    }
    
    //start check
    NSLog(@"Start check/scheduling tasks");
    self.isSchedulingTask = YES;
    
    NSMutableArray *newTask = [NSMutableArray new];
    
    //Check task from server if not desired number
    if (tasks.count != 7 * nWeeksToScheduleTask && !self.lastChecked.isUpToDated) {
        //cannot check my task from server, which will cause checking / schedule cycle
        NSLog(@"My task count is %lu, checking from server!", (unsigned long)tasks.count);
        //this approach is a last resort to fetch task by owner
        PFQuery *taskQuery= [PFQuery queryWithClassName:@"EWTaskItem"];
        [taskQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
        [taskQuery whereKey:kParseObjectID notContainedIn:[tasks valueForKey:kParseObjectID]];
        NSArray *objects = [taskQuery findObjects];
        for (PFObject *t in objects) {
            EWTaskItem *task = (EWTaskItem *)[t managedObjectInContext:context];
            [task refresh];
            if (![tasks containsObject:task]) {
                [tasks addObject:task];
                [newTask addObject:task];
                
                // add schedule notification
                [EWTaskStore scheduleNotificationOnServerWithTimer:task];
                
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
    BOOL hasOutDatedTask = [self checkPastTasks];
    
    //for each alarm, find matching task, or create new task
    NSMutableArray *goodTasks = [NSMutableArray new];
    
    for (EWAlarmItem *a in alarms){//loop through alarms
        
        for (unsigned i=0; i<nWeeksToScheduleTask; i++) {//loop for week
            
            //next time for alarm, this is what the time should be there
            NSDate *time = [a.time nextOccurTime:i];
            BOOL taskMatched = NO;
            //loop through the tasks to verify the target time has been scheduled
            for (EWTaskItem *t in tasks) {
                if ([t.time isEqualToDate:time] && t.objectId) {
                    BOOL good = [EWTaskStore validateTask:t];
                    //find the task, move to good task
                    if (good) {
                        [goodTasks addObject:t];
                        [tasks removeObject:t];
                        if (t.alarm != a) {
                            t.alarm = a;
                        }
                        taskMatched = YES;
                        //break here to avoid creating new task
                        break;
                    }
                    
                }
            }
            
            if (!taskMatched) {
                //start scheduling task
                NSLog(@"Task on %@ has not been found, creating!", time.weekday);
                //new task
                EWTaskItem *t = [self newTaskInContext:context];
                t.time = time;
                t.alarm = a;
                t.state = a.state;
                [goodTasks addObject:t];
                //localNotif
                [self scheduleNotificationForTask:t];
                
                //prepare to broadcast
                [newTask addObject:t];
            }
        }
    }
   
    //check data integrety
    if (tasks.count > 0) {
        NSLog(@"!!! After removing valid task and past task, there are still %lu tasks left", (unsigned long)tasks.count);
        for (EWTaskItem *t in tasks) {
            [self removeTask:t];
        }
    }
    
    //save
    if (hasOutDatedTask || newTask.count) {
        
        [self updateNextTaskTime];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskNewNotification object:nil userInfo:nil];
        });
        
        NSArray *newTaskIDs = [newTask valueForKey:@"objectID"];
        
        [[EWDataStore sharedInstance].saveCallbacks addObject:^{
            for (NSManagedObjectID *taskID in newTaskIDs) {
                EWTaskItem *task = (EWTaskItem *)[[EWDataStore mainContext] existingObjectWithID:taskID error:NULL];
                // remote notification
                [EWTaskStore scheduleNotificationOnServerWithTimer:task];
            }
        }];
    }
    
    //last checked
    self.lastChecked = [NSDate date];
    
    self.isSchedulingTask = NO;
    return goodTasks;
}


- (BOOL)checkPastTasks{
    __block BOOL taskOutDated = NO;
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        
        EWPerson *localMe = [me inContext:localContext];
        NSMutableSet *tasks = localMe.tasks.mutableCopy;
        
        //nullify old task's relation to alarm
        BOOL taskOutDated = NO;
        NSPredicate *old = [NSPredicate predicateWithFormat:@"time < %@", [[NSDate date] timeByAddingSeconds:-kMaxWakeTime]];
        NSSet *outDatedTasks = [tasks filteredSetUsingPredicate:old];
        for (EWTaskItem *t in outDatedTasks) {
            t.alarm = nil;
            t.owner = nil;
            t.pastOwner = [EWPersonStore meInContext:t.managedObjectContext];
            [tasks removeObject:t];
            NSLog(@"====== Task on %@ moved to past ======", [t.time date2dayString]);
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDeleteNotification object:t];
            taskOutDated = YES;
        }
        
        //check on server
        NSMutableArray *pastTasks = [[localMe.pastTasks allObjects] mutableCopy];
        [pastTasks sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]]];
        EWTaskItem *latestTask = pastTasks.firstObject;
        if (latestTask.time.timeElapsed > 3600*24) {
            //we should not query other's past task
            if([EWDataStore isReachable]){
                //get from server
                NSLog(@"Fetch past task from server for %@", localMe.name);
                PFQuery *query = [PFQuery queryWithClassName:@"EWTaskItem"];
                //[query whereKey:@"time" lessThan:[[NSDate date] timeByAddingMinutes:-kMaxWakeTime]];
                //[query whereKey:@"state" equalTo:@YES];
                [query whereKey:kParseObjectID notContainedIn:[pastTasks valueForKey:kParseObjectID]];
                PFUser *user = [PFUser objectWithoutDataWithClassName:@"PFUser" objectId:localMe.objectId];
                [query whereKey:@"pastOwner" equalTo:user];
                [query orderBySortDescriptor:[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]];
                tasks = [[query findObjects] mutableCopy];
//                >>>>>>> task has not result <<<<<<<<
                //assign back to person.tasks
                for (PFObject *task in tasks) {
                    EWTaskItem *taskMO = (EWTaskItem *)[task managedObjectInContext:localContext];
                    [localMe addPastTasksObject:taskMO];
                    taskOutDated = YES;
                    NSLog(@"!!! Task found on server: %@", taskMO.time.date2dayString);
                }
            }
        }
        
        
        if (taskOutDated) {
            //update cached activities
            [EWStatisticsManager updateTaskActivityCacheWithCompletion:NULL];
        }

    }];
    
    
    return taskOutDated;
}

#pragma mark - NEW
- (EWTaskItem *)newTaskInContext:(NSManagedObjectContext *)context{
    
    EWTaskItem *t = [EWTaskItem createInContext:context];
    t.updatedAt = [NSDate date];
    //relation
    t.owner = [EWPersonStore meInContext:context];
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
                [self updateNextTaskTime];
                [self scheduleNotificationForTask:t];
            } else {
                //cancel local notif
                [self cancelNotificationForTask:t];
                [self updateNextTaskTime];
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

- (void)updateTaskTimeForAlarm:(EWAlarmItem *)alarm{
    if (!alarm.tasks.count) {
        //[a.managedObjectContext refreshObject:a mergeChanges:YES];
        //[EWDataStore refreshObjectWithServer:a];
        NSLog(@"Alarm's tasks not fetched, refresh from server. New tasks relation has %lu tasks", (unsigned long)alarm.tasks.count);
    }
    NSSortDescriptor *des = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
    NSArray *sortedTasks = [alarm.tasks sortedArrayUsingDescriptors:@[des]];
    for (unsigned i=0; i<nWeeksToScheduleTask; i++) {
        EWTaskItem *t = sortedTasks[i];
        NSDate *nextTime = [alarm.time nextOccurTime:i];
        if (![t.time isEqual:nextTime]) {
            t.time = nextTime;
            //local notif
            [self cancelNotificationForTask:t];
            [self scheduleNotificationForTask:t];
            //Notification
            //[[NSNotificationCenter defaultCenter] postNotificationName:kTaskChangedNotification object:t userInfo:@{@"task": t}];
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskTimeChangedNotification object:t userInfo:@{@"task": t}];
            // schedule on server
            [EWTaskStore scheduleNotificationOnServerWithTimer:t];
        }
    }
    [self updateNextTaskTime];
    [EWDataStore save];
}

//Tone
- (void)updateNotifTone:(NSNotification *)notif{
    EWAlarmItem *alarm = notif.userInfo[@"alarm"];
    
    for (EWTaskItem *t in alarm.tasks) {
        [self cancelNotificationForTask:t];
        [self scheduleNotificationForTask:t];
        NSLog(@"Notification on %@ tone updated to: %@", t.time.date2String, alarm.tone);
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

//Update next task time in cache
- (void)updateNextTaskTime{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        EWPerson *localMe = [EWPersonStore meInContext:localContext];
        EWTaskItem *task = [self nextValidTaskForPerson:localMe];
        NSMutableDictionary *cache = [localMe.cachedInfo mutableCopy]?:[NSMutableDictionary new];

        if (![cache[kNextTaskTime] isEqual: task.time]) {
            [cache setValue:task.time forKey:kNextTaskTime];
            [cache setValue:task.statement forKeyPath:kNextTaskStatement];
            localMe.cachedInfo = [cache copy];
            
            NSLog(@"Updated next task time: %@ to cacheInfo", task.time.date2detailDateString);
        }

    }];
    
}

#pragma mark - DELETE
- (void)removeTask:(EWTaskItem *)task{
    NSLog(@"Task on %@ deleted", task.time.date2detailDateString);
    [self cancelNotificationForTask:task];
    [task.managedObjectContext deleteObject:task];
    [task.managedObjectContext saveToPersistentStoreAndWait];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDeleteNotification object:task userInfo:@{kLocalTaskKey: task}];
}

- (void)deleteAllTasks{
    NSLog(@"*** Deleting all tasks");
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (EWTaskItem *t in [self getTasksByPerson:[EWPersonStore meInContext:localContext]]) {
            //post notification
            dispatch_async(dispatch_get_main_queue(), ^{
                EWTaskItem *task = (EWTaskItem *)[[EWDataStore mainContext] objectWithID:t.objectID];
                [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDeleteNotification object:task userInfo:@{kLocalTaskKey: t}];
            });
            
            //cancel local notif
            [self cancelNotificationForTask:t];
            //delete
            [t.managedObjectContext deleteObject:t];
        }

    } completion:^(BOOL success, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTaskNewNotification object:self userInfo:nil];
    }];
    
   
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
    
    //delete remaining alarm timer
    for (UILocalNotification *ln in notifications) {
        if ([ln.userInfo[kLocalNotificationTypeKey] isEqualToString:kLocalNotificationTypeAlarmTimer]) {
            
            NSLog(@"Unmatched alarm notification deleted (%@) ", ln.fireDate.date2detailDateString);
            [[UIApplication sharedApplication] cancelLocalNotification:ln];
        }
        
    }
    
    //schedule sleep timer
    [EWTaskStore scheduleSleepNotificationForTask:task];
    
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
    NSParameterAssert([NSThread isMainThread]);
    NSMutableArray *allNotification = [[[UIApplication sharedApplication] scheduledLocalNotifications] mutableCopy];
    NSArray *tasks = [self getTasksByPerson:me];

    NSLog(@"There are %ld scheduled local notification and %ld stored task info", (long)allNotification.count, (long)tasks.count);
    
    //delete redundant alarm notif
    for (EWTaskItem *task in tasks) {
        [self scheduleNotificationForTask:task];
        NSArray *notifs= [self localNotificationForTask:task];
        [allNotification removeObjectsInArray:notifs];
    }
    
    for (UILocalNotification *aNotif in allNotification) {

        NSLog(@"===== Deleted %@ (%@) =====", aNotif.userInfo[kLocalNotificationTypeKey], aNotif.fireDate.date2detailDateString);
        [[UIApplication sharedApplication] cancelLocalNotification:aNotif];
    
    }
    
    if (allNotification.count > 0) {
        //make sure the redundent notif didn't block
        [self checkScheduledNotifications];
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
    BOOL good = YES;
    
    BOOL completed = task.completed || [[NSDate date] timeIntervalSinceDate: task.time] > kMaxWakeTime;
    if (completed) {
        if(task.alarm){
            task.alarm = nil;
        }
        
        if (task.owner) {
            task.owner = nil;
            //good = NO;
            NSLog(@"*** task (%@) completed, shoundn't have owner", task.serverID);
        }
        if (!task.pastOwner) {
            NSLog(@"*** task missing pastOwner: %@", task);
            task.pastOwner = [EWPersonStore meInContext:task.managedObjectContext];
            //good = NO;
        }else if(!task.pastOwner.isMe){
            //NSParameterAssert(task.pastOwner.isMe);
            NSLog(@"*** Uploading task(%@) that is not owned by me, please check!", task.serverID);
        }
        
    }else{
        //NSParameterAssert(task.alarm);
        
        if (!task.alarm) {
            PFObject *PO = task.parseObject;
            PFObject *aPO = PO[@"alarm"];
            if (aPO) {
                task.alarm = (EWAlarmItem *)[aPO managedObjectInContext:task.managedObjectContext];
            }else{
                good = NO;
                NSLog(@"*** task (%@) missing alarm", task.serverID);
            }
            
        }
        
        if (task.pastOwner) {
            task.pastOwner = nil;
            //good = NO;
            NSLog(@"*** task (%@) incomplete, shoundn't have past owner", task.serverID);
        }
        
        if (!task.owner) {
            task.owner = task.alarm.owner;
            //good = NO;
            NSLog(@"*** task (%@) missing owner", task.serverID);
        }else if(!task.owner.isMe){
            //NSParameterAssert(task.owner.isMe);
            NSLog(@"*** validation task(%@) that is not owned by me, please check!", task.serverID);
        }
    }
    
    if (!task.time) {
        PFObject *PO = task.parseObject;
        if (PO[@"time"]) {
            task.time = PO[@"time"];
        }else{
            good = NO;
            NSLog(@"*** task missing time: %@", task);
        }
        
    }
    
    if (!good) {
        if (task.updatedAt.timeElapsed > kStalelessInterval) {
            [[EWTaskStore sharedInstance] removeTask:task];
        }else{
            [[EWTaskStore sharedInstance] scheduleTasksInBackground];
        }
    }
    
    return good;
}


#pragma mark - Sleep notification
+ (void)updateSleepNotification{
    //cancel all sleep notification first
    [EWTaskStore cancelSleepNotification];
    
    for (EWTaskItem *task in me.tasks) {
        [EWTaskStore scheduleSleepNotificationForTask:task];
    }
}

+ (void)scheduleSleepNotificationForTask:(EWTaskItem *)task{
    NSNumber *duration = me.preference[@"SleepDuration"];
    float d = duration.floatValue;
    NSDate *sleepTime = [task.time dateByAddingTimeInterval:-d*3600];
    
    //cancel if no change
    NSArray *notifs = [[EWTaskStore sharedInstance] localNotificationForTask:task];
    for (UILocalNotification *notif in notifs) {
        if ([notif.userInfo[kLocalNotificationTypeKey] isEqualToString:kLocalNotificationTypeSleepTimer]) {
            if ([notif.fireDate isEqualToDate:sleepTime]) {
                //nothing to do
                return;
            }else{
                [[UIApplication sharedApplication] cancelLocalNotification:notif];
            }
        }
    }
    
    //local notification
    UILocalNotification *sleepNotif = [[UILocalNotification alloc] init];
    sleepNotif.fireDate = sleepTime;
    sleepNotif.timeZone = [NSTimeZone systemTimeZone];
    sleepNotif.alertBody = [NSString stringWithFormat:@"It's time to sleep, press here to enter sleep mode (%@)", sleepTime.date2String];
    sleepNotif.alertAction = @"Sleep";
    sleepNotif.repeatInterval = NSWeekCalendarUnit;
    sleepNotif.soundName = @"sleep mode.caf";
    sleepNotif.userInfo = @{kLocalTaskKey: task.objectID.URIRepresentation.absoluteString,
                            kLocalNotificationTypeKey: kLocalNotificationTypeSleepTimer};
    
    [[UIApplication sharedApplication] scheduleLocalNotification:sleepNotif];
    NSLog(@"Sleep notification schedule at %@", sleepNotif.fireDate.date2detailDateString);
}

+ (void)cancelSleepNotification{
    NSArray *sleeps = [UIApplication sharedApplication].scheduledLocalNotifications;
    NSInteger n = 0;
    for (UILocalNotification *sleep in sleeps) {
        if ([sleep.userInfo[kLocalNotificationTypeKey] isEqualToString:kLocalNotificationTypeSleepTimer]) {
            [[UIApplication sharedApplication] cancelLocalNotification:sleep];
            n++;
        }
    }
    NSLog(@"Cancelled %ld sleep notification", (long)n);
}


#pragma mark - Schedule Alarm Timer

+ (void)scheduleNotificationOnServerWithTimer:(EWTaskItem *)task;{
    if (!task.time || !task.objectId) {
        NSLog(@"*** The Task on %@ (%@) you passed in doesn't have time or objectId", task.time.weekday, task.objectId);
        [[EWTaskStore sharedInstance] scheduleTasksInBackground];
        return;
    }
    if ([[task time] timeIntervalSinceNow] < 0) {
        // task outDate
        return;
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
   
    [manager.requestSerializer setValue:kParseApplicationId forHTTPHeaderField:@"X-Parse-Application-Id"];
    [manager.requestSerializer setValue:kParseRestAPIId forHTTPHeaderField:@"X-Parse-REST-API-Key"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    

    NSDictionary *dic = @{@"where":@{kUsername:me.username},

                          @"push_time":[NSNumber numberWithDouble:[task.time timeIntervalSince1970] ],
                          @"data":@{@"alert":@"Time to get up",
                                   @"content-available":@1,
                                   kPushTypeKey: kPushTypeTimerKey,
                                  kPushTaskKey: task.objectId},
                         };
    
    [manager POST:kParsePushUrl parameters:dic
         success:^(AFHTTPRequestOperation *operation,id responseObject) {
             
             NSLog(@"Schedule push success: %@", responseObject);
             
             
         }failure:^(AFHTTPRequestOperation *operation,NSError *error) {
             
             NSLog(@"Schedule Push Error: %@", error);
             
         }];
    
}

@end
