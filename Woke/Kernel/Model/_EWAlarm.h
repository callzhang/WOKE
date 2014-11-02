// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWAlarm.h instead.

#import <CoreData/CoreData.h>
#import "EWServerObject.h"

extern const struct EWAlarmAttributes {
	__unsafe_unretained NSString *important;
	__unsafe_unretained NSString *state;
	__unsafe_unretained NSString *statement;
	__unsafe_unretained NSString *time;
	__unsafe_unretained NSString *todo;
	__unsafe_unretained NSString *tone;
} EWAlarmAttributes;

extern const struct EWAlarmRelationships {
	__unsafe_unretained NSString *owner;
} EWAlarmRelationships;

@class EWPerson;

@interface EWAlarmID : EWServerObjectID {}
@end

@interface _EWAlarm : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWAlarmID* objectID;

@property (nonatomic, strong) NSNumber* important;

@property (atomic) BOOL importantValue;
- (BOOL)importantValue;
- (void)setImportantValue:(BOOL)value_;

//- (BOOL)validateImportant:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* state;

@property (atomic) BOOL stateValue;
- (BOOL)stateValue;
- (void)setStateValue:(BOOL)value_;

//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* statement;

//- (BOOL)validateStatement:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* time;

//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* todo;

//- (BOOL)validateTodo:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* tone;

//- (BOOL)validateTone:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWPerson *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;

@end

@interface _EWAlarm (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveImportant;
- (void)setPrimitiveImportant:(NSNumber*)value;

- (BOOL)primitiveImportantValue;
- (void)setPrimitiveImportantValue:(BOOL)value_;

- (NSNumber*)primitiveState;
- (void)setPrimitiveState:(NSNumber*)value;

- (BOOL)primitiveStateValue;
- (void)setPrimitiveStateValue:(BOOL)value_;

- (NSString*)primitiveStatement;
- (void)setPrimitiveStatement:(NSString*)value;

- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;

- (NSString*)primitiveTodo;
- (void)setPrimitiveTodo:(NSString*)value;

- (NSString*)primitiveTone;
- (void)setPrimitiveTone:(NSString*)value;

- (EWPerson*)primitiveOwner;
- (void)setPrimitiveOwner:(EWPerson*)value;

@end
