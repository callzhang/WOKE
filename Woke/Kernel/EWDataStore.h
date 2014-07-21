//
//  EWStore.h
//  EarlyWorm
//
//  This class manages Core Data related properties and functions, such as context and model.
//  It also manages backend: StockMob related and Push notification registration
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
//#import <AWSRuntime/AWSRuntime.h>
#import <Parse/Parse.h>
//#import <AWSSNS/AWSSNS.h>



@class EWPerson;
typedef void (^EWSavingCallback)(void);


//Server update time
#define kServerUpdateInterval            1800 //30 min
#define kStalelessInterval               30

//attribute stored on ManagedObject to identify corresponding PFObject on server
#define kParseObjectID          @"objectId"
//Attribute stored on PFObject to identify corresponding ManagedObject on SQLite, not used
#define kManagedObjectID        @"objectID"
//The timestamp when MO gets updated from PO
#define kUpdatedDateKey         @"updatedAt"
//Not used
#define kCreatedDateKey         @"createdAt"
//Parse update queue
#define kParseQueueInsert       @"parse_queue_insert"
#define kParseQueueUpdate       @"parse_queue_update"
#define kParseQueueDelete       @"parse_queue_delete"
#define kParseQueueWorking      @"parse_queue_working"
#define kUserID                 @"user_object_id"
#define kUsername               @"username"

@interface EWDataStore : NSObject
//@property (nonatomic, retain) AmazonSNSClient *snsClient;
@property (nonatomic, retain) NSManagedObjectModel *model;
@property (nonatomic, retain) dispatch_queue_t dispatch_queue;//Task dispatch queue runs in serial
@property (nonatomic, retain) dispatch_queue_t coredata_queue;//coredata queue runs in serial
@property (nonatomic, retain) NSTimer *serverUpdateTimer;
@property (nonatomic, retain) NSDate *lastChecked;//The date that last sync with server
@property (nonatomic, retain) NSMutableArray *saveCallbacks;


#pragma mark - Queue
+ (NSSet *) updateQueue;
+ (NSSet *) insertQueue;
+ (NSSet *) deleteQueue;
+ (NSSet *) workingQueue;//the working queue


+ (EWDataStore *)sharedInstance;

#pragma mark - PARSE
/**
 The main save function, it save and upload to the server
 */
+ (void)save;
+ (void)saveWithCompletion:(EWSavingCallback)block;
+ (void)saveToLocal:(NSManagedObject *)mo;


#pragma mark - data
///**
// get Amazon S3 storage data with key from StackMob backend
// */
//+ (NSData *)getRemoteDataWithKey:(NSString *)key;
//
///**
// *Get local cached file path for url. If not cached, dispatch a download URLSession
// @param key: the normal string url, not MD5 value
// */
//+ (NSString *)localPathForKey:(NSString *)key;
//
///**
// Update the data for key. Create object if not cached.
// */
//+ (void)updateCacheForKey:(NSString *)key withData:(NSData *)data;
//
////check cache data
//+ (NSDate *)lastModifiedDateForObjectAtKey:(NSString *)key;
////deletion
//+ (void)deleteCacheForKey:(NSString *)key;

/**
 * Register the server update process, which will run periodically to sync with server data
 */
- (void)registerServerUpdateService;

#pragma mark - CoreData
+ (NSManagedObjectContext *)currentContext;
+ (id)objectForCurrentContext:(NSManagedObject *)obj;


#pragma mark - Parse Server methods
/**
 The main method of server update/insert/delete.
 And save ManagedObject.
 @discussion Please do not call this method directly. It is scheduled when you call save method.
 */
+ (void)updateToServer;

/**
 *Update or Insert PFObject according to given ManagedObject
 *
 *1. First decide create or find parse object, handle error if necessary
 *
 *2. Update PO value and relation with given MO. (-updateValueFromManagedObject:) If related PO doesn't exist, create a PO async, and assign the newly created related PO to the relation.
 *
 *3. Save PO in background.
 *
 *4. When saved, assign parseID to MO
 *
 *5. Perform save callback block for this PO
 */
+ (void)updateParseObjectFromManagedObjectID:(NSManagedObjectID *)managedObjectID;

