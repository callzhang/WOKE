//
//  EWTaskStore.h
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWPerson, EWTaskItem, EWAlarmItem;

@interface EWTaskStore : NSObject <NSKeyedArchiverDelegate>
@property (nonatomic) NSManagedObjectContext *context;

/**
 Contains all tasks scheduled as alarm for current user
 */
@property (retain, nonatomic) NSMutableArray *allTasks;

/**
 Time stamp of last checked.
 @discussion: Used to determin if another check is needed.
 */
@property (nonatomic) NSDate *lastChecked;

+ (EWTaskStore *)sharedInstance;
//find
- (NSArray *)getTasksByPerson:(EWPerson *)person;
- (EWTaskItem *)nextTaskAtDayCount:(NSInteger)n ForPerson:(EWPerson *)person;
- (NSArray *)pastTasksByPerson:(EWPerson *)person;

//Schedule
/**
 This method schedules tasks. It goes from last task time to the possible future tasks defined by Alarms and nWeeksToScheduleTask, to create tasks needed.
 */
- (NSArray *)scheduleTasks;

//KVO
- (void)updateTaskState:(NSNotification *)notif;
- (void)updateTaskTime:(NSNotification *)notif;

//delete (delete only happens at change alarm, never delete all tasks)
- (void)removeTask:(EWTaskItem *)task;
- (void)deleteAllTasks;//debug only

//local Notification
- (void)scheduleNotificationForTask:(EWTaskItem *)task;
- (void)cancelNotificationForTask:(EWTaskItem *)task;

//check
- (void)checkScheduledNotifications;

/**
Checks the tasks relation from EWPerson. If task is in the past, this method moves it to Person.pastTasks relation, and schedule new task.
*/
- (BOOL)checkTasks;

@end
