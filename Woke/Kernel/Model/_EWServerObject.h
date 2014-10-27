// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWServerObject.h instead.

#import <CoreData/CoreData.h>

extern const struct EWServerObjectAttributes {
	__unsafe_unretained NSString *createdAt;
	__unsafe_unretained NSString *objectId;
	__unsafe_unretained NSString *updatedAt;
} EWServerObjectAttributes;

@interface EWServerObjectID : NSManagedObjectID {}
@end

@interface _EWServerObject : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWServerObjectID* objectID;

@property (nonatomic, strong) NSDate* createdAt;

//- (BOOL)validateCreatedAt:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* objectId;

//- (BOOL)validateObjectId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* updatedAt;

//- (BOOL)validateUpdatedAt:(id*)value_ error:(NSError**)error_;

@end

@interface _EWServerObject (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveCreatedAt;
- (void)setPrimitiveCreatedAt:(NSDate*)value;

- (NSString*)primitiveObjectId;
- (void)setPrimitiveObjectId:(NSString*)value;

- (NSDate*)primitiveUpdatedAt;
- (void)setPrimitiveUpdatedAt:(NSDate*)value;

@end
