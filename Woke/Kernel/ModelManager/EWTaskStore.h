//
//  EWTaskStore.h
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWPerson, EWTaskItem, EWAlarmItem;

#define kTaskUpdateInterval         3600 * 24

@interface EWTaskStore : NSObject <NSKeyedArchiverDelegate>
@property BOOL isCheckingTask;

#pragma mark - Search Task
/**
 Contains all tasks scheduled as alarm for current user
 */
//@property (retain, nonatomic) NSArray *allTasks;

+ (EWTaskStore *)sharedInstance;
//find
/**
 get future task for person
 */
- (NSArray *)getTasksByPerson:(EWPerson *)person;

/**
 Shortcut for all tasks from current user
 */
+ (NSArray *)myTasks;

/**
 get task for next n'th day
 */
- (EWTaskItem *)nextTaskAtDayCount:(NSInteger)n ForPerson:(EWPerson *)person;
/**
 Get task for next day
 */
- (EWTaskItem *)nextValidTaskForPerson:(EWPerson *)person;
- (EWTaskItem *)nextNth:(NSInteger)n validTaskForPerson:(EWPerson *)person;
/**
 Main method for getting task:
 First decide if a fetch is needed. A fetch is needed if
 1) It is not current user
 2) OR It is current user but timed out
 
 After fetch or get, Filter the tasks by current time. If User's task has less then 7n that are 'current', tasks need to reschedule. Call 'scheduleTask'.
 */
- (NSArray *)pastTasksByPerson:(EWPerson *)person;
- (EWTaskItem *)getTaskByID:(NSString *)taskID;

#pragma mark - Schedule
/**
 This method schedules tasks. It goes from last task time to the possible future tasks defined by Alarms and nWeeksToScheduleTask, to create tasks needed.
 
 When new tasks created, notification of kTaskNewNotification is sent and causes main alarmVC to refresh its task page view
 */
- (NSArray *)scheduleTasks;

#pragma mark - KVO
- (void)updateTaskState:(NSNotification *)notif;
- (void)updateTaskTime:(NSNotification *)notif;
- (void)updateNotifTone:(NSNotification *)notif;
- (void)updateTaskMedia:(NSNotification *)notif;
- (void)alarmRemoved:(NSNotification *)notif;

#pragma mark - delete 
//(delete only happens at change alarm, never delete all tasks)
- (void)removeTask:(EWTaskItem *)task;
- (void)deleteAllTasks;//debug only

#pragma mark - local Notification
/**
 Schedule local notifications for task
 1. Find all scheduled notif
 2. Find all time-matched notif
 3. Delete those not matched
 */
- (void)scheduleNotificationForTask:(EWTaskItem *)task;
- (void)cancelNotificationForTask:(EWTaskItem *)task;
- (NSArray *)localNotificationForTask:(EWTaskItem *)task;
/**
 Check all scheduled Notification
 1. Get all scheduled local notification
 2. Add new notif if not scheduled by time-matching
 3. Delete unmatched local notif
 */
- (void)checkScheduledNotifications;
/**
 Fire a instant alarm for task
 */
- (void)fireAlarmForTask:(EWTaskItem *)task;

#pragma mark - check
- (NSInteger)numberOfVoiceInTask:(EWTaskItem *)task;

@end
