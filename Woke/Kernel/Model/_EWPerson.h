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
	__unsafe_unretained NSString *images;
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
	__unsafe_unretained NSString *activities;
	__unsafe_unretained NSString *alarms;
	__unsafe_unretained NSString *friends;
	__unsafe_unretained NSString *medias;
	__unsafe_unretained NSString *notifications;
	__unsafe_unretained NSString *socialGraph;
	__unsafe_unretained NSString *unreadMedias;
} EWPersonRelationships;

@class EWAchievement;
@class EWActivity;
@class EWAlarm;
@class EWPerson;
@class EWMedia;
@class EWNotification;
@class EWSocialGraph;
@class EWMedia;

@class NSObject;

@class NSObject;

@class NSObject;

@class NSObject;

@class NSObject;

@class NSObject;

@class NSObject;

@interface EWPersonID : EWServerObjectID {}
@end

@interface _EWPerson : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWPersonID* objectID;

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

@property (nonatomic, strong) id images;

//- (BOOL)validateImages:(id*)value_ error:(NSError**)error_;

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

@property (atomic) float scoreValue;
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

@property (nonatomic, strong) NSSet *activities;

- (NSMutableSet*)activitiesSet;

@property (nonatomic, strong) NSSet *alarms;

- (NSMutableSet*)alarmsSet;

@property (nonatomic, strong) NSSet *friends;

- (NSMutableSet*)friendsSet;

@property (nonatomic, strong) NSSet *medias;

- (NSMutableSet*)mediasSet;

@property (nonatomic, strong) NSSet *notifications;

- (NSMutableSet*)notificationsSet;

@property (nonatomic, strong) EWSocialGraph *socialGraph;

//- (BOOL)validateSocialGraph:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *unreadMedias;

- (NSMutableSet*)unreadMediasSet;

@end

@interface _EWPerson (AchievementsCoreDataGeneratedAccessors)
- (void)addAchievements:(NSSet*)value_;
- (void)removeAchievements:(NSSet*)value_;
- (void)addAchievementsObject:(EWAchievement*)value_;
- (void)removeAchievementsObject:(EWAchievement*)value_;

@end

@interface _EWPerson (ActivitiesCoreDataGeneratedAccessors)
- (void)addActivities:(NSSet*)value_;
- (void)removeActivities:(NSSet*)value_;
- (void)addActivitiesObject:(EWActivity*)value_;
- (void)removeActivitiesObject:(EWActivity*)value_;

@end

@interface _EWPerson (AlarmsCoreDataGeneratedAccessors)
- (void)addAlarms:(NSSet*)value_;
- (void)removeAlarms:(NSSet*)value_;
- (void)addAlarmsObject:(EWAlarm*)value_;
- (void)removeAlarmsObject:(EWAlarm*)value_;

@end

@interface _EWPerson (FriendsCoreDataGeneratedAccessors)
- (void)addFriends:(NSSet*)value_;
- (void)removeFriends:(NSSet*)value_;
- (void)addFriendsObject:(EWPerson*)value_;
- (void)removeFriendsObject:(EWPerson*)value_;

@end

@interface _EWPerson (MediasCoreDataGeneratedAccessors)
- (void)addMedias:(NSSet*)value_;
- (void)removeMedias:(NSSet*)value_;
- (void)addMediasObject:(EWMedia*)value_;
- (void)removeMediasObject:(EWMedia*)value_;

@end

@interface _EWPerson (NotificationsCoreDataGeneratedAccessors)
- (void)addNotifications:(NSSet*)value_;
- (void)removeNotifications:(NSSet*)value_;
- (void)addNotificationsObject:(EWNotification*)value_;
- (void)removeNotificationsObject:(EWNotification*)value_;

@end

@interface _EWPerson (UnreadMediasCoreDataGeneratedAccessors)
- (void)addUnreadMedias:(NSSet*)value_;
- (void)removeUnreadMedias:(NSSet*)value_;
- (void)addUnreadMediasObject:(EWMedia*)value_;
- (void)removeUnreadMediasObject:(EWMedia*)value_;

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

- (id)primitiveImages;
- (void)setPrimitiveImages:(id)value;

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

- (NSMutableSet*)primitiveActivities;
- (void)setPrimitiveActivities:(NSMutableSet*)value;

- (NSMutableSet*)primitiveAlarms;
- (void)setPrimitiveAlarms:(NSMutableSet*)value;

- (NSMutableSet*)primitiveFriends;
- (void)setPrimitiveFriends:(NSMutableSet*)value;

- (NSMutableSet*)primitiveMedias;
- (void)setPrimitiveMedias:(NSMutableSet*)value;

- (NSMutableSet*)primitiveNotifications;
- (void)setPrimitiveNotifications:(NSMutableSet*)value;

- (EWSocialGraph*)primitiveSocialGraph;
- (void)setPrimitiveSocialGraph:(EWSocialGraph*)value;

- (NSMutableSet*)primitiveUnreadMedias;
- (void)setPrimitiveUnreadMedias:(NSMutableSet*)value;

@end