/**
 Find or delete ManagedObject by Entity and by Server Object
 @discussion This method only updates attributes of MO, not relationship. So it is only used to refresh value of specific MO
 */
//+ (NSManagedObject *)findOrCreateManagedObjectWithParseObjectID:(NSString *)objectId;

/**
 Delete PFObject in server
 */
+ (void)deleteParseObject:(PFObject *)parseObject;

/**
 Perform save callback for managedObject
 */
+ (void)performSaveCallbacksWithParseObject:(PFObject *)parseObject andManagedObjectID:(NSManagedObjectID *)managedObjectID;
/**
 Access Global Save Callback dictionary and add blcok with key of ManagedObjectID
 */
+ (void)addSaveCallback:(PFObjectResultBlock)callback forManagedObjectID:(NSManagedObjectID *)objectID;

@end



#pragma mark - Core Data ManagedObject extension
@interface NSManagedObject (PFObject)
/**
 Update ManagedObject from correspoinding Server Object
 
 *1) First assign the attribute value from server object
 
 *2) Iterate through the relations
 **   -> Delete obsolete related object.
 **   -> For each end point in relationship, To-Many or To-One, find or create MO and assign value to that relationship.
 @discussion The attributes and relationship are updated in sync.
 */
- (void)updateValueAndRelationFromParseObject:(PFObject *)object;

/**
 Get conterparty Parse Object and assign value to self
 */
- (PFObject *)parseObject;
/**
 Get PO only
 */
- (PFObject *)getParseObjectWithError:(NSError **)error;
/**
 Create a parse object
 */
- (void)createParseObjectWithCompletion:(void (^)(void))block;

/**
 Refresh ManagedObject value from server in background
 @discussion If the ParseID is not found on this ManagedObject, an insert action will performed.
 */
- (void)refreshInBackgroundWithCompletion:(void (^)(void))block;

/**
 Refresh ManagedObject value from server in the current thread
 @discussion If the ParseID is not found on this ManagedObject, an insert action will performed.
 */
- (void)refresh;

/**
 *Refresh related MO from server in background.
 *
 *This method iterates all objects related to the MO and refresh (updatedDate) to make sure my relevant data is copied locally.
 *
 *TODO: It also checks that if any data on server has duplication.
 *@discussion it is usually used for current user object (me)
 */
- (void)refreshRelatedInBackground;

/**
 Update object from PO for value, and related PO that is returned as Array of pointers
 The goal is to call server once and get as much as possible.
 */
- (void)refreshShallowWithCompletion:(void (^)(void))block;

/**
 Assign only attribute values (not relation) to the ManagedObject from the Parse Object
 */
- (void)assignValueFromParseObject:(PFObject *)object;

/**
 Save ManagedObjectID into update queue in userDefaults
 */
- (void)updateEventually;

/**
 Save ManagedObjectID into delete queue in userDefaults
 */
- (void)deleteEventually;

#pragma mark - Helper methods
/**
 Reflex method to search for runtime attributes
 */
- (NSString *)getPropertyClassByName:(NSString *)name;

/**
 Check if the MO's updatedAt time is more than the server refresh interval
 */
- (BOOL)isOutDated;

//Parse objectId
- (NSString *)serverID;

@end

#pragma mark - Parse Object extension
@interface PFObject (NSManagedObject)
/**
 Update parse value and relation to server object. Create if no ParseID on ManagedObject.
 1) First assign the attribute value from ManagedObject
 2) Iterate through the relations described by entityDescription
 -> Delete obsolete related object async
 -> For each end point in relationship, To-Many or To-One, find corresponding PO and assign value to that relationship. If parseID not exist on that MO, it creates a save callback block, indicating that there is a 'need' to establish relation to that PO once it is created on server.
 @discussion The attributes are updated in sync, the relationship is updated async for new andn deleted related objects.
 */
- (void)updateFromManagedObject:(NSManagedObject *)managedObject;

/**
 The ManagedObject will only update attributes but not relations
 */
- (NSManagedObject *)managedObject;

- (NSString *)localClassName;
@end

@interface NSEntityDescription (Parse)
- (NSString *)serverClassName;
@end

@interface NSString (Parse)
- (NSString *)serverType;
- (BOOL)skipUpload;
@end
