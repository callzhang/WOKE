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
#import "AWSRuntime.h"
#import <Parse/Parse.h>
#import "AWSSNS.h"

@class EWPerson;

//attribute stored on ManagedObject to identify corresponding PFObject on server
#define kParseObjectID          @"objectId"
//Attribute stored on PFObject to identify corresponding ManagedObject on SQLite
#define kManagedObjectID        @"objectID"
//Parse update queue
#define kParseQueueInsert       @"parse_queue_insert"
#define kParseQueueUpdate       @"parse_queue_update"
#define kParseQueueDelete       @"parse_queue_delete"

@interface EWDataStore : NSObject
@property (nonatomic, retain) AmazonSNSClient *snsClient;
@property (nonatomic, retain) NSManagedObjectModel *model;
@property (nonatomic, retain) dispatch_queue_t dispatch_queue;//Task dispatch queue runs in serial
@property (nonatomic, retain) dispatch_queue_t coredata_queue;//coredata queue runs in serial
@property (nonatomic, retain) NSTimer *serverUpdateTimer;
/**
 *The date that last sync with server
 */
@property (nonatomic, retain) NSDate *lastChecked;


+ (EWDataStore *)sharedInstance;
+ (void)save;
//- (void)registerPushNotification;
+ (void)checkAlarmData;

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
+ (void)registerServerUpdateService;

#pragma mark - CoreData
+ (NSManagedObjectContext *)currentContext;
+ (id)objectForCurrentContext:(NSManagedObject *)obj;

//Core Data and PFObject translation
#pragma mark - Core Data and PFObject translation
+ (NSManagedObject *)getManagedObjectFromParseObject:(PFObject *)object;
+ (PFObject *)getParseObjectFromManagedObject:(NSManagedObject *)managedObject;

#pragma mark - Parse Server methods
/**
 The main method of server update/insert/delete.
 And save ManagedObject.
 @discussion Use this method to update server and save. Replace this method with any ManagedObjectContext save method. Concurrency is NOT supported. Please call it on main thread.
 */
+ (void)updateToServerAndSave;

/**
 Refresh ManagedObject value from server
 */
+ (void)refreshManagedObject:(NSManagedObject *)managedObject;

/**
 Update or Insert PFObject according to given ManagedObject
 */
+ (void)updateParseObjectFromManagedObject:(NSManagedObject *)managedObject;

/**
 Delete PFObject according to given ManagedObject
 */
+ (void)deleteParseObjectWithManagedObject:(NSManagedObject *)managedObject;

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
- (void)updateValueFromParseObject:(PFObject *)object;
/**
 Save ManagedObjectID into update queue in userDefaults
 */
- (void)updateEventually;
/**
 Save ManagedObjectID into delete queue in userDefaults
 */
- (void)deleteEventually;
@end

#pragma mark - Parse Object extension
@interface PFObject (NSManagedObject)
- (void)updateValueFromManagedObject:(NSManagedObject *)managedObject;
@end
