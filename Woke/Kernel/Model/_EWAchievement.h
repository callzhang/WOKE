// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWAchievement.h instead.

#import <CoreData/CoreData.h>


extern const struct EWAchievementAttributes {
	__unsafe_unretained NSString *createdAt;
	__unsafe_unretained NSString *explaination;
	__unsafe_unretained NSString *image_key;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *objectId;
	__unsafe_unretained NSString *time;
	__unsafe_unretained NSString *type;
	__unsafe_unretained NSString *updatedAt;
} EWAchievementAttributes;

extern const struct EWAchievementRelationships {
	__unsafe_unretained NSString *owner;
} EWAchievementRelationships;

extern const struct EWAchievementFetchedProperties {
} EWAchievementFetchedProperties;

@class EWPerson;










@interface EWAchievementID : NSManagedObjectID {}
@end

@interface _EWAchievement : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWAchievementID*)objectID;





@property (nonatomic, strong) NSString* createdAt;



//- (BOOL)validateCreatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* explaination;



//- (BOOL)validateExplaination:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* image_key;



//- (BOOL)validateImage_key:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* objectId;



//- (BOOL)validateObjectId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* time;



//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* type;



//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* updatedAt;



//- (BOOL)validateUpdatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) EWPerson *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;





@end

@interface _EWAchievement (CoreDataGeneratedAccessors)

@end

@interface _EWAchievement (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveCreatedAt;
- (void)setPrimitiveCreatedAt:(NSString*)value;




- (NSString*)primitiveExplaination;
- (void)setPrimitiveExplaination:(NSString*)value;




- (NSString*)primitiveImage_key;
- (void)setPrimitiveImage_key:(NSString*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitiveObjectId;
- (void)setPrimitiveObjectId:(NSString*)value;




- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;




- (NSString*)primitiveType;
- (void)setPrimitiveType:(NSString*)value;




- (NSDate*)primitiveUpdatedAt;
- (void)setPrimitiveUpdatedAt:(NSDate*)value;





- (EWPerson*)primitiveOwner;
- (void)setPrimitiveOwner:(EWPerson*)value;


@end
