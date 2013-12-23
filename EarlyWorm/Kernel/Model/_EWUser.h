// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWUser.h instead.

#import <CoreData/CoreData.h>


extern const struct EWUserAttributes {
	__unsafe_unretained NSString *fbID;
	__unsafe_unretained NSString *fbToken;
	__unsafe_unretained NSString *parseID;
	__unsafe_unretained NSString *password;
	__unsafe_unretained NSString *userName;
	__unsafe_unretained NSString *uuid;
	__unsafe_unretained NSString *weiboID;
	__unsafe_unretained NSString *weiboToken;
	__unsafe_unretained NSString *weixinID;
	__unsafe_unretained NSString *weixinToken;
} EWUserAttributes;

extern const struct EWUserRelationships {
	__unsafe_unretained NSString *person;
} EWUserRelationships;

extern const struct EWUserFetchedProperties {
} EWUserFetchedProperties;

@class EWPerson;


@class NSObject;





@class NSObject;

@class NSObject;

@interface EWUserID : NSManagedObjectID {}
@end

@interface _EWUser : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWUserID*)objectID;





@property (nonatomic, strong) NSString* fbID;



//- (BOOL)validateFbID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id fbToken;



//- (BOOL)validateFbToken:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* parseID;



//- (BOOL)validateParseID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* password;



//- (BOOL)validatePassword:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* userName;



//- (BOOL)validateUserName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* uuid;



//- (BOOL)validateUuid:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* weiboID;



//- (BOOL)validateWeiboID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id weiboToken;



//- (BOOL)validateWeiboToken:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* weixinID;



//- (BOOL)validateWeixinID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id weixinToken;



//- (BOOL)validateWeixinToken:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) EWPerson *person;

//- (BOOL)validatePerson:(id*)value_ error:(NSError**)error_;





@end

@interface _EWUser (CoreDataGeneratedAccessors)

@end

@interface _EWUser (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveFbID;
- (void)setPrimitiveFbID:(NSString*)value;




- (id)primitiveFbToken;
- (void)setPrimitiveFbToken:(id)value;




- (NSString*)primitiveParseID;
- (void)setPrimitiveParseID:(NSString*)value;




- (NSString*)primitivePassword;
- (void)setPrimitivePassword:(NSString*)value;




- (NSString*)primitiveUserName;
- (void)setPrimitiveUserName:(NSString*)value;




- (NSString*)primitiveUuid;
- (void)setPrimitiveUuid:(NSString*)value;




- (NSString*)primitiveWeiboID;
- (void)setPrimitiveWeiboID:(NSString*)value;




- (id)primitiveWeiboToken;
- (void)setPrimitiveWeiboToken:(id)value;




- (NSString*)primitiveWeixinID;
- (void)setPrimitiveWeixinID:(NSString*)value;




- (id)primitiveWeixinToken;
- (void)setPrimitiveWeixinToken:(id)value;





- (EWPerson*)primitivePerson;
- (void)setPrimitivePerson:(EWPerson*)value;


@end
