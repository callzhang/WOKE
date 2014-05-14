// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMediaItem.h instead.

#import <CoreData/CoreData.h>


extern const struct EWMediaItemAttributes {
	__unsafe_unretained NSString *audioKey;
	__unsafe_unretained NSString *buzzKey;
	__unsafe_unretained NSString *createdAt;
	__unsafe_unretained NSString *fixedDate;
	__unsafe_unretained NSString *imageKey;
	__unsafe_unretained NSString *message;
	__unsafe_unretained NSString *objectId;
	__unsafe_unretained NSString *played;
	__unsafe_unretained NSString *priority;
	__unsafe_unretained NSString *readTime;
	__unsafe_unretained NSString *type;
	__unsafe_unretained NSString *updatedAt;
	__unsafe_unretained NSString *videoKey;
} EWMediaItemAttributes;

extern const struct EWMediaItemRelationships {
	__unsafe_unretained NSString *author;
	__unsafe_unretained NSString *groupTask;
	__unsafe_unretained NSString *receiver;
	__unsafe_unretained NSString *task;
} EWMediaItemRelationships;

extern const struct EWMediaItemFetchedProperties {
} EWMediaItemFetchedProperties;

@class EWPerson;
@class EWGroupTask;
@class EWPerson;
@class EWTaskItem;















@interface EWMediaItemID : NSManagedObjectID {}
@end

@interface _EWMediaItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWMediaItemID*)objectID;





@property (nonatomic, strong) NSString* audioKey;



//- (BOOL)validateAudioKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* buzzKey;



//- (BOOL)validateBuzzKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* createdAt;



//- (BOOL)validateCreatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* fixedDate;



//- (BOOL)validateFixedDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* imageKey;



//- (BOOL)validateImageKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* message;



//- (BOOL)validateMessage:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* objectId;



//- (BOOL)validateObjectId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* played;



@property BOOL playedValue;
- (BOOL)playedValue;
- (void)setPlayedValue:(BOOL)value_;

//- (BOOL)validatePlayed:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* priority;



@property int64_t priorityValue;
- (int64_t)priorityValue;
- (void)setPriorityValue:(int64_t)value_;

//- (BOOL)validatePriority:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* readTime;



//- (BOOL)validateReadTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* type;



//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* updatedAt;



//- (BOOL)validateUpdatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* videoKey;



//- (BOOL)validateVideoKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) EWPerson *author;

//- (BOOL)validateAuthor:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) EWGroupTask *groupTask;

//- (BOOL)validateGroupTask:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) EWPerson *receiver;

//- (BOOL)validateReceiver:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) EWTaskItem *task;

//- (BOOL)validateTask:(id*)value_ error:(NSError**)error_;





@end

@interface _EWMediaItem (CoreDataGeneratedAccessors)

@end

@interface _EWMediaItem (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveAudioKey;
- (void)setPrimitiveAudioKey:(NSString*)value;




- (NSString*)primitiveBuzzKey;
- (void)setPrimitiveBuzzKey:(NSString*)value;




- (NSDate*)primitiveCreatedAt;
- (void)setPrimitiveCreatedAt:(NSDate*)value;




- (NSDate*)primitiveFixedDate;
- (void)setPrimitiveFixedDate:(NSDate*)value;




- (NSString*)primitiveImageKey;
- (void)setPrimitiveImageKey:(NSString*)value;




- (NSString*)primitiveMessage;
- (void)setPrimitiveMessage:(NSString*)value;




- (NSString*)primitiveObjectId;
- (void)setPrimitiveObjectId:(NSString*)value;




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




- (NSString*)primitiveType;
- (void)setPrimitiveType:(NSString*)value;




- (NSDate*)primitiveUpdatedAt;
- (void)setPrimitiveUpdatedAt:(NSDate*)value;




- (NSString*)primitiveVideoKey;
- (void)setPrimitiveVideoKey:(NSString*)value;





- (EWPerson*)primitiveAuthor;
- (void)setPrimitiveAuthor:(EWPerson*)value;



- (EWGroupTask*)primitiveGroupTask;
- (void)setPrimitiveGroupTask:(EWGroupTask*)value;



- (EWPerson*)primitiveReceiver;
- (void)setPrimitiveReceiver:(EWPerson*)value;



- (EWTaskItem*)primitiveTask;
- (void)setPrimitiveTask:(EWTaskItem*)value;


@end
