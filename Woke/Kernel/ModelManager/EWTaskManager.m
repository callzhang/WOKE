 //
//  EWTaskStore.m
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

//#import "EWTaskManager.h"
#import "EWPerson.h"
#import "EWMedia.h"
#import "EWMediaManager.h"
//#import "EWTaskItem.h"
#import "EWAlarm.h"
#import "EWAlarmManager.h"
#import "EWDataStore.h"
#import "EWUserManagement.h"
#import "EWPersonManager.h"
#import "AFNetworking.h"
#import "EWStatisticsManager.h"
#import "EWWakeUpManager.h"

@implementation EWTaskManager
@synthesize isSchedulingTask = _isSchedulingTask;

+(EWTaskManager *)sharedInstance{
    
    //make sure core data stuff is always on main thread
    //NSParameterAssert([NSThread isMainThread]);
    
    static EWTaskManager *sharedTaskStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTaskStore_ = [[EWTaskManager alloc] init];
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
    });
    return sharedTaskStore_;
}

#pragma mark - threading
- (BOOL)isSchedulingTask{
    @synchronized(self){
        return _isSchedulingTask;
    }
}

- (void)setIsSchedulingTask:(BOOL)isSchedulingTask{
    @synchronized(self){
        _isSchedulingTask = isSchedulingTask;
    }
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
    NSArray *tasks = [[EWTaskManager sharedInstance] getTasksByPerson:[EWSession sharedSession].currentUser];
    for (EWTaskItem *task in tasks) {
        [task addObserver:[EWTaskManager sharedInstance] forKeyPath:@"owner" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    return tasks;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[EWTaskItem class]]) {
        EWTaskItem *task = (EWTaskItem *)object;
        if ([keyPath isEqualToString:@"owner"]) {
            if ([change objectForKey:NSKeyValueChangeNewKey] == nil) {
                //check why the new value is nil
                BOOL completed  = task.completed || task.time.timeElapsed > kMaxWakeTime;
                NSAssert(completed, @"*** Something wrong, the task's owner has been set to nil, check the call stack.");
            }
            
        }
    }
}

- (NSArray *)pastTasksByPerson:(EWPerson *)person{
    
    //because the pastTask is not a static relationship, i.e. the set of past tasks need to be updated timely, we try to pull data from Query first and save them to person
    //get from local cache if self or time elapsed since last update is shorter than predefined interval
    if (!person.isMe) {
        return [NSArray new];
    }
    [person.managedObjectContext refreshObject:person mergeChanges:YES];
    NSMutableArray *tasks = [[person.pastTasks allObjects] mutableCopy];
    [tasks sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]]];
    
    return [tasks copy];
}

#pragma mark - Next task
//next valid task
- (EWTaskItem *)nextValidTaskForPerson:(EWPerson *)person{
    return [self nextNth:0 validTaskForPerson:person];
}

