// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWPerson.h instead.

#import <CoreData/CoreData.h>
#import "EWServerObject.h"

extern const struct EWPersonAttributes {
	__unsafe_unretained NSString *bgImage;
	__unsafe_unretained NSString *birthday;
	__unsafe_unretained NSString *cachedInfo;
	__unsafe_unretained NSString *city;
	__unsafe_unretained NSString *email;
	__unsafe_unretained NSString *facebook;
	__unsafe_unretained NSString *gender;
	__unsafe_unretained NSString *history;
	__unsafe_unretained NSString *lastLocation;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *preference;
	__unsafe_unretained NSString *profilePic;
	__unsafe_unretained NSString *region;
	__unsafe_unretained NSString *score;
	__unsafe_unretained NSString *statement;
	__unsafe_unretained NSString *username;
	__unsafe_unretained NSString *weibo;
} EWPersonAttributes;

extern const struct EWPersonRelationships {
	__unsafe_unretained NSString *achievements;
	__unsafe_unretained NSString *alarms;
	__unsafe_unretained NSString *friends;
	__unsafe_unretained NSString *groupTasks;
	__unsafe_unretained NSString *groups;
	__unsafe_unretained NSString *groupsManaging;
	__unsafe_unretained NSString *images;
	__unsafe_unretained NSString *mediaAssets;
	__unsafe_unretained NSString *medias;
	__unsafe_unretained NSString *notifications;
	__unsafe_unretained NSString *pastTasks;
	__unsafe_unretained NSString *receivedMessages;
	__unsafe_unretained NSString *sentMessages;
	__unsafe_unretained NSString *socialGraph;
	__unsafe_unretained NSString *tasks;
	__unsafe_unretained NSString *tasksHelped;
} EWPersonRelationships;

extern const struct EWPersonFetchedProperties {
} EWPersonFetchedProperties;

@class EWAchievement;
@class EWAlarmItem;
@class EWPerson;
@class EWGroupTask;
@class EWGroup;
@class EWGroup;
@class EWImage;
@class EWMediaItem;
@class EWMediaItem;
@class EWNotification;
@class EWTaskItem;
@class EWMessage;
@class EWMessage;
@class EWSocialGraph;
@class EWTaskItem;
@class EWTaskItem;

@class NSObject;

@class NSObject;




@class NSObject;
@class NSObject;

@class NSObject;
@class NSObject;






@interface EWPersonID : NSManagedObjectID {}
@end

@interface _EWPerson : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWPersonID*)objectID;





@property (nonatomic, strong) id bgImage;



//- (BOOL)validateBgImage:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* birthday;



//- (BOOL)validateBirthday:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id cachedInfo;



//- (BOOL)validateCachedInfo:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* city;



//- (BOOL)validateCity:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* email;



//- (BOOL)validateEmail:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* facebook;



//- (BOOL)validateFacebook:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* gender;



//- (BOOL)validateGender:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id history;



//- (BOOL)validateHistory:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id lastLocation;



//- (BOOL)validateLastLocation:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id preference;



//- (BOOL)validatePreference:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id profilePic;



//- (BOOL)validateProfilePic:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* region;



//- (BOOL)validateRegion:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* score;



@property float scoreValue;
- (float)scoreValue;
- (void)setScoreValue:(float)value_;

//- (BOOL)validateScore:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* statement;



//- (BOOL)validateStatement:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* username;



//- (BOOL)validateUsername:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* weibo;



//- (BOOL)validateWeibo:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *achievements;

- (NSMutableSet*)achievementsSet;




@property (nonatomic, strong) NSSet *alarms;

- (NSMutableSet*)alarmsSet;




@property (nonatomic, strong) NSSet *friends;

- (NSMutableSet*)friendsSet;




@property (nonatomic, strong) NSSet *groupTasks;

- (NSMutableSet*)groupTasksSet;




@property (nonatomic, strong) NSSet *groups;

- (NSMutableSet*)groupsSet;




@property (nonatomic, strong) NSSet *groupsManaging;

- (NSMutableSet*)groupsManagingSet;




@property (nonatomic, strong) NSSet *images;

- (NSMutableSet*)imagesSet;




@property (nonatomic, strong) NSSet *mediaAssets;

