// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMessage.h instead.

#import <CoreData/CoreData.h>
#import "EWServerObject.h"

extern const struct EWMessageAttributes {
	__unsafe_unretained NSString *attribute;
	__unsafe_unretained NSString *text;
	__unsafe_unretained NSString *thumbnail;
	__unsafe_unretained NSString *time;
} EWMessageAttributes;

extern const struct EWMessageRelationships {
	__unsafe_unretained NSString *media;
	__unsafe_unretained NSString *recipient;
	__unsafe_unretained NSString *sender;
} EWMessageRelationships;

@class EWMediaItem;
@class EWPerson;
@class EWPerson;

@class NSObject;

@interface EWMessageID : EWServerObjectID {}
@end

@interface _EWMessage : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWMessageID* objectID;

@property (nonatomic, strong) NSString* text;

//- (BOOL)validateText:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id thumbnail;

//- (BOOL)validateThumbnail:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* time;

//- (BOOL)validateTime:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWMediaItem *media;

//- (BOOL)validateMedia:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWPerson *recipient;

//- (BOOL)validateRecipient:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWPerson *sender;

//- (BOOL)validateSender:(id*)value_ error:(NSError**)error_;

@end

@interface _EWMessage (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveText;
- (void)setPrimitiveText:(NSString*)value;

- (id)primitiveThumbnail;
- (void)setPrimitiveThumbnail:(id)value;

- (NSDate*)primitiveTime;
- (void)setPrimitiveTime:(NSDate*)value;

- (EWMediaItem*)primitiveMedia;
- (void)setPrimitiveMedia:(EWMediaItem*)value;

- (EWPerson*)primitiveRecipient;
- (void)setPrimitiveRecipient:(EWPerson*)value;

- (EWPerson*)primitiveSender;
- (void)setPrimitiveSender:(EWPerson*)value;

@end
