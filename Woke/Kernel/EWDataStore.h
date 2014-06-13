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

//Server update time
#define kServerUpdateInterval            1800 //30 min

//attribute stored on ManagedObject to identify corresponding PFObject on server
#define kParseObjectID          @"objectId"
//Attribute stored on PFObject to identify corresponding ManagedObject on SQLite
#define kManagedObjectID        @"objectID"
//Attribute to store update date
#define kUpdatedDateKey         @"updatedAt"
//Parse update queue
#define kParseQueueInsert       @"parse_queue_insert"
#define kParseQueueUpdate       @"parse_queue_update"
#define kParseQueueDelete       @"parse_queue_delete"

@interface EWDataStore : NSObject
//@property (nonatomic, retain) AmazonSNSClient *snsClient;
@property (nonatomic, retain) NSManagedObjectModel *model;
@property (nonatomic, retain) dispatch_queue_t dispatch_queue;//Task dispatch queue runs in serial
@property (nonatomic, retain) dispatch_queue_t coredata_queue;//coredata queue runs in serial
@property (nonatomic, retain) NSTimer *serverUpdateTimer;
@property (nonatomic, retain) NSSet *updateQueue;
@property (nonatomic, retain) NSSet *insertQueue;
@property (nonatomic, retain) NSSet *deleteQueue;

/**
 *The date that last sync with server
 */
@property (nonatomic, retain) NSDate *lastChecked;


+ (EWDataStore *)sharedInstance;
+ (void)save;
//- (void)registerPushNotification;
//+ (void)checkAlarmData;

#pragma mark - Push notification
/**
 Initiate the Push Notification registration to APNS
 */
+ (void)registerAPNS;
/**
 Handle the returned token for registered device. Register the push service to 3rd party server.
 */
+ (void)registerPushNotificationWithToken:(NSData *)deviceToken;


#pragma mark - data
/**
 get Amazon S3 storage data with key from StackMob backend
 */
+ (NSData *)getRemoteDataWithKey:(NSString *)key;

/**
 *Get local cached file path for url. If not cached, dispatch a download URLSession
 @param key: the normal string url, not MD5 value
 */
+ (NSString *)localPathForKey:(NSString *)key;

/**
 Update the data for key. Create object if not cached.
 */
+ (void)updateCacheForKey:(NSString *)key withData:(NSData *)data;

//check cache data
+ (NSDate *)lastModifiedDateForObjectAtKey:(NSString *)key;
//deletion
+ (void)deleteCacheForKey:(NSString *)key;

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
 @discussion Use this method to update server and save. Replace this method with any ManagedObjectContext save method. Concurrency is NOT supported. Please call it on main thread.
 */
+ (void)updateToServer;

/**
 *Update or Insert PFObject according to given ManagedObject
 *
 *1. First decide create or find parse object, handle error if necessary
 *
 *2. Update PO value and relation with given MO. (-updateValueFromManagedObject:)
 *
 *3. Save PO in background. Save MO to exit method.
 *
 *4. When saved, assign parseID to MO
 *
 *5. Perform save callback block for this PO
 */
+ (void)updateParseObjectFromManagedObject:(NSManagedObject *)managedObject;

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
 
 *2) Iterate through the relations described by entityDescription
 **   -> Delete obsolete related object.
 **   -> For each end point in relationship, To-Many or To-One, find or create MO and assign value to that relationship.
 @discussion The attributes and relationship are updated in sync.
 */
- (void)updateValueAndRelationFromParseObject:(PFObject *)object;

/**
 Get conterparty Parse Object
 */
- (PFObject *)parseObject;

/**
 Refresh ManagedObject value from server in background
 @discussion If the ParseID is not found on this ManagedObject, an insert action will performed.
 */
//- (void)refreshInBackgroundWithCompletion:(void (^)(void))block;

/**
 Refresh ManagedObject value from server in the current thread
 @discussion If the ParseID is not found on this ManagedObject, an insert action will performed.
 */
- (void)refresh;

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

- (NSString *)getPropertyClassByName:(NSString *)name;
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
- (void)updateValueFromManagedObject:(NSManagedObject *)managedObject;

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
@end
