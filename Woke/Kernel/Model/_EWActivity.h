// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWActivity.h instead.

#import <CoreData/CoreData.h>
#import "EWServerObject.h"

extern const struct EWActivityAttributes {
	__unsafe_unretained NSString *completed;
	__unsafe_unretained NSString *friendID;
	__unsafe_unretained NSString *friended;
	__unsafe_unretained NSString *sleepTime;
	__unsafe_unretained NSString *statement;
	__unsafe_unretained NSString *time;
	__unsafe_unretained NSString *type;
} EWActivityAttributes;

extern const struct EWActivityRelationships {
	__unsafe_unretained NSString *medias;
	__unsafe_unretained NSString *owner;
} EWActivityRelationships;

extern const struct EWActivityFetchedProperties {
} EWActivityFetchedProperties;

@class EWMedia;
@class EWPerson;









@interface EWActivityID : NSManagedObjectID {}
@end

@interface _EWActivity : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWActivityID*)objectID;





@property (nonatomic, strong) NSDate* completed;



//- (BOOL)validateCompleted:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* friendID;



//- (BOOL)validateFriendID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* friended;



@property BOOL friendedValue;
- (BOOL)friendedValue;
- (void)setFriendedValue:(BOOL)value_;

//- (BOOL)validateFriended:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* sleepTime;



//- (BOOL)validateSleepTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* statement;



//- (BOOL)validateStatement:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* time;



//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* type;



//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *medias;

- (NSMutableSet*)mediasSet;




@property (nonatomic, strong) EWPerson *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;





@end

@interface _EWActivity (CoreDataGeneratedAccessors)

- (void)addMedias:(NSSet*)value_;
- (void)removeMedias:(NSSet*)value_;
- (void)addMediasObject:(EWMedia*)value_;
- (void)removeMediasObject:(EWMedia*)value_;

@end

@interface _EWActivity (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveCompleted;
- (void)setPrimitiveCompleted:(NSDate*)value;




- (NSString*)primitiveFriendID;
- (void)setPrimitiveFriendID:(NSString*)value;




- (NSNumber*)primitiveFriended;
- (void)setPrimitiveFriended:(NSNumber*)value;

- (BOOL)primitiveFriendedValue;
- (void)setPrimitiveFriendedValue:(BOOL)value_;




- (NSDate*)primitiveSleepTime;
- (void)setPrimitiveSleepTime:(NSDate*)value;




- (NSString*)primitiveStatement;
- (void)setPrimitiveStatement:(NSString*)value;




- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;




- (NSString*)primitiveType;
- (void)setPrimitiveType:(NSString*)value;





- (NSMutableSet*)primitiveMedias;
- (void)setPrimitiveMedias:(NSMutableSet*)value;



- (EWPerson*)primitiveOwner;
- (void)setPrimitiveOwner:(EWPerson*)value;


@end
