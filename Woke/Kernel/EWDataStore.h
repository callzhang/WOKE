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
#import <AWSRuntime/AWSRuntime.h>
#import <AWSSNS/AWSSNS.h>
#import <Parse/Parse.h>

extern AmazonSNSClient *snsClient;

@class EWPerson;

@interface EWDataStore : NSObject
@property (nonatomic, retain) NSManagedObjectModel *model;
@property (nonatomic, retain) dispatch_queue_t dispatch_queue;//Task dispatch queue runs in serial
@property (nonatomic, retain) dispatch_queue_t coredata_queue;//coredata queue runs in serial
@property (nonatomic, retain) NSTimer *serverUpdateTimer;
/**
 *The date that last sync with server
 */
@property (nonatomic, retain) NSDate *lastChecked;


+ (EWDataStore *)sharedInstance;
- (void)save;
//- (void)registerPushNotification;
- (void)checkAlarmData;

#pragma mark - data
/**
 get Amazon S3 storage data with key from StackMob backend
 */
- (NSData *)getRemoteDataWithKey:(NSString *)key;

/**
 *Get local cached file path for url. If not cached, dispatch a download URLSession
 @param key: the normal string url, not MD5 value
 */
- (NSString *)localPathForKey:(NSString *)key;

/**
 Update the data for key. Create object if not cached.
 */
- (void)updateCacheForKey:(NSString *)key withData:(NSData *)data;

//check cache data
- (NSDate *)lastModifiedDateForObjectAtKey:(NSString *)key;
//deletion
- (void)deleteCacheForKey:(NSString *)key;

/**
 * Register the server update process, which will run periodically to sync with server data
 */
- (void)registerServerUpdateService;

#pragma mark - CoreData
+ (NSManagedObjectContext *)currentContext;
+ (id)objectForCurrentContext:(NSManagedObject *)obj;

//Core Data and PFObject translation
#pragma mark - Core Data and PFObject translation
+ (NSManagedObject *)getManagedObjectFromParseObject:(PFObject *)object;
+ (PFObject *)getParseObjectFromManagedObject:(NSManagedObject *)managedObject;

@end

#pragma mark - Core Data ManagedObject extension
@interface NSManagedObject (PFObject)
- (void)updateValueFromParseObject:(PFObject *)object;
@end

#pragma mark - Parse Object extension
@interface PFObject (NSManagedObject)
- (void)updateValueFromManagedObject:(NSManagedObject *)managedObject;
@end