- (EWTaskItem *)nextNth:(NSInteger)n validTaskForPerson:(EWPerson *)person{
    NSArray *tasks = [self getTasksByPerson:person];
    EWTaskItem *nextTask;
    for (unsigned i=0; i<tasks.count; i++) {
        nextTask = tasks[i];
		BOOL finished = nextTask.completed || [nextTask.time timeIntervalSinceNow]<-kMaxWakeTime;
        //Task shoud be On AND not finished
        if (nextTask.state == YES && !finished) {
			n--;
			if (n < 0) {
				//find the task
				return nextTask;
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
    
    EWTaskItem *task = (EWTaskItem *)[EWSync managedObjectWithClass:@"EWTaskItem" withID:taskID];
    return task;
}


#pragma mark - SCHEDULE
- (NSArray *)scheduleTasks{
    NSParameterAssert([NSThread isMainThread]);
    if (self.isSchedulingTask) {
        NSLog(@"It is already checking task, skip!");
        return nil;
    }
    [self scheduleTasksInContext:mainContext];
    NSArray *myTasks = [self getTasksByPerson:[EWSession sharedSession].currentUser];
    return myTasks;
}


- (void)scheduleTasksInBackgroundWithCompletion:(void (^)(void))block{
    NSParameterAssert([NSThread isMainThread]);
    
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        [self scheduleTasksInContext:localContext];
    }completion:^(BOOL success, NSError *error) {
        if (block) {
            block();
        }
    }];
    
}

//schedule new task in the future
- (NSArray *)scheduleTasksInContext:(NSManagedObjectContext *)context{
    NSParameterAssert(context);
    if (self.isSchedulingTask) {
        NSLog(@"It is already checking task, skip!");
        return nil;
    }
    
    //Also stop scheduling if is waking
    BOOL isWakingUp = [EWWakeUpManager sharedInstance].isWakingUp;
    if (isWakingUp) {
        NSLog(@"Waking up, skip scheduling tasks");
        return nil;
    }

    self.isSchedulingTask = YES;
    
    //check necessity
    EWPerson *localPerson = [[EWSession sharedSession].currentUser inContext:context];
    NSMutableArray *tasks = [localPerson.tasks mutableCopy];
    NSArray *alarms = [[EWAlarmManager sharedInstance] alarmsForUser:localPerson];
    if (alarms.count != 7) {
        NSLog(@"Something wrong with my alarms， only (%d) found when scheduling task", alarms.count);
        self.isSchedulingTask = NO;
        return nil;
    }
    
    if (alarms.count == 0 && tasks.count == 0) {
        NSLog(@"Forfeit sccheduling task due to no alarm and task exists");
        self.isSchedulingTask = NO;
        return nil;
    }
    
    NSMutableArray *newTask = [NSMutableArray new];
    
    //Check task from server if not desired number
    if (tasks.count != 7 * nWeeksToScheduleTask && !self.lastChecked.isUpToDated) {
        //cannot check my task from server, which will cause checking / schedule cycle
        NSLog(@"My task count is %lu, checking from server!", (unsigned long)tasks.count);
        //this approach is a last resort to fetch task by owner
        PFQuery *taskQuery= [PFQuery queryWithClassName:@"EWTaskItem"];
        [taskQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
        [taskQuery whereKey:kParseObjectID notContainedIn:[tasks valueForKey:kParseObjectID]];
        NSArray *objects = [EWSync findServerObjectWithQuery:taskQuery];
        for (PFObject *t in objects) {
            EWTaskItem *task = (EWTaskItem *)[t managedObjectInContext:context];
            [task refresh];
            task.owner = [[EWSession sharedSession].currentUser inContext:context];
            BOOL good = [EWTaskManager validateTask:task];
            if (!good) {
                [self removeTask:task];
            }else if (![tasks containsObject:task]) {
                [tasks addObject:task];
                [newTask addObject:task];
                // add schedule notification
                [EWTaskManager scheduleNotificationOnServerForTask:task];
                
                NSLog(@"New task found from server: %@(%@)", task.time.weekday, t.objectId);
            }
        }
    }

    //FIRST check past tasks
    BOOL hasOutDatedTask = [self checkPastTasksInContext:context];
    if (hasOutDatedTask) {
        //need to make sure the task is up to date
        tasks = [localPerson.tasks mutableCopy];
    }
    
    //for each alarm, find matching task, or create new task
    NSMutableArray *goodTasks = [NSMutableArray new];
    
    for (EWAlarm *a in alarms){//loop through alarms
        
        for (unsigned i=0; i<nWeeksToScheduleTask; i++) {//loop for week
            
            //first find
            
            
            //next time for alarm, this is what the time should be there
            NSDate *time = [a.time nextOccurTime:i withDevidingPoint:-kMaxWakeTime];
			DDLogVerbose(@"Checking for alarm time: %@", time);
            BOOL taskMatched = NO;
            //loop through the tasks to verify the target time has been scheduled
            for (EWTaskItem *t in tasks) {
                if (abs([t.time timeIntervalSinceDate:time]) < 10) {
                    BOOL good = [EWTaskManager validateTask:t];
                    //find the task, move to good task
                    if (good) {
                        [goodTasks addObject:t];
                        [tasks removeObject:t];
                        if (t.alarm != a) {
                            DDLogError(@"Task miss match to another alarm: Task:%@ Alarm:%@", t, a);
                            t.alarm = a;
                        }
                        taskMatched = YES;
                        //break here to avoid creating new task
                        break;
                    }else{
                        DDLogError(@"*** Task failed validation: %@", t);
                    }
                    
                }else if (abs([t.time timeIntervalSinceDate:time]) < 100){
                    DDLogError(@"*** Time mismatch");
                }
            }
            
            if (!taskMatched) {
                //start scheduling task
                DDLogInfo(@"Task on %@ has not been found, creating!", time);
                //new task
                EWTaskItem *t = [self newTaskInContext:context];
                //new time in the future
                time = [time nextOccurTime:0 withDevidingPoint:0];
                DDLogVerbose(@"Next task time: %@", time);
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
        DDLogError(@"Serious error: After removing valid task and past task, there are still %lu tasks left:%@", (unsigned long)tasks.count, tasks);
        for (EWTaskItem *t in tasks) {
            [self removeTask:t];
        }
    }
    
    
    
    //save
    if (hasOutDatedTask || newTask.count) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskNewNotification object:nil userInfo:nil];
        });
		//call back
		[[EWSync sharedInstance].saveCallbacks addObject:^{
            for (EWTaskItem *t in newTask) {
				EWTaskItem *task = (EWTaskItem *)[t inContext:mainContext];
                // remote notification
                [EWTaskManager scheduleNotificationOnServerForTask:task];
				//check
				DDLogInfo(@"Perform schedule task completion block: %lu alarms and %lu tasks", (unsigned long)[EWSession sharedSession].currentUser.alarms.count, (unsigned long)[EWSession sharedSession].currentUser.tasks.count);
				if ([EWSession sharedSession].currentUser.tasks.count != 7*nWeeksToScheduleTask) {
					DDLogError(@"Something wrong with my task: %@", [EWSession sharedSession].currentUser.tasks);
				}
            }
        }];
    }
    
    //last checked
    self.lastChecked = [NSDate date];
    //check if the main context is good
    [mainContext performBlockAndWait:^{
		
    }];
    
    self.isSchedulingTask = NO;
    return goodTasks;
}

