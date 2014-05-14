// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMessage.h instead.

#import <CoreData/CoreData.h>


extern const struct EWMessageAttributes {
	__unsafe_unretained NSString *createdAt;
	__unsafe_unretained NSString *media;
	__unsafe_unretained NSString *objectId;
	__unsafe_unretained NSString *text;
	__unsafe_unretained NSString *time;
	__unsafe_unretained NSString *updatedAt;
} EWMessageAttributes;

extern const struct EWMessageRelationships {
	__unsafe_unretained NSString *groupTask;
	__unsafe_unretained NSString *recipient;
	__unsafe_unretained NSString *sender;
	__unsafe_unretained NSString *task;
} EWMessageRelationships;

extern const struct EWMessageFetchedProperties {
} EWMessageFetchedProperties;

@class EWGroupTask;
@class EWPerson;
@class EWPerson;
@class EWTaskItem;








@interface EWMessageID : NSManagedObjectID {}
@end

@interface _EWMessage : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWMessageID*)objectID;





@property (nonatomic, strong) NSDate* createdAt;



//- (BOOL)validateCreatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* media;



//- (BOOL)validateMedia:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* objectId;



//- (BOOL)validateObjectId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* text;



//- (BOOL)validateText:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* time;



//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* updatedAt;



//- (BOOL)validateUpdatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) EWGroupTask *groupTask;

//- (BOOL)validateGroupTask:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) EWPerson *recipient;

//- (BOOL)validateRecipient:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) EWPerson *sender;

//- (BOOL)validateSender:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) EWTaskItem *task;

//- (BOOL)validateTask:(id*)value_ error:(NSError**)error_;





@end

@interface _EWMessage (CoreDataGeneratedAccessors)

@end

@interface _EWMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveCreatedAt;
- (void)setPrimitiveCreatedAt:(NSDate*)value;




- (NSString*)primitiveMedia;
- (void)setPrimitiveMedia:(NSString*)value;




- (NSString*)primitiveObjectId;
- (void)setPrimitiveObjectId:(NSString*)value;




- (NSString*)primitiveText;
- (void)setPrimitiveText:(NSString*)value;




- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;




- (NSDate*)primitiveUpdatedAt;
- (void)setPrimitiveUpdatedAt:(NSDate*)value;





- (EWGroupTask*)primitiveGroupTask;
- (void)setPrimitiveGroupTask:(EWGroupTask*)value;



- (EWPerson*)primitiveRecipient;
- (void)setPrimitiveRecipient:(EWPerson*)value;



- (EWPerson*)primitiveSender;
- (void)setPrimitiveSender:(EWPerson*)value;



- (EWTaskItem*)primitiveTask;
- (void)setPrimitiveTask:(EWTaskItem*)value;


@end
