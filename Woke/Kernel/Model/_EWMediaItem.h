// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMediaItem.h instead.

#import <CoreData/CoreData.h>
#import "EWServerObject.h"

extern const struct EWMediaItemAttributes {
	__unsafe_unretained NSString *liked;
	__unsafe_unretained NSString *message;
	__unsafe_unretained NSString *played;
	__unsafe_unretained NSString *priority;
	__unsafe_unretained NSString *response;
	__unsafe_unretained NSString *targetDate;
	__unsafe_unretained NSString *type;
} EWMediaItemAttributes;

extern const struct EWMediaItemRelationships {
	__unsafe_unretained NSString *activity;
	__unsafe_unretained NSString *author;
	__unsafe_unretained NSString *mediaFile;
	__unsafe_unretained NSString *messages;
	__unsafe_unretained NSString *receivers;
} EWMediaItemRelationships;

@class NSManagedObject;
@class EWPerson;
@class EWMeidaFile;
@class EWMessage;
@class EWPerson;

@interface EWMediaItemID : EWServerObjectID {}
@end

@interface _EWMediaItem : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWMediaItemID* objectID;

@property (nonatomic, strong) NSNumber* liked;

@property (atomic) BOOL likedValue;
- (BOOL)likedValue;
- (void)setLikedValue:(BOOL)value_;

//- (BOOL)validateLiked:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* message;

//- (BOOL)validateMessage:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* played;

//- (BOOL)validatePlayed:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* priority;

@property (atomic) int64_t priorityValue;
- (int64_t)priorityValue;
- (void)setPriorityValue:(int64_t)value_;

//- (BOOL)validatePriority:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* response;

//- (BOOL)validateResponse:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* targetDate;

//- (BOOL)validateTargetDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* type;

//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSManagedObject *activity;

//- (BOOL)validateActivity:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWPerson *author;

//- (BOOL)validateAuthor:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWMeidaFile *mediaFile;

//- (BOOL)validateMediaFile:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *messages;

- (NSMutableSet*)messagesSet;

@property (nonatomic, strong) NSSet *receivers;

- (NSMutableSet*)receiversSet;

@end

@interface _EWMediaItem (MessagesCoreDataGeneratedAccessors)
- (void)addMessages:(NSSet*)value_;
- (void)removeMessages:(NSSet*)value_;
- (void)addMessagesObject:(EWMessage*)value_;
- (void)removeMessagesObject:(EWMessage*)value_;

@end

@interface _EWMediaItem (ReceiversCoreDataGeneratedAccessors)
- (void)addReceivers:(NSSet*)value_;
- (void)removeReceivers:(NSSet*)value_;
- (void)addReceiversObject:(EWPerson*)value_;
- (void)removeReceiversObject:(EWPerson*)value_;

@end

@interface _EWMediaItem (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveLiked;
- (void)setPrimitiveLiked:(NSNumber*)value;

- (BOOL)primitiveLikedValue;
- (void)setPrimitiveLikedValue:(BOOL)value_;

- (NSString*)primitiveMessage;
- (void)setPrimitiveMessage:(NSString*)value;

- (NSDate*)primitivePlayed;
- (void)setPrimitivePlayed:(NSDate*)value;

- (NSNumber*)primitivePriority;
- (void)setPrimitivePriority:(NSNumber*)value;

- (int64_t)primitivePriorityValue;
- (void)setPrimitivePriorityValue:(int64_t)value_;

- (NSString*)primitiveResponse;
- (void)setPrimitiveResponse:(NSString*)value;

- (NSDate*)primitiveTargetDate;
- (void)setPrimitiveTargetDate:(NSDate*)value;

- (NSManagedObject*)primitiveActivity;
- (void)setPrimitiveActivity:(NSManagedObject*)value;

- (EWPerson*)primitiveAuthor;
- (void)setPrimitiveAuthor:(EWPerson*)value;

- (EWMeidaFile*)primitiveMediaFile;
- (void)setPrimitiveMediaFile:(EWMeidaFile*)value;

- (NSMutableSet*)primitiveMessages;
- (void)setPrimitiveMessages:(NSMutableSet*)value;

- (NSMutableSet*)primitiveReceivers;
- (void)setPrimitiveReceivers:(NSMutableSet*)value;

@end