- (BOOL)checkPastTasks{
    //in sync
    __block BOOL taskOutDated = NO;

    [mainContext saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        taskOutDated = [self checkPastTasksInContext:localContext];
    }];
    
    return taskOutDated;
}

- (void)checkPastTasksInBackgroundWithCompletion:(void (^)(void))block{
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        [self checkPastTasksInContext:localContext];
    }completion:^(BOOL success, NSError *error) {
        if (block) {
            block();
        }
    }];
}

- (BOOL)checkPastTasksInContext:(NSManagedObjectContext *)localContext{
    BOOL taskOutDated = NO;
    if (_lastPastTaskChecked && _lastPastTaskChecked.timeElapsed < kTaskUpdateInterval) {
        return taskOutDated;
    }
    
    NSLog(@"=== Start checking past tasks ===");
    //First get outdated current task and move to past
    EWPerson *localMe = [[EWSession sharedSession].currentUser inContext:localContext];
    NSMutableSet *tasks = localMe.tasks.mutableCopy;
    
    //nullify old task's relation to alarm
    NSPredicate *old = [NSPredicate predicateWithFormat:@"time < %@", [[NSDate date] timeByAddingSeconds:-kMaxWakeTime]];
    NSSet *outDatedTasks = [tasks filteredSetUsingPredicate:old];
    for (EWTaskItem *t in outDatedTasks) {
        t.alarm = nil;
        t.owner = nil;
        t.pastOwner = [[EWSession sharedSession].currentUser inContext:t.managedObjectContext];
        [tasks removeObject:t];
        NSLog(@"=== Task(%@) on %@ moved to past", t.objectId, [t.time date2dayString]);
        [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDeleteNotification object:t];
        taskOutDated = YES;
    }
    
    //check on server
    NSMutableArray *pastTasks = [[localMe.pastTasks allObjects] mutableCopy];
    [pastTasks sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]]];
    EWTaskItem *latestTask = pastTasks.firstObject;
    if (latestTask.time.timeElapsed > 3600*24) {
        NSLog(@"=== Checking past tasks but the latest task is outdated: %@", latestTask.time);
        if([EWSync isReachable]){
            //get from server
            NSLog(@"=== Fetch past task from server for %@", localMe.name);
            PFQuery *query = [PFQuery queryWithClassName:@"EWTaskItem"];
            //[query whereKey:@"time" lessThan:[[NSDate date] timeByAddingMinutes:-kMaxWakeTime]];
            //[query whereKey:@"state" equalTo:@YES];
            [query whereKey:kParseObjectID notContainedIn:[pastTasks valueForKey:kParseObjectID]];
            PFUser *user = [PFUser objectWithoutDataWithClassName:@"PFUser" objectId:localMe.objectId];
            [query whereKey:@"pastOwner" equalTo:user];
            [query orderBySortDescriptor:[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]];
            tasks = [[EWSync findServerObjectWithQuery:query] mutableCopy];
            //assign back to person.tasks
            for (PFObject *task in tasks) {
                EWTaskItem *taskMO = (EWTaskItem *)[task managedObjectInContext:localContext];
                [taskMO refresh];
                [pastTasks addObject:taskMO];
                [localMe addPastTasksObject:taskMO];
                taskOutDated = YES;
                NSLog(@"!!! Task found on server: %@", taskMO.time.date2dayString);
            }
        }
    }
    
    
    if (taskOutDated) {
        
        //check duplicated past tasks
        NSMutableDictionary *pastTaskDic = [NSMutableDictionary new];
        for (EWTaskItem *t in pastTasks) {
            NSString *day = t.time.date2YYMMDDString;
            if (!pastTaskDic[day]) {
                pastTaskDic[day] = t;
            }else{
                if (!t.completed) {
                    [t deleteEntityInContext:localContext];
                    DDLogWarn(@"duplicated past(%@) task deleted: %@", t.objectId, t.time);
                }else{
                    EWTaskItem *t0 = (EWTaskItem *)pastTaskDic[day];
                    NSDate *c0 = [t0 completed];
                    if (!c0 || [t.completed isEarlierThan:c0]) {
                        pastTaskDic[day] = t;
                        [t0 deleteEntityInContext:localContext];
                        DDLogWarn(@"duplicated past(%@) task deleted: %@", t.objectId, t.time);
                    }else{
                        [t deleteEntityInContext:localContext];
                        DDLogWarn(@"duplicated past(%@) task deleted: %@", t.objectId, t.time);
                    }
                }
            }
        }
        
        
        //update cached activities
        [EWStatisticsManager updateTaskActivityCacheWithCompletion:NULL];
    }

    _lastPastTaskChecked = [NSDate date];
    
    return taskOutDated;
}


