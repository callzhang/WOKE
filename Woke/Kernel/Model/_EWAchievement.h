// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWAchievement.h instead.

#import <CoreData/CoreData.h>
#import "EWServerObject.h"

extern const struct EWAchievementAttributes {
	__unsafe_unretained NSString *body;
	__unsafe_unretained NSString *image;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *time;
	__unsafe_unretained NSString *type;
} EWAchievementAttributes;

extern const struct EWAchievementRelationships {
	__unsafe_unretained NSString *owner;
} EWAchievementRelationships;

@class EWPerson;

@class NSObject;

@interface EWAchievementID : EWServerObjectID {}
@end

@interface _EWAchievement : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWAchievementID* objectID;

@property (nonatomic, strong) NSString* body;

//- (BOOL)validateBody:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id image;

//- (BOOL)validateImage:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* time;

//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* type;

//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWPerson *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;

@end

@interface _EWAchievement (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveBody;
- (void)setPrimitiveBody:(NSString*)value;

- (id)primitiveImage;
- (void)setPrimitiveImage:(id)value;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;

- (EWPerson*)primitiveOwner;
- (void)setPrimitiveOwner:(EWPerson*)value;

@end
