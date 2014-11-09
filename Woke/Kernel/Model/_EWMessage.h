// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMessage.h instead.

#import <CoreData/CoreData.h>
#import "EWServerObject.h"

extern const struct EWMessageAttributes {
	__unsafe_unretained NSString *read;
	__unsafe_unretained NSString *text;
	__unsafe_unretained NSString *thumbnail;
	__unsafe_unretained NSString *time;
	__unsafe_unretained NSString *type;
} EWMessageAttributes;

extern const struct EWMessageRelationships {
	__unsafe_unretained NSString *media;
	__unsafe_unretained NSString *recipient;
	__unsafe_unretained NSString *sender;
} EWMessageRelationships;

extern const struct EWMessageFetchedProperties {
} EWMessageFetchedProperties;

@class EWMedia;
@class EWPerson;
@class EWPerson;



@class NSObject;



@interface EWMessageID : NSManagedObjectID {}
@end

@interface _EWMessage : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWMessageID*)objectID;





@property (nonatomic, strong) NSDate* read;



//- (BOOL)validateRead:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* text;



//- (BOOL)validateText:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id thumbnail;



//- (BOOL)validateThumbnail:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* time;



//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* type;



//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) EWMedia *media;

//- (BOOL)validateMedia:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) EWPerson *recipient;

//- (BOOL)validateRecipient:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) EWPerson *sender;

//- (BOOL)validateSender:(id*)value_ error:(NSError**)error_;





@end

@interface _EWMessage (CoreDataGeneratedAccessors)

@end

@interface _EWMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveRead;
- (void)setPrimitiveRead:(NSDate*)value;




- (NSString*)primitiveText;
- (void)setPrimitiveText:(NSString*)value;




- (id)primitiveThumbnail;
- (void)setPrimitiveThumbnail:(id)value;




- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;




- (NSString*)primitiveType;
- (void)setPrimitiveType:(NSString*)value;





- (EWMedia*)primitiveMedia;
- (void)setPrimitiveMedia:(EWMedia*)value;



- (EWPerson*)primitiveRecipient;
- (void)setPrimitiveRecipient:(EWPerson*)value;



- (EWPerson*)primitiveSender;
- (void)setPrimitiveSender:(EWPerson*)value;


@end