- (void)completedTask:(EWTaskItem *)task{
    if (task.time.timeIntervalSinceNow>0) {
        DDLogError(@"%s passed in future task %@(%@)", __func__, task.time, task.objectId);
        return;
    }
    task.completed = [NSDate date];
    //task.pastOwner = task.owner;
    //task.owner = nil;
    //task.alarm = nil;
    DDLogVerbose(@"Completed task: %@", task.objectId);
	[self scheduleTasks];
}


#pragma mark - NEW
- (EWTaskItem *)newTaskInContext:(NSManagedObjectContext *)context{
    
    EWTaskItem *t = [EWTaskItem createEntityInContext:context];
    t.updatedAt = [NSDate date];
    //relation
    t.owner = [[EWSession sharedSession].currentUser inContext:context];
    //others
    t.createdAt = [NSDate date];
    //[EWSync save];
    
    DDLogInfo(@"Created new Task %@", t.objectID);
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


//time
- (void)updateTaskTime:(NSNotification *)notif{
    EWAlarm *a = notif.object;
    if (!a) [NSException raise:@"No alarm info" format:@"Check notification"];
    [self updateTaskTimeForAlarm:a];
}

- (void)updateTaskTimeForAlarm:(EWAlarm *)alarm{
	if (alarm.tasks.count != nWeeksToScheduleTask) {
		DDLogError(@"Serious error: alarm(%@) has incorrect number of tasks: %lu", alarm.serverID, (unsigned long)alarm.tasks.count);
        [self scheduleTasks];
        return;
	}
	NSSortDescriptor *des = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
	NSArray *sortedTasks = [alarm.tasks sortedArrayUsingDescriptors:@[des]];
    for (unsigned i=0; i<sortedTasks.count; i++) {
        EWTaskItem *t = sortedTasks[i];
        NSDate *nextTime = [alarm.time nextOccurTime:i];
        if (![t.time isEqualToDate:nextTime]) {
            t.time = nextTime;
            //local notif
            [self cancelNotificationForTask:t];
            [self scheduleNotificationForTask:t];
            //Notification
            //[[NSNotificationCenter defaultCenter] postNotificationName:kTaskChangedNotification object:t userInfo:@{@"task": t}];
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskTimeChangedNotification object:t userInfo:@{@"task": t}];
            // schedule on server
            if (t.objectId) {
                [EWTaskManager scheduleNotificationOnServerForTask:t];
            }else{
                __block EWTaskItem *blockTask = t;
                [EWSync saveWithCompletion:^{
                    [EWTaskManager scheduleNotificationOnServerForTask:blockTask];
                }];
            }
        }
    }
    [EWSync save];
}

