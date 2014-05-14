// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWAlarmItem.h instead.

#import <CoreData/CoreData.h>


extern const struct EWAlarmItemAttributes {
	__unsafe_unretained NSString *alarmDescription;
	__unsafe_unretained NSString *createdAt;
	__unsafe_unretained NSString *important;
	__unsafe_unretained NSString *objectId;
	__unsafe_unretained NSString *state;
	__unsafe_unretained NSString *time;
	__unsafe_unretained NSString *todo;
	__unsafe_unretained NSString *tone;
	__unsafe_unretained NSString *updatedAt;
} EWAlarmItemAttributes;

extern const struct EWAlarmItemRelationships {
	__unsafe_unretained NSString *owner;
	__unsafe_unretained NSString *tasks;
} EWAlarmItemRelationships;

extern const struct EWAlarmItemFetchedProperties {
} EWAlarmItemFetchedProperties;

@class EWPerson;
@class EWTaskItem;











@interface EWAlarmItemID : NSManagedObjectID {}
@end

@interface _EWAlarmItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWAlarmItemID*)objectID;





@property (nonatomic, strong) NSString* alarmDescription;



//- (BOOL)validateAlarmDescription:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* createdAt;



//- (BOOL)validateCreatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* important;



@property BOOL importantValue;
- (BOOL)importantValue;
- (void)setImportantValue:(BOOL)value_;

//- (BOOL)validateImportant:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* objectId;



//- (BOOL)validateObjectId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* state;



@property BOOL stateValue;
- (BOOL)stateValue;
- (void)setStateValue:(BOOL)value_;

//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* time;



//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* todo;



//- (BOOL)validateTodo:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* tone;



//- (BOOL)validateTone:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* updatedAt;



//- (BOOL)validateUpdatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) EWPerson *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet *tasks;

- (NSMutableSet*)tasksSet;





@end

@interface _EWAlarmItem (CoreDataGeneratedAccessors)

- (void)addTasks:(NSSet*)value_;
- (void)removeTasks:(NSSet*)value_;
- (void)addTasksObject:(EWTaskItem*)value_;
- (void)removeTasksObject:(EWTaskItem*)value_;

@end

@interface _EWAlarmItem (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveAlarmDescription;
- (void)setPrimitiveAlarmDescription:(NSString*)value;




- (NSDate*)primitiveCreatedAt;
- (void)setPrimitiveCreatedAt:(NSDate*)value;




- (NSNumber*)primitiveImportant;
- (void)setPrimitiveImportant:(NSNumber*)value;

- (BOOL)primitiveImportantValue;
- (void)setPrimitiveImportantValue:(BOOL)value_;




- (NSString*)primitiveObjectId;
- (void)setPrimitiveObjectId:(NSString*)value;




- (NSNumber*)primitiveState;
- (void)setPrimitiveState:(NSNumber*)value;

- (BOOL)primitiveStateValue;
- (void)setPrimitiveStateValue:(BOOL)value_;




- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;




- (NSString*)primitiveTodo;
- (void)setPrimitiveTodo:(NSString*)value;




- (NSString*)primitiveTone;
- (void)setPrimitiveTone:(NSString*)value;




- (NSDate*)primitiveUpdatedAt;
- (void)setPrimitiveUpdatedAt:(NSDate*)value;





- (EWPerson*)primitiveOwner;
- (void)setPrimitiveOwner:(EWPerson*)value;



- (NSMutableSet*)primitiveTasks;
- (void)setPrimitiveTasks:(NSMutableSet*)value;


@end
