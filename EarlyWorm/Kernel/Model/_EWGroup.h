// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWGroup.h instead.

#import <CoreData/CoreData.h>


extern const struct EWGroupAttributes {
	__unsafe_unretained NSString *created;
	__unsafe_unretained NSString *createddate;
	__unsafe_unretained NSString *ewgroup_id;
	__unsafe_unretained NSString *imageKey;
	__unsafe_unretained NSString *lastmoddate;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *statement;
	__unsafe_unretained NSString *topic;
	__unsafe_unretained NSString *wakeupTime;
} EWGroupAttributes;

extern const struct EWGroupRelationships {
	__unsafe_unretained NSString *admin;
	__unsafe_unretained NSString *member;
} EWGroupRelationships;

extern const struct EWGroupFetchedProperties {
} EWGroupFetchedProperties;

@class EWPerson;
@class EWPerson;




@class NSObject;






@interface EWGroupID : NSManagedObjectID {}
@end

@interface _EWGroup : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWGroupID*)objectID;





@property (nonatomic, strong) NSDate* created;



//- (BOOL)validateCreated:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* createddate;



//- (BOOL)validateCreateddate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* ewgroup_id;



//- (BOOL)validateEwgroup_id:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id imageKey;



//- (BOOL)validateImageKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* lastmoddate;



//- (BOOL)validateLastmoddate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* statement;



//- (BOOL)validateStatement:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* topic;



//- (BOOL)validateTopic:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* wakeupTime;



//- (BOOL)validateWakeupTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *admin;

- (NSMutableSet*)adminSet;




@property (nonatomic, strong) NSSet *member;

- (NSMutableSet*)memberSet;





@end

@interface _EWGroup (CoreDataGeneratedAccessors)

- (void)addAdmin:(NSSet*)value_;
- (void)removeAdmin:(NSSet*)value_;
- (void)addAdminObject:(EWPerson*)value_;
- (void)removeAdminObject:(EWPerson*)value_;

- (void)addMember:(NSSet*)value_;
- (void)removeMember:(NSSet*)value_;
- (void)addMemberObject:(EWPerson*)value_;
- (void)removeMemberObject:(EWPerson*)value_;

@end

@interface _EWGroup (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveCreated;
- (void)setPrimitiveCreated:(NSDate*)value;




- (NSDate*)primitiveCreateddate;
- (void)setPrimitiveCreateddate:(NSDate*)value;




- (NSString*)primitiveEwgroup_id;
- (void)setPrimitiveEwgroup_id:(NSString*)value;




- (id)primitiveImageKey;
- (void)setPrimitiveImageKey:(id)value;




- (NSDate*)primitiveLastmoddate;
- (void)setPrimitiveLastmoddate:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitiveStatement;
- (void)setPrimitiveStatement:(NSString*)value;




- (NSString*)primitiveTopic;
- (void)setPrimitiveTopic:(NSString*)value;




- (NSDate*)primitiveWakeupTime;
- (void)setPrimitiveWakeupTime:(NSDate*)value;





- (NSMutableSet*)primitiveAdmin;
- (void)setPrimitiveAdmin:(NSMutableSet*)value;



- (NSMutableSet*)primitiveMember;
- (void)setPrimitiveMember:(NSMutableSet*)value;


@end