//Tone
- (void)updateNotifTone:(NSNotification *)notif{
    EWAlarm *alarm = notif.userInfo[@"alarm"];
    
    for (EWTaskItem *t in alarm.tasks) {
        [self cancelNotificationForTask:t];
        [self scheduleNotificationForTask:t];
        NSLog(@"Notification on %@ tone updated to: %@", t.time.date2String, alarm.tone);
    }
}


- (void)alarmRemoved:(NSNotification *)notif{
    id objects = notif.object;
    NSArray *alarms;
    if ([objects isKindOfClass:[NSArray class]]) {
        alarms = objects;
    }else if ([objects isKindOfClass:[EWAlarm class]]){
        alarms = @[objects];
    }
    for (EWAlarm *alarm in alarms) {
        while (alarm.tasks.count > 0) {
            EWTaskItem *t = alarm.tasks.anyObject;
            NSLog(@"Delete task on %@ due to alarm deleted", t.time.weekday);
            [self removeTask:t];
        }
    }
    
    [EWSync save];
}


#pragma mark - DELETE
- (void)removeTask:(EWTaskItem *)task{
    NSLog(@"Task on %@ deleted", task.time.date2detailDateString);
    //test
    //[task removeObserver:self forKeyPath:@"owner"];
    
    [self cancelNotificationForTask:task];
    [task.managedObjectContext deleteObject:task];
    [task.managedObjectContext saveToPersistentStoreAndWait];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskDeleteNotification object:task userInfo:@{kLocalTaskKey: task}];
}

