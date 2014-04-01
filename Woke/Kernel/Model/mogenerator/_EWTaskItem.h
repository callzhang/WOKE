// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWTaskItem.h instead.

#import <CoreData/CoreData.h>


extern const struct EWTaskItemAttributes {
	__unsafe_unretained NSString *added;
	__unsafe_unretained NSString *buzzers_string;
	__unsafe_unretained NSString *completed;
	__unsafe_unretained NSString *createddate;
	__unsafe_unretained NSString *ewtaskitem_id;
	__unsafe_unretained NSString *lastmoddate;
	__unsafe_unretained NSString *state;
	__unsafe_unretained NSString *statement;
	__unsafe_unretained NSString *success;
	__unsafe_unretained NSString *time;
} EWTaskItemAttributes;

extern const struct EWTaskItemRelationships {
	__unsafe_unretained NSString *alarm;
	__unsafe_unretained NSString *medias;
	__unsafe_unretained NSString *messages;
	__unsafe_unretained NSString *owner;
	__unsafe_unretained NSString *pastOwner;
	__unsafe_unretained NSString *waker;
} EWTaskItemRelationships;

extern const struct EWTaskItemFetchedProperties {
} EWTaskItemFetchedProperties;

@class EWAlarmItem;
@class EWMediaItem;
@class EWMessage;
@class EWPerson;












@interface EWTaskItemID : NSManagedObjectID {}
@end

@interface _EWTaskItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWTaskItemID*)objectID;





@property (nonatomic, strong) NSDate* added;



//- (BOOL)validateAdded:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* buzzers_string;



//- (BOOL)validateBuzzers_string:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* completed;



//- (BOOL)validateCompleted:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* createddate;



//- (BOOL)validateCreateddate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* ewtaskitem_id;



//- (BOOL)validateEwtaskitem_id:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* lastmoddate;



//- (BOOL)validateLastmoddate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* state;



@property BOOL stateValue;
- (BOOL)stateValue;
- (void)setStateValue:(BOOL)value_;

//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* statement;



//- (BOOL)validateStatement:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* success;



@property BOOL successValue;
- (BOOL)successValue;
- (void)setSuccessValue:(BOOL)value_;

//- (BOOL)validateSuccess:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* time;



//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) EWAlarmItem *alarm;

//- (BOOL)validateAlarm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet *medias;

- (NSMutableSet*)mediasSet;




@property (nonatomic, strong) EWMessage *messages;

//- (BOOL)validateMessages:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) EWPerson *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) EWPerson *pastOwner;

//- (BOOL)validatePastOwner:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet *waker;

- (NSMutableSet*)wakerSet;





@end

@interface _EWTaskItem (CoreDataGeneratedAccessors)

- (void)addMedias:(NSSet*)value_;
- (void)removeMedias:(NSSet*)value_;
- (void)addMediasObject:(EWMediaItem*)value_;
- (void)removeMediasObject:(EWMediaItem*)value_;

- (void)addWaker:(NSSet*)value_;
- (void)removeWaker:(NSSet*)value_;
- (void)addWakerObject:(EWPerson*)value_;
- (void)removeWakerObject:(EWPerson*)value_;

@end

@interface _EWTaskItem (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveAdded;
- (void)setPrimitiveAdded:(NSDate*)value;




- (NSString*)primitiveBuzzers_string;
- (void)setPrimitiveBuzzers_string:(NSString*)value;




- (NSDate*)primitiveCompleted;
- (void)setPrimitiveCompleted:(NSDate*)value;




- (NSDate*)primitiveCreateddate;
- (void)setPrimitiveCreateddate:(NSDate*)value;




- (NSString*)primitiveEwtaskitem_id;
- (void)setPrimitiveEwtaskitem_id:(NSString*)value;




- (NSDate*)primitiveLastmoddate;
- (void)setPrimitiveLastmoddate:(NSDate*)value;




- (NSNumber*)primitiveState;
- (void)setPrimitiveState:(NSNumber*)value;

- (BOOL)primitiveStateValue;
- (void)setPrimitiveStateValue:(BOOL)value_;




- (NSString*)primitiveStatement;
- (void)setPrimitiveStatement:(NSString*)value;




- (NSNumber*)primitiveSuccess;
- (void)setPrimitiveSuccess:(NSNumber*)value;

- (BOOL)primitiveSuccessValue;
- (void)setPrimitiveSuccessValue:(BOOL)value_;




- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;





- (EWAlarmItem*)primitiveAlarm;
- (void)setPrimitiveAlarm:(EWAlarmItem*)value;



- (NSMutableSet*)primitiveMedias;
- (void)setPrimitiveMedias:(NSMutableSet*)value;



- (EWMessage*)primitiveMessages;
- (void)setPrimitiveMessages:(EWMessage*)value;



- (EWPerson*)primitiveOwner;
- (void)setPrimitiveOwner:(EWPerson*)value;



- (EWPerson*)primitivePastOwner;
- (void)setPrimitivePastOwner:(EWPerson*)value;



- (NSMutableSet*)primitiveWaker;
- (void)setPrimitiveWaker:(NSMutableSet*)value;


@end
