//
//  EWPerson.h
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "StackMob.h"
#import <MapKit/MapKit.h>

@class EWTaskItem, EWAlarmItem, EWGroup, EWGroupTask, EWMediaItem, EWMessage, EWAchievement;

@interface EWPerson : SMUserManagedObject {}
@property (nonatomic, retain) NSSet * achievements;
@property (nonatomic, retain) NSString * aws_id;
@property (nonatomic, retain) NSString * bgImageKey;
@property (nonatomic, retain) NSDate * birthday;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSDate * createddate;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * facebook;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) id lastLocation;
@property (nonatomic, retain) NSDate * lastmoddate;
@property (nonatomic, retain) NSDate * lastSeenDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id preference;
@property (nonatomic, retain) NSString * profilePicKey;
@property (nonatomic, retain) NSString * region;
@property (nonatomic, retain) NSString * statement;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * weibo;
//relation
@property (nonatomic, retain) NSSet *alarms;
@property (nonatomic, retain) NSSet *friends;
@property (nonatomic, retain) NSSet *friended; //shadow relation acted as reverse of friends relation, should never be called
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) NSSet *groupsManaging;
@property (nonatomic, retain) NSSet *groupTasks;
@property (nonatomic, retain) NSSet *medias;
@property (nonatomic, retain) NSSet *pastTasks;
@property (nonatomic, retain) NSSet *receivedMessages;
@property (nonatomic, retain) NSSet *sentMessages;
@property (nonatomic, retain) NSSet *tasks;
@property (nonatomic, retain) NSSet *tasksHelped;

//local properties
@property (nonatomic) UIImage *profilePic;
@property (nonatomic) UIImage *bgImage;


- (id)initNewUserInContext:(NSManagedObjectContext *)context;

@end

@interface EWPerson (CoreDataGeneratedAccessors)

- (void)addAchievementsObject:(EWAchievement *)value;
- (void)removeAchievementsObject:(EWAchievement *)value;
- (void)addAchievements:(NSSet *)values;
- (void)removeAchievements:(NSSet *)values;

/*
- (void)insertObject:(EWAlarmItem *)value inAlarmsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAlarmsAtIndex:(NSUInteger)idx;
- (void)insertAlarms:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAlarmsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAlarmsAtIndex:(NSUInteger)idx withObject:(EWAlarmItem *)value;
- (void)replaceAlarmsAtIndexes:(NSIndexSet *)indexes withAlarms:(NSArray *)values;*/
- (void)addAlarmsObject:(EWAlarmItem *)value;
- (void)removeAlarmsObject:(EWAlarmItem *)value;
- (void)addAlarms:(NSOrderedSet *)values;
- (void)removeAlarms:(NSOrderedSet *)values;

- (void)addFriendsObject:(EWPerson *)value;
- (void)removeFriendsObject:(EWPerson *)value;
- (void)addFriends:(NSSet *)values;
- (void)removeFriends:(NSSet *)values;

- (void)addFriendedObject:(EWPerson *)value;
- (void)removeFriendedObject:(EWPerson *)value;
- (void)addFriended:(NSSet *)values;
- (void)removeFriended:(NSSet *)values;

- (void)addGroupsObject:(EWGroup *)value;
- (void)removeGroupsObject:(EWGroup *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;

- (void)addGroupsManagingObject:(EWGroup *)value;
- (void)removeGroupsManagingObject:(EWGroup *)value;
- (void)addGroupsManaging:(NSSet *)values;
- (void)removeGroupsManaging:(NSSet *)values;

- (void)addGroupTasksObject:(EWGroupTask *)value;
- (void)removeGroupTasksObject:(EWGroupTask *)value;
- (void)addGroupTasks:(NSSet *)values;
- (void)removeGroupTasks:(NSSet *)values;

- (void)addMediasObject:(EWMediaItem *)value;
- (void)removeMediasObject:(EWMediaItem *)value;
- (void)addMedias:(NSSet *)values;
- (void)removeMedias:(NSSet *)values;

- (void)addReceivedMessagesObject:(EWMessage *)value;
- (void)removeReceivedMessagesObject:(EWMessage *)value;
- (void)addReceivedMessages:(NSSet *)values;
- (void)removeReceivedMessages:(NSSet *)values;

- (void)addSentMessagesObject:(EWMessage *)value;
- (void)removeSentMessagesObject:(EWMessage *)value;
- (void)addSentMessages:(NSSet *)values;
- (void)removeSentMessages:(NSSet *)values;
/*
- (void)insertObject:(EWTaskItem *)value inTasksAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTasksAtIndex:(NSUInteger)idx;
- (void)insertTasks:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTasksAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTasksAtIndex:(NSUInteger)idx withObject:(EWTaskItem *)value;
- (void)replaceTasksAtIndexes:(NSIndexSet *)indexes withTasks:(NSArray *)values;*/
- (void)addTasksObject:(EWTaskItem *)value;
- (void)removeTasksObject:(EWTaskItem *)value;
- (void)addTasks:(NSOrderedSet *)values;
- (void)removeTasks:(NSOrderedSet *)values;

- (void)addPastTasksObject:(EWTaskItem *)value;
- (void)removePastTasksObject:(EWTaskItem *)value;
- (void)addPastTasks:(NSSet *)values;
- (void)removePastTasks:(NSSet *)values;

- (void)addTasksHelpedObject:(EWTaskItem *)value;
- (void)removeTasksHelpedObject:(EWTaskItem *)value;
- (void)addTasksHelped:(NSSet *)values;
- (void)removeTasksHelped:(NSSet *)values;

@end
