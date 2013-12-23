// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMediaItem.h instead.

#import <CoreData/CoreData.h>


extern const struct EWMediaItemAttributes {
	__unsafe_unretained NSString *audioKey;
	__unsafe_unretained NSString *createddate;
	__unsafe_unretained NSString *ewmediaitem_id;
	__unsafe_unretained NSString *imageKey;
	__unsafe_unretained NSString *lastmoddate;
	__unsafe_unretained NSString *mediaType;
	__unsafe_unretained NSString *message;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *videoKey;
} EWMediaItemAttributes;

extern const struct EWMediaItemRelationships {
	__unsafe_unretained NSString *author;
	__unsafe_unretained NSString *groupTask;
	__unsafe_unretained NSString *tasks;
} EWMediaItemRelationships;

extern const struct EWMediaItemFetchedProperties {
} EWMediaItemFetchedProperties;

@class EWPerson;
@class EWGroupTask;
@class EWTaskItem;











@interface EWMediaItemID : NSManagedObjectID {}
@end

@interface _EWMediaItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EWMediaItemID*)objectID;





@property (nonatomic, strong) NSString* audioKey;



//- (BOOL)validateAudioKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* createddate;



//- (BOOL)validateCreateddate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* ewmediaitem_id;



//- (BOOL)validateEwmediaitem_id:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* imageKey;



//- (BOOL)validateImageKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* lastmoddate;



//- (BOOL)validateLastmoddate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* mediaType;



//- (BOOL)validateMediaType:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* message;



//- (BOOL)validateMessage:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* title;



//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* videoKey;



//- (BOOL)validateVideoKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) EWPerson *author;

//- (BOOL)validateAuthor:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet *groupTask;

- (NSMutableSet*)groupTaskSet;




@property (nonatomic, strong) NSSet *tasks;

- (NSMutableSet*)tasksSet;





@end

@interface _EWMediaItem (CoreDataGeneratedAccessors)

- (void)addGroupTask:(NSSet*)value_;
- (void)removeGroupTask:(NSSet*)value_;
- (void)addGroupTaskObject:(EWGroupTask*)value_;
- (void)removeGroupTaskObject:(EWGroupTask*)value_;

- (void)addTasks:(NSSet*)value_;
- (void)removeTasks:(NSSet*)value_;
- (void)addTasksObject:(EWTaskItem*)value_;
- (void)removeTasksObject:(EWTaskItem*)value_;

@end

@interface _EWMediaItem (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveAudioKey;
- (void)setPrimitiveAudioKey:(NSString*)value;




- (NSDate*)primitiveCreateddate;
- (void)setPrimitiveCreateddate:(NSDate*)value;




- (NSString*)primitiveEwmediaitem_id;
- (void)setPrimitiveEwmediaitem_id:(NSString*)value;




- (NSString*)primitiveImageKey;
- (void)setPrimitiveImageKey:(NSString*)value;




- (NSDate*)primitiveLastmoddate;
- (void)setPrimitiveLastmoddate:(NSDate*)value;




- (NSString*)primitiveMediaType;
- (void)setPrimitiveMediaType:(NSString*)value;




- (NSString*)primitiveMessage;
- (void)setPrimitiveMessage:(NSString*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSString*)primitiveVideoKey;
- (void)setPrimitiveVideoKey:(NSString*)value;





- (EWPerson*)primitiveAuthor;
- (void)setPrimitiveAuthor:(EWPerson*)value;



- (NSMutableSet*)primitiveGroupTask;
- (void)setPrimitiveGroupTask:(NSMutableSet*)value;



- (NSMutableSet*)primitiveTasks;
- (void)setPrimitiveTasks:(NSMutableSet*)value;


@end
