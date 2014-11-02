// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWTaskItem.h instead.

#import <CoreData/CoreData.h>
#import "EWServerObject.h"

extern const struct EWTaskItemAttributes {
	__unsafe_unretained NSString *completed;
	__unsafe_unretained NSString *log;
	__unsafe_unretained NSString *state;
	__unsafe_unretained NSString *statement;
	__unsafe_unretained NSString *time;
} EWTaskItemAttributes;

extern const struct EWTaskItemRelationships {
	__unsafe_unretained NSString *alarm;
	__unsafe_unretained NSString *medias;
	__unsafe_unretained NSString *messages;
	__unsafe_unretained NSString *owner;
	__unsafe_unretained NSString *pastOwner;
} EWTaskItemRelationships;

@class EWAlarm;
@class EWMedia;
@class EWMessage;
@class EWPerson;
@class EWPerson;

@class NSObject;

@interface EWTaskItemID : EWServerObjectID {}
@end

@interface _EWTaskItem : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWTaskItemID* objectID;

@property (nonatomic, strong) NSDate* completed;

//- (BOOL)validateCompleted:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id log;

//- (BOOL)validateLog:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* state;

@property (atomic) BOOL stateValue;
- (BOOL)stateValue;
- (void)setStateValue:(BOOL)value_;

//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* statement;

//- (BOOL)validateStatement:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* time;

//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWAlarm *alarm;

//- (BOOL)validateAlarm:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *medias;

- (NSMutableSet*)mediasSet;

@property (nonatomic, strong) NSSet *messages;

- (NSMutableSet*)messagesSet;

@property (nonatomic, strong) EWPerson *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWPerson *pastOwner;

//- (BOOL)validatePastOwner:(id*)value_ error:(NSError**)error_;

@end

@interface _EWTaskItem (MediasCoreDataGeneratedAccessors)
- (void)addMedias:(NSSet*)value_;
- (void)removeMedias:(NSSet*)value_;
- (void)addMediasObject:(EWMedia*)value_;
- (void)removeMediasObject:(EWMedia*)value_;

@end

@interface _EWTaskItem (MessagesCoreDataGeneratedAccessors)
- (void)addMessages:(NSSet*)value_;
- (void)removeMessages:(NSSet*)value_;
- (void)addMessagesObject:(EWMessage*)value_;
- (void)removeMessagesObject:(EWMessage*)value_;

@end

@interface _EWTaskItem (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveCompleted;
- (void)setPrimitiveCompleted:(NSDate*)value;

- (id)primitiveLog;
- (void)setPrimitiveLog:(id)value;

- (NSNumber*)primitiveState;
- (void)setPrimitiveState:(NSNumber*)value;

- (BOOL)primitiveStateValue;
- (void)setPrimitiveStateValue:(BOOL)value_;

- (NSString*)primitiveStatement;
- (void)setPrimitiveStatement:(NSString*)value;

- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;

- (EWAlarm*)primitiveAlarm;
- (void)setPrimitiveAlarm:(EWAlarm*)value;

- (NSMutableSet*)primitiveMedias;
- (void)setPrimitiveMedias:(NSMutableSet*)value;

- (NSMutableSet*)primitiveMessages;
- (void)setPrimitiveMessages:(NSMutableSet*)value;

- (EWPerson*)primitiveOwner;
- (void)setPrimitiveOwner:(EWPerson*)value;

- (EWPerson*)primitivePastOwner;
- (void)setPrimitivePastOwner:(EWPerson*)value;

@end
