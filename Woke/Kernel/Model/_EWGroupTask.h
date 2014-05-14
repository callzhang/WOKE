// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWGroupTask.h instead.

#import <CoreData/CoreData.h>


extern const struct EWGroupTaskAttributes {
	__unsafe_unretained NSString *added;
	__unsafe_unretained NSString *city;
	__unsafe_unretained NSString *createdAt;
	__unsafe_unretained NSString *objectId;
	__unsafe_unretained NSString *region;
	__unsafe_unretained NSString *time;
	__unsafe_unretained NSString *updatedId;
} EWGroupTaskAttributes;

extern const struct EWGroupTaskRelationships {
	__unsafe_unretained NSString *medias;
	__unsafe_unretained NSString *messages;
	__unsafe_unretained NSString *participents;
} EWGroupTaskRelationships;

extern const struct EWGroupTaskFetchedProperties {
} EWGroupTaskFetchedProperties;

@class EWMediaItem;
@class EWMessage;
@class EWPerson;









@interface EWGroupTaskID : NSManagedObjectID {}
@end

@interface _EWGroupTask : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWGroupTaskID*)objectID;





@property (nonatomic, strong) NSDate* added;



//- (BOOL)validateAdded:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* city;



//- (BOOL)validateCity:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* createdAt;



//- (BOOL)validateCreatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* objectId;



//- (BOOL)validateObjectId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* region;



//- (BOOL)validateRegion:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* time;



//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* updatedId;



//- (BOOL)validateUpdatedId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *medias;

- (NSMutableSet*)mediasSet;




@property (nonatomic, strong) EWMessage *messages;

//- (BOOL)validateMessages:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet *participents;

- (NSMutableSet*)participentsSet;





@end

@interface _EWGroupTask (CoreDataGeneratedAccessors)

- (void)addMedias:(NSSet*)value_;
- (void)removeMedias:(NSSet*)value_;
- (void)addMediasObject:(EWMediaItem*)value_;
- (void)removeMediasObject:(EWMediaItem*)value_;

- (void)addParticipents:(NSSet*)value_;
- (void)removeParticipents:(NSSet*)value_;
- (void)addParticipentsObject:(EWPerson*)value_;
- (void)removeParticipentsObject:(EWPerson*)value_;

@end

@interface _EWGroupTask (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveAdded;
- (void)setPrimitiveAdded:(NSDate*)value;




- (NSString*)primitiveCity;
- (void)setPrimitiveCity:(NSString*)value;




- (NSDate*)primitiveCreatedAt;
- (void)setPrimitiveCreatedAt:(NSDate*)value;




- (NSString*)primitiveObjectId;
- (void)setPrimitiveObjectId:(NSString*)value;




- (NSString*)primitiveRegion;
- (void)setPrimitiveRegion:(NSString*)value;




- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;




- (NSDate*)primitiveUpdatedId;
- (void)setPrimitiveUpdatedId:(NSDate*)value;





- (NSMutableSet*)primitiveMedias;
- (void)setPrimitiveMedias:(NSMutableSet*)value;



- (EWMessage*)primitiveMessages;
- (void)setPrimitiveMessages:(EWMessage*)value;



- (NSMutableSet*)primitiveParticipents;
- (void)setPrimitiveParticipents:(NSMutableSet*)value;


@end