- (NSMutableSet*)mediaAssetsSet;




@property (nonatomic, strong) NSSet *medias;

- (NSMutableSet*)mediasSet;




@property (nonatomic, strong) NSSet *notifications;

- (NSMutableSet*)notificationsSet;




@property (nonatomic, strong) NSSet *pastTasks;

- (NSMutableSet*)pastTasksSet;




@property (nonatomic, strong) NSSet *receivedMessages;

- (NSMutableSet*)receivedMessagesSet;




@property (nonatomic, strong) NSSet *sentMessages;

- (NSMutableSet*)sentMessagesSet;




@property (nonatomic, strong) EWSocialGraph *socialGraph;

//- (BOOL)validateSocialGraph:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet *tasks;

- (NSMutableSet*)tasksSet;




@property (nonatomic, strong) NSSet *tasksHelped;

- (NSMutableSet*)tasksHelpedSet;





@end

@interface _EWPerson (CoreDataGeneratedAccessors)

- (void)addAchievements:(NSSet*)value_;
- (void)removeAchievements:(NSSet*)value_;
- (void)addAchievementsObject:(EWAchievement*)value_;
- (void)removeAchievementsObject:(EWAchievement*)value_;

- (void)addAlarms:(NSSet*)value_;
- (void)removeAlarms:(NSSet*)value_;
- (void)addAlarmsObject:(EWAlarmItem*)value_;
- (void)removeAlarmsObject:(EWAlarmItem*)value_;

- (void)addFriends:(NSSet*)value_;
- (void)removeFriends:(NSSet*)value_;
- (void)addFriendsObject:(EWPerson*)value_;
- (void)removeFriendsObject:(EWPerson*)value_;

- (void)addGroupTasks:(NSSet*)value_;
- (void)removeGroupTasks:(NSSet*)value_;
- (void)addGroupTasksObject:(EWGroupTask*)value_;
- (void)removeGroupTasksObject:(EWGroupTask*)value_;

- (void)addGroups:(NSSet*)value_;
- (void)removeGroups:(NSSet*)value_;
- (void)addGroupsObject:(EWGroup*)value_;
- (void)removeGroupsObject:(EWGroup*)value_;

- (void)addGroupsManaging:(NSSet*)value_;
- (void)removeGroupsManaging:(NSSet*)value_;
- (void)addGroupsManagingObject:(EWGroup*)value_;
- (void)removeGroupsManagingObject:(EWGroup*)value_;

- (void)addImages:(NSSet*)value_;
- (void)removeImages:(NSSet*)value_;
- (void)addImagesObject:(EWImage*)value_;
- (void)removeImagesObject:(EWImage*)value_;

- (void)addMediaAssets:(NSSet*)value_;
- (void)removeMediaAssets:(NSSet*)value_;
- (void)addMediaAssetsObject:(EWMediaItem*)value_;
- (void)removeMediaAssetsObject:(EWMediaItem*)value_;

- (void)addMedias:(NSSet*)value_;
- (void)removeMedias:(NSSet*)value_;
- (void)addMediasObject:(EWMediaItem*)value_;
- (void)removeMediasObject:(EWMediaItem*)value_;

- (void)addNotifications:(NSSet*)value_;
- (void)removeNotifications:(NSSet*)value_;
- (void)addNotificationsObject:(EWNotification*)value_;
- (void)removeNotificationsObject:(EWNotification*)value_;

- (void)addPastTasks:(NSSet*)value_;
- (void)removePastTasks:(NSSet*)value_;
- (void)addPastTasksObject:(EWTaskItem*)value_;
- (void)removePastTasksObject:(EWTaskItem*)value_;

- (void)addReceivedMessages:(NSSet*)value_;
- (void)removeReceivedMessages:(NSSet*)value_;
- (void)addReceivedMessagesObject:(EWMessage*)value_;
- (void)removeReceivedMessagesObject:(EWMessage*)value_;

- (void)addSentMessages:(NSSet*)value_;
- (void)removeSentMessages:(NSSet*)value_;
- (void)addSentMessagesObject:(EWMessage*)value_;
- (void)removeSentMessagesObject:(EWMessage*)value_;

- (void)addTasks:(NSSet*)value_;
- (void)removeTasks:(NSSet*)value_;
- (void)addTasksObject:(EWTaskItem*)value_;
- (void)removeTasksObject:(EWTaskItem*)value_;

- (void)addTasksHelped:(NSSet*)value_;
- (void)removeTasksHelped:(NSSet*)value_;
- (void)addTasksHelpedObject:(EWTaskItem*)value_;
- (void)removeTasksHelpedObject:(EWTaskItem*)value_;

@end

@interface _EWPerson (CoreDataGeneratedPrimitiveAccessors)


- (id)primitiveBgImage;
- (void)setPrimitiveBgImage:(id)value;




- (NSDate*)primitiveBirthday;
- (void)setPrimitiveBirthday:(NSDate*)value;




- (id)primitiveCachedInfo;
- (void)setPrimitiveCachedInfo:(id)value;




- (NSString*)primitiveCity;
- (void)setPrimitiveCity:(NSString*)value;




- (NSString*)primitiveEmail;
- (void)setPrimitiveEmail:(NSString*)value;




- (NSString*)primitiveFacebook;
- (void)setPrimitiveFacebook:(NSString*)value;




- (NSString*)primitiveGender;
- (void)setPrimitiveGender:(NSString*)value;




- (id)primitiveHistory;
- (void)setPrimitiveHistory:(id)value;




- (id)primitiveLastLocation;
- (void)setPrimitiveLastLocation:(id)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (id)primitivePreference;
- (void)setPrimitivePreference:(id)value;




- (id)primitiveProfilePic;
- (void)setPrimitiveProfilePic:(id)value;




- (NSString*)primitiveRegion;
- (void)setPrimitiveRegion:(NSString*)value;




- (NSNumber*)primitiveScore;
- (void)setPrimitiveScore:(NSNumber*)value;

- (float)primitiveScoreValue;
- (void)setPrimitiveScoreValue:(float)value_;




- (NSString*)primitiveStatement;
- (void)setPrimitiveStatement:(NSString*)value;




- (NSString*)primitiveUsername;
- (void)setPrimitiveUsername:(NSString*)value;




- (NSString*)primitiveWeibo;
- (void)setPrimitiveWeibo:(NSString*)value;





- (NSMutableSet*)primitiveAchievements;
- (void)setPrimitiveAchievements:(NSMutableSet*)value;



- (NSMutableSet*)primitiveAlarms;
- (void)setPrimitiveAlarms:(NSMutableSet*)value;



- (NSMutableSet*)primitiveFriends;
- (void)setPrimitiveFriends:(NSMutableSet*)value;



- (NSMutableSet*)primitiveGroupTasks;
- (void)setPrimitiveGroupTasks:(NSMutableSet*)value;



- (NSMutableSet*)primitiveGroups;
- (void)setPrimitiveGroups:(NSMutableSet*)value;



- (NSMutableSet*)primitiveGroupsManaging;
- (void)setPrimitiveGroupsManaging:(NSMutableSet*)value;



- (NSMutableSet*)primitiveImages;
- (void)setPrimitiveImages:(NSMutableSet*)value;



- (NSMutableSet*)primitiveMediaAssets;
- (void)setPrimitiveMediaAssets:(NSMutableSet*)value;



- (NSMutableSet*)primitiveMedias;
- (void)setPrimitiveMedias:(NSMutableSet*)value;



- (NSMutableSet*)primitiveNotifications;
- (void)setPrimitiveNotifications:(NSMutableSet*)value;



- (NSMutableSet*)primitivePastTasks;
- (void)setPrimitivePastTasks:(NSMutableSet*)value;



- (NSMutableSet*)primitiveReceivedMessages;
- (void)setPrimitiveReceivedMessages:(NSMutableSet*)value;



- (NSMutableSet*)primitiveSentMessages;
- (void)setPrimitiveSentMessages:(NSMutableSet*)value;



- (EWSocialGraph*)primitiveSocialGraph;
- (void)setPrimitiveSocialGraph:(EWSocialGraph*)value;



- (NSMutableSet*)primitiveTasks;
- (void)setPrimitiveTasks:(NSMutableSet*)value;



- (NSMutableSet*)primitiveTasksHelped;
- (void)setPrimitiveTasksHelped:(NSMutableSet*)value;


@end
