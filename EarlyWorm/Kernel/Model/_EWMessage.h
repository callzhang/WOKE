// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMessage.h instead.

#import <CoreData/CoreData.h>


extern const struct EWMessageAttributes {
	__unsafe_unretained NSString *createddate;
	__unsafe_unretained NSString *ewmessage_id;
	__unsafe_unretained NSString *lastmoddate;
	__unsafe_unretained NSString *media;
	__unsafe_unretained NSString *text;
	__unsafe_unretained NSString *time;
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





@property (nonatomic, strong) NSDate* createddate;



//- (BOOL)validateCreateddate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* ewmessage_id;



//- (BOOL)validateEwmessage_id:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* lastmoddate;



//- (BOOL)validateLastmoddate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* media;



//- (BOOL)validateMedia:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* text;



//- (BOOL)validateText:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* time;



//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;





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


- (NSDate*)primitiveCreateddate;
- (void)setPrimitiveCreateddate:(NSDate*)value;




- (NSString*)primitiveEwmessage_id;
- (void)setPrimitiveEwmessage_id:(NSString*)value;




- (NSDate*)primitiveLastmoddate;
- (void)setPrimitiveLastmoddate:(NSDate*)value;




- (NSString*)primitiveMedia;
- (void)setPrimitiveMedia:(NSString*)value;




- (NSString*)primitiveText;
- (void)setPrimitiveText:(NSString*)value;




- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;





- (EWGroupTask*)primitiveGroupTask;
- (void)setPrimitiveGroupTask:(EWGroupTask*)value;



- (EWPerson*)primitiveRecipient;
- (void)setPrimitiveRecipient:(EWPerson*)value;



- (EWPerson*)primitiveSender;
- (void)setPrimitiveSender:(EWPerson*)value;



- (EWTaskItem*)primitiveTask;
- (void)setPrimitiveTask:(EWTaskItem*)value;


@end
