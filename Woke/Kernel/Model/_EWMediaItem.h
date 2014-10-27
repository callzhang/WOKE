// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMediaItem.h instead.

#import <CoreData/CoreData.h>
#import "EWServerObject.h"

extern const struct EWMediaItemAttributes {
	__unsafe_unretained NSString *audio;
	__unsafe_unretained NSString *buzzKey;
	__unsafe_unretained NSString *image;
	__unsafe_unretained NSString *message;
	__unsafe_unretained NSString *played;
	__unsafe_unretained NSString *priority;
	__unsafe_unretained NSString *readTime;
	__unsafe_unretained NSString *targetDate;
	__unsafe_unretained NSString *thumbnail;
	__unsafe_unretained NSString *type;
	__unsafe_unretained NSString *video;
} EWMediaItemAttributes;

extern const struct EWMediaItemRelationships {
	__unsafe_unretained NSString *author;
	__unsafe_unretained NSString *groupTask;
	__unsafe_unretained NSString *receivers;
	__unsafe_unretained NSString *tasks;
} EWMediaItemRelationships;

@class EWPerson;
@class EWGroupTask;
@class EWPerson;
@class EWTaskItem;

@class NSObject;

@class NSObject;

@interface EWMediaItemID : EWServerObjectID {}
@end

@interface _EWMediaItem : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWMediaItemID* objectID;

@property (nonatomic, strong) NSData* audio;

//- (BOOL)validateAudio:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* buzzKey;

//- (BOOL)validateBuzzKey:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id image;

//- (BOOL)validateImage:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* message;

//- (BOOL)validateMessage:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* played;

@property (atomic) BOOL playedValue;
- (BOOL)playedValue;
- (void)setPlayedValue:(BOOL)value_;

//- (BOOL)validatePlayed:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* priority;

@property (atomic) int64_t priorityValue;
- (int64_t)priorityValue;
- (void)setPriorityValue:(int64_t)value_;

//- (BOOL)validatePriority:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* readTime;

//- (BOOL)validateReadTime:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* targetDate;

//- (BOOL)validateTargetDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id thumbnail;

//- (BOOL)validateThumbnail:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* type;

//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSData* video;

//- (BOOL)validateVideo:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWPerson *author;

//- (BOOL)validateAuthor:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWGroupTask *groupTask;

//- (BOOL)validateGroupTask:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *receivers;

- (NSMutableSet*)receiversSet;

@property (nonatomic, strong) NSSet *tasks;

- (NSMutableSet*)tasksSet;

@end

@interface _EWMediaItem (ReceiversCoreDataGeneratedAccessors)
- (void)addReceivers:(NSSet*)value_;
- (void)removeReceivers:(NSSet*)value_;
- (void)addReceiversObject:(EWPerson*)value_;
- (void)removeReceiversObject:(EWPerson*)value_;

@end

@interface _EWMediaItem (TasksCoreDataGeneratedAccessors)
- (void)addTasks:(NSSet*)value_;
- (void)removeTasks:(NSSet*)value_;
- (void)addTasksObject:(EWTaskItem*)value_;
- (void)removeTasksObject:(EWTaskItem*)value_;

@end

@interface _EWMediaItem (CoreDataGeneratedPrimitiveAccessors)

- (NSData*)primitiveAudio;
- (void)setPrimitiveAudio:(NSData*)value;

- (NSString*)primitiveBuzzKey;
- (void)setPrimitiveBuzzKey:(NSString*)value;

- (id)primitiveImage;
- (void)setPrimitiveImage:(id)value;

- (NSString*)primitiveMessage;
- (void)setPrimitiveMessage:(NSString*)value;

- (NSNumber*)primitivePlayed;
- (void)setPrimitivePlayed:(NSNumber*)value;

- (BOOL)primitivePlayedValue;
- (void)setPrimitivePlayedValue:(BOOL)value_;

- (NSNumber*)primitivePriority;
- (void)setPrimitivePriority:(NSNumber*)value;

- (int64_t)primitivePriorityValue;
- (void)setPrimitivePriorityValue:(int64_t)value_;

- (NSDate*)primitiveReadTime;
- (void)setPrimitiveReadTime:(NSDate*)value;

- (NSDate*)primitiveTargetDate;
- (void)setPrimitiveTargetDate:(NSDate*)value;

- (id)primitiveThumbnail;
- (void)setPrimitiveThumbnail:(id)value;

- (NSData*)primitiveVideo;
- (void)setPrimitiveVideo:(NSData*)value;

- (EWPerson*)primitiveAuthor;
- (void)setPrimitiveAuthor:(EWPerson*)value;

- (EWGroupTask*)primitiveGroupTask;
- (void)setPrimitiveGroupTask:(EWGroupTask*)value;

- (NSMutableSet*)primitiveReceivers;
- (void)setPrimitiveReceivers:(NSMutableSet*)value;

- (NSMutableSet*)primitiveTasks;
- (void)setPrimitiveTasks:(NSMutableSet*)value;

@end
