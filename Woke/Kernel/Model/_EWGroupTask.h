// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWGroupTask.h instead.

#import <CoreData/CoreData.h>
#import "EWServerObject.h"

extern const struct EWGroupTaskAttributes {
	__unsafe_unretained NSString *added;
	__unsafe_unretained NSString *city;
	__unsafe_unretained NSString *region;
	__unsafe_unretained NSString *time;
} EWGroupTaskAttributes;

extern const struct EWGroupTaskRelationships {
	__unsafe_unretained NSString *medias;
	__unsafe_unretained NSString *messages;
	__unsafe_unretained NSString *participents;
} EWGroupTaskRelationships;

@class EWMedia;
@class EWMessage;
@class EWPerson;

@interface EWGroupTaskID : EWServerObjectID {}
@end

@interface _EWGroupTask : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWGroupTaskID* objectID;

@property (nonatomic, strong) NSDate* added;

//- (BOOL)validateAdded:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* city;

//- (BOOL)validateCity:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* region;

//- (BOOL)validateRegion:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* time;

//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *medias;

- (NSMutableSet*)mediasSet;

@property (nonatomic, strong) EWMessage *messages;

//- (BOOL)validateMessages:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *participents;

- (NSMutableSet*)participentsSet;

@end

@interface _EWGroupTask (MediasCoreDataGeneratedAccessors)
- (void)addMedias:(NSSet*)value_;
- (void)removeMedias:(NSSet*)value_;
- (void)addMediasObject:(EWMedia*)value_;
- (void)removeMediasObject:(EWMedia*)value_;

@end

@interface _EWGroupTask (ParticipentsCoreDataGeneratedAccessors)
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

- (NSString*)primitiveRegion;
- (void)setPrimitiveRegion:(NSString*)value;

- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;

- (NSMutableSet*)primitiveMedias;
- (void)setPrimitiveMedias:(NSMutableSet*)value;

- (EWMessage*)primitiveMessages;
- (void)setPrimitiveMessages:(EWMessage*)value;

- (NSMutableSet*)primitiveParticipents;
- (void)setPrimitiveParticipents:(NSMutableSet*)value;

@end