- (void)deleteAllTasks{
    NSLog(@"*** Deleting all tasks");
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (EWTaskItem *t in [self getTasksByPerson:[[EWSession sharedSession].currentUser inContext:localContext]]) {
            //post notification
            dispatch_async(dispatch_get_main_queue(), ^{
                EWTaskItem *task = (EWTaskItem *)[mainContext objectWithID:t.objectID];
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
    NSArray *tasks = [self getTasksByPerson:[EWSession sharedSession].currentUser];

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
    for (EWMedia *m in task.medias) {
        if ([m.type isEqualToString: kMediaTypeVoice]) {
            nMedia++;
        }
    }
    return nMedia;
}

+ (BOOL)validateTask:(EWTaskItem *)task{
    BOOL good = YES;
    
    BOOL completed = task.completed || task.time.timeElapsed > kMaxWakeTime;
    if (completed) {
        if(task.alarm){
            DDLogError(@"*** task (%@) completed, shoundn't have alarm", task.serverID);
            task.alarm = nil;
        }
        
        if (task.owner) {
            task.owner = nil;
            //good = NO;
            DDLogError(@"*** task (%@) completed, shoundn't have owner", task.serverID);
        }
        if (!task.pastOwner) {
            DDLogError(@"*** task missing pastOwner: %@", task);
            task.pastOwner = [[EWSession sharedSession].currentUser inContext:task.managedObjectContext];
            //good = NO;
        }else if(!task.pastOwner.isMe){
            //NSParameterAssert(task.pastOwner.isMe);
            DDLogError(@"*** Uploading task(%@) that is not owned by me, please check!", task.serverID);
            return NO;
        }
        
    }else{
        //NSParameterAssert(task.alarm);
        
        if (!task.alarm) {
            PFObject *PO = task.parseObject;
            PFObject *aPO = PO[@"alarm"];
            if (aPO) {
                task.alarm = (EWAlarm *)[aPO managedObjectInContext:task.managedObjectContext];
            }else{
                good = NO;
                DDLogError(@"*** task (%@) missing alarm", task.serverID);
            }
            
        }
        
        if (task.pastOwner) {
            task.pastOwner = nil;
            //good = NO;
            DDLogError(@"*** task (%@) incomplete, shoundn't have past owner", task.serverID);
        }
        
        if (!task.owner) {
            task.owner = task.alarm.owner;
            if (!task.owner) {
                task.owner = [[EWSession sharedSession].currentUser inContext:task.managedObjectContext]?:task.alarm.owner;
                if (!task.owner) {
                    DDLogError(@"*** task (%@) missing owner", task.serverID);
                }
            }
        }else if(!task.owner.isMe){
            //NSParameterAssert(task.owner.isMe);
            DDLogError(@"*** validation task(%@) that is not owned by me, please check!", task.serverID);
            return NO;
        }
    }
    
    if (!task.time) {
        PFObject *PO = task.parseObject;
        if (PO[@"time"]) {
            task.time = PO[@"time"];
        }else if (task.alarm.time){
            task.time = task.alarm.time;
        }else{
            good = NO;
            DDLogError(@"*** task missing time: %@", task.serverID);
        }
        
    }
//    
//    if (!good) {
//        if (task.updatedAt.timeElapsed > kStalelessInterval) {
//            [[EWTaskStore sharedInstance] removeTask:task];
//        }else{
//            [[EWTaskStore sharedInstance] scheduleTasksInBackgroundWithCompletion:NULL];
//        }
//    }
    
    if (!good) {
        DDLogError(@"Task failed validation: %@", task);
    }
    
    return good;
}




#pragma mark - Schedule Alarm Timer

+ (void)scheduleNotificationOnServerForTask:(EWTaskItem *)task{
    if (!task.time || !task.objectId) {
        DDLogError(@"*** The Task for schedule push doesn't have time or objectId: %@", task);
        [[EWTaskManager sharedInstance] scheduleTasksInBackgroundWithCompletion:NULL];
        return;
    }
    if ([task.time timeIntervalSinceNow] < 0) {
        // task outDate
        return;
    }
    NSString *taskID = task.serverID;
    NSDate *time = task.time;
    //check local schedule records before make the REST call
    __block NSMutableDictionary *timeTable = [[[NSUserDefaults standardUserDefaults] objectForKey:kScheduledAlarmTimers] mutableCopy] ?:[NSMutableDictionary new];
    for (NSString *objectId in timeTable.allKeys) {
        EWTaskItem *t = [EWTaskItem findFirstByAttribute:kParseObjectID withValue:objectId];
        if (t.time.timeElapsed > 0) {
            //delete from time table
            [timeTable removeObjectForKey:objectId];
            DDLogInfo(@"Past task on %@ has been removed from schedule table", t.time.date2detailDateString);
        }
    }
    //add scheduled time to task
    __block NSMutableArray *times = [[timeTable objectForKey:taskID] mutableCopy]?:[NSMutableArray new];
    if ([times containsObject:time]) {
        DDLogInfo(@"===Task (%@) timer push (%@) has already been scheduled on server, skip.", taskID, time);
        return;
    }else{
        [times addObject:time];
        [timeTable setObject:times.copy forKey:taskID];
        [[NSUserDefaults standardUserDefaults] setObject:timeTable.copy forKey:kScheduledAlarmTimers];
        DDLogInfo(@"Scheduled task timer on server: %@", times);
    }
    
    
    //============ Start scheduling task timer on server ============
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    [manager.requestSerializer setValue:kParseApplicationId forHTTPHeaderField:@"X-Parse-Application-Id"];
    [manager.requestSerializer setValue:kParseRestAPIId forHTTPHeaderField:@"X-Parse-REST-API-Key"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
    NSDictionary *dic = @{@"where":@{kUsername:[EWSession sharedSession].currentUser.username},
                          @"push_time":[NSNumber numberWithDouble:[time timeIntervalSince1970]+30],
                          @"data":@{@"alert":@"Time to get up",
                                    @"content-available":@1,
                                    kPushType: kPushTypeAlarmTimer,
                                    kPushTaskID: taskID},
                          };
    
    [manager POST:kParsePushUrl parameters:dic
          success:^(AFHTTPRequestOperation *operation,id responseObject) {
              
              DDLogVerbose(@"Schedule task timer push success for time %@", time.date2detailDateString);
              [times addObject:time];
              [timeTable setObject:times forKey:taskID];
              [[NSUserDefaults standardUserDefaults] setObject:timeTable.copy forKey:kScheduledAlarmTimers];
              
          }failure:^(AFHTTPRequestOperation *operation,NSError *error) {
              
              DDLogError(@"Schedule Push Error: %@", error);
              
    }];

}

@end
