// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWSocialGraph.h instead.

#import <CoreData/CoreData.h>


extern const struct EWSocialGraphAttributes {
	__unsafe_unretained NSString *createdAt;
	__unsafe_unretained NSString *facebookFriends;
	__unsafe_unretained NSString *facebookToken;
	__unsafe_unretained NSString *facebookUpdated;
	__unsafe_unretained NSString *objectId;
	__unsafe_unretained NSString *updatedAt;
	__unsafe_unretained NSString *weiboFriends;
	__unsafe_unretained NSString *weiboToken;
	__unsafe_unretained NSString *weiboUpdated;
} EWSocialGraphAttributes;

extern const struct EWSocialGraphRelationships {
	__unsafe_unretained NSString *owner;
} EWSocialGraphRelationships;

extern const struct EWSocialGraphFetchedProperties {
} EWSocialGraphFetchedProperties;

@class EWPerson;


@class NSObject;




@class NSObject;



@interface EWSocialGraphID : NSManagedObjectID {}
@end

@interface _EWSocialGraph : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWSocialGraphID*)objectID;





@property (nonatomic, strong) NSDate* createdAt;



//- (BOOL)validateCreatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id facebookFriends;



//- (BOOL)validateFacebookFriends:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSData* facebookToken;



//- (BOOL)validateFacebookToken:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* facebookUpdated;



//- (BOOL)validateFacebookUpdated:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* objectId;



//- (BOOL)validateObjectId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* updatedAt;



//- (BOOL)validateUpdatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id weiboFriends;



//- (BOOL)validateWeiboFriends:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSData* weiboToken;



//- (BOOL)validateWeiboToken:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* weiboUpdated;



//- (BOOL)validateWeiboUpdated:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) EWPerson *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;





@end

@interface _EWSocialGraph (CoreDataGeneratedAccessors)

@end

@interface _EWSocialGraph (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveCreatedAt;
- (void)setPrimitiveCreatedAt:(NSDate*)value;




- (id)primitiveFacebookFriends;
- (void)setPrimitiveFacebookFriends:(id)value;




- (NSData*)primitiveFacebookToken;
- (void)setPrimitiveFacebookToken:(NSData*)value;




- (NSDate*)primitiveFacebookUpdated;
- (void)setPrimitiveFacebookUpdated:(NSDate*)value;




- (NSString*)primitiveObjectId;
- (void)setPrimitiveObjectId:(NSString*)value;




- (NSDate*)primitiveUpdatedAt;
- (void)setPrimitiveUpdatedAt:(NSDate*)value;




- (id)primitiveWeiboFriends;
- (void)setPrimitiveWeiboFriends:(id)value;




- (NSData*)primitiveWeiboToken;
- (void)setPrimitiveWeiboToken:(NSData*)value;




- (NSDate*)primitiveWeiboUpdated;
- (void)setPrimitiveWeiboUpdated:(NSDate*)value;





- (EWPerson*)primitiveOwner;
- (void)setPrimitiveOwner:(EWPerson*)value;


@end
