//
//  EWAlarmItem.h
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_EWAlarmItem.h"

@interface EWAlarmItem : NSManagedObject {}
@property (nonatomic, retain) NSString * alarmDescription;
@property (nonatomic, retain) NSDate * createddate;
@property (nonatomic, retain) NSString * ewalarmitem_id;
@property (nonatomic, retain) NSNumber * important;
@property (nonatomic, retain) NSDate * lastmoddate;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSString * todo;
@property (nonatomic, retain) NSString * tone;
@property (nonatomic, retain) EWPerson *owner;
@property (nonatomic, retain) NSSet *tasks;
@end
 
@interface EWAlarmItem (CoreDataGeneratedAccessors)

- (void)addTasksObject:(EWTaskItem *)value;
- (void)removeTasksObject:(EWTaskItem *)value;
- (void)addTasks:(NSSet *)values;
- (void)removeTasks:(NSSet *)values;

@end