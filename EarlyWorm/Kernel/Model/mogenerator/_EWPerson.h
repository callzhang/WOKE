// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWPerson.h instead.

#import <CoreData/CoreData.h>


extern const struct EWPersonAttributes {
	__unsafe_unretained NSString *bgImageKey;
	__unsafe_unretained NSString *birthday;
	__unsafe_unretained NSString *city;
	__unsafe_unretained NSString *createddate;
	__unsafe_unretained NSString *email;
	__unsafe_unretained NSString *facebook;
	__unsafe_unretained NSString *gender;
	__unsafe_unretained NSString *lastLocation;
	__unsafe_unretained NSString *lastSeenDate;
	__unsafe_unretained NSString *lastmoddate;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *preferenceString;
	__unsafe_unretained NSString *profilePicKey;
	__unsafe_unretained NSString *region;
	__unsafe_unretained NSString *statement;
	__unsafe_unretained NSString *username;
	__unsafe_unretained NSString *weibo;
} EWPersonAttributes;

extern const struct EWPersonRelationships {
	__unsafe_unretained NSString *achievements;
	__unsafe_unretained NSString *alarms;
	__unsafe_unretained NSString *friended;
	__unsafe_unretained NSString *friends;
	__unsafe_unretained NSString *groupTasks;
	__unsafe_unretained NSString *groups;
	__unsafe_unretained NSString *groupsManaging;
	__unsafe_unretained NSString *medias;
	__unsafe_unretained NSString *pastTasks;
	__unsafe_unretained NSString *receivedMessages;
	__unsafe_unretained NSString *sentMessages;
	__unsafe_unretained NSString *tasks;
	__unsafe_unretained NSString *tasksHelped;
} EWPersonRelationships;

extern const struct EWPersonFetchedProperties {
} EWPersonFetchedProperties;

@class EWAchievement;
@class EWAlarmItem;
@class EWPerson;
@class EWPerson;
@class EWGroupTask;
@class EWGroup;
@class EWGroup;
@class EWMediaItem;
@class EWTaskItem;
@class EWMessage;
@class EWMessage;
@class EWTaskItem;
@class EWTaskItem;








@class NSObject;










@interface EWPersonID : NSManagedObjectID {}
@end

@interface _EWPerson : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWPersonID*)objectID;





@property (nonatomic, strong) NSString* bgImageKey;



//- (BOOL)validateBgImageKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* birthday;



//- (BOOL)validateBirthday:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* city;



//- (BOOL)validateCity:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* createddate;



//- (BOOL)validateCreateddate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* email;



//- (BOOL)validateEmail:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* facebook;



//- (BOOL)validateFacebook:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* gender;



//- (BOOL)validateGender:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id lastLocation;



//- (BOOL)validateLastLocation:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* lastSeenDate;



//- (BOOL)validateLastSeenDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* lastmoddate;



//- (BOOL)validateLastmoddate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* preferenceString;



//- (BOOL)validatePreferenceString:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* profilePicKey;



//- (BOOL)validateProfilePicKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* region;



//- (BOOL)validateRegion:(id*)value_ error:(NSError**)error_;





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




@property (nonatomic, strong) NSSet *friended;

- (NSMutableSet*)friendedSet;




@property (nonatomic, strong) NSSet *friends;

- (NSMutableSet*)friendsSet;




@property (nonatomic, strong) NSSet *groupTasks;

- (NSMutableSet*)groupTasksSet;




@property (nonatomic, strong) NSSet *groups;

- (NSMutableSet*)groupsSet;




@property (nonatomic, strong) NSSet *groupsManaging;

- (NSMutableSet*)groupsManagingSet;




@property (nonatomic, strong) NSSet *medias;

- (NSMutableSet*)mediasSet;




@property (nonatomic, strong) NSSet *pastTasks;

- (NSMutableSet*)pastTasksSet;




@property (nonatomic, strong) NSSet *receivedMessages;

- (NSMutableSet*)receivedMessagesSet;




@property (nonatomic, strong) NSSet *sentMessages;

- (NSMutableSet*)sentMessagesSet;




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

- (void)addFriended:(NSSet*)value_;
- (void)removeFriended:(NSSet*)value_;
- (void)addFriendedObject:(EWPerson*)value_;
- (void)removeFriendedObject:(EWPerson*)value_;

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

- (void)addMedias:(NSSet*)value_;
- (void)removeMedias:(NSSet*)value_;
- (void)addMediasObject:(EWMediaItem*)value_;
- (void)removeMediasObject:(EWMediaItem*)value_;

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


- (NSString*)primitiveBgImageKey;
- (void)setPrimitiveBgImageKey:(NSString*)value;




- (NSDate*)primitiveBirthday;
- (void)setPrimitiveBirthday:(NSDate*)value;




- (NSString*)primitiveCity;
- (void)setPrimitiveCity:(NSString*)value;




- (NSDate*)primitiveCreateddate;
- (void)setPrimitiveCreateddate:(NSDate*)value;




- (NSString*)primitiveEmail;
- (void)setPrimitiveEmail:(NSString*)value;




- (NSString*)primitiveFacebook;
- (void)setPrimitiveFacebook:(NSString*)value;




- (NSString*)primitiveGender;
- (void)setPrimitiveGender:(NSString*)value;




- (id)primitiveLastLocation;
- (void)setPrimitiveLastLocation:(id)value;




- (NSDate*)primitiveLastSeenDate;
- (void)setPrimitiveLastSeenDate:(NSDate*)value;




- (NSDate*)primitiveLastmoddate;
- (void)setPrimitiveLastmoddate:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitivePreferenceString;
- (void)setPrimitivePreferenceString:(NSString*)value;




- (NSString*)primitiveProfilePicKey;
- (void)setPrimitiveProfilePicKey:(NSString*)value;




- (NSString*)primitiveRegion;
- (void)setPrimitiveRegion:(NSString*)value;




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



- (NSMutableSet*)primitiveFriended;
- (void)setPrimitiveFriended:(NSMutableSet*)value;



- (NSMutableSet*)primitiveFriends;
- (void)setPrimitiveFriends:(NSMutableSet*)value;



- (NSMutableSet*)primitiveGroupTasks;
- (void)setPrimitiveGroupTasks:(NSMutableSet*)value;



- (NSMutableSet*)primitiveGroups;
- (void)setPrimitiveGroups:(NSMutableSet*)value;



- (NSMutableSet*)primitiveGroupsManaging;
- (void)setPrimitiveGroupsManaging:(NSMutableSet*)value;



- (NSMutableSet*)primitiveMedias;
- (void)setPrimitiveMedias:(NSMutableSet*)value;



- (NSMutableSet*)primitivePastTasks;
- (void)setPrimitivePastTasks:(NSMutableSet*)value;



- (NSMutableSet*)primitiveReceivedMessages;
- (void)setPrimitiveReceivedMessages:(NSMutableSet*)value;



- (NSMutableSet*)primitiveSentMessages;
- (void)setPrimitiveSentMessages:(NSMutableSet*)value;



- (NSMutableSet*)primitiveTasks;
- (void)setPrimitiveTasks:(NSMutableSet*)value;



- (NSMutableSet*)primitiveTasksHelped;
- (void)setPrimitiveTasksHelped:(NSMutableSet*)value;


@end
