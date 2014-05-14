// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWNotification.h instead.

#import <CoreData/CoreData.h>


extern const struct EWNotificationAttributes {
	__unsafe_unretained NSString *completed;
	__unsafe_unretained NSString *createdAt;
	__unsafe_unretained NSString *importance;
	__unsafe_unretained NSString *objectId;
	__unsafe_unretained NSString *sender;
	__unsafe_unretained NSString *type;
	__unsafe_unretained NSString *updatedAt;
	__unsafe_unretained NSString *userInfoString;
} EWNotificationAttributes;

extern const struct EWNotificationRelationships {
	__unsafe_unretained NSString *owner;
} EWNotificationRelationships;

extern const struct EWNotificationFetchedProperties {
} EWNotificationFetchedProperties;

@class EWPerson;










@interface EWNotificationID : NSManagedObjectID {}
@end

@interface _EWNotification : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWNotificationID*)objectID;





@property (nonatomic, strong) NSDate* completed;



//- (BOOL)validateCompleted:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* createdAt;



//- (BOOL)validateCreatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* importance;



@property int64_t importanceValue;
- (int64_t)importanceValue;
- (void)setImportanceValue:(int64_t)value_;

//- (BOOL)validateImportance:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* objectId;



//- (BOOL)validateObjectId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* sender;



//- (BOOL)validateSender:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* type;



//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* updatedAt;



//- (BOOL)validateUpdatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* userInfoString;



//- (BOOL)validateUserInfoString:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) EWPerson *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;





@end

@interface _EWNotification (CoreDataGeneratedAccessors)

@end

@interface _EWNotification (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveCompleted;
- (void)setPrimitiveCompleted:(NSDate*)value;




- (NSDate*)primitiveCreatedAt;
- (void)setPrimitiveCreatedAt:(NSDate*)value;




- (NSNumber*)primitiveImportance;
- (void)setPrimitiveImportance:(NSNumber*)value;

- (int64_t)primitiveImportanceValue;
- (void)setPrimitiveImportanceValue:(int64_t)value_;




- (NSString*)primitiveObjectId;
- (void)setPrimitiveObjectId:(NSString*)value;




- (NSString*)primitiveSender;
- (void)setPrimitiveSender:(NSString*)value;




- (NSString*)primitiveType;
- (void)setPrimitiveType:(NSString*)value;




- (NSDate*)primitiveUpdatedAt;
- (void)setPrimitiveUpdatedAt:(NSDate*)value;




- (NSString*)primitiveUserInfoString;
- (void)setPrimitiveUserInfoString:(NSString*)value;





- (EWPerson*)primitiveOwner;
- (void)setPrimitiveOwner:(EWPerson*)value;


@end
