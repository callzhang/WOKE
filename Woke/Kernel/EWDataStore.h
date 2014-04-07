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
#import "StackMob.h"
#import "SMPushClient.h"
#import <AWSRuntime/AWSRuntime.h>
#import <AWSSNS/AWSSNS.h>

/**
 *Shortcut for context for Main thread
 */
//extern NSManagedObjectContext *context;
extern SMClient *client;
extern SMPushClient *pushClient;
extern AmazonSNSClient *snsClient;
//extern NSDate *lastChecked;

@class EWPerson;
@interface EWDataStore : NSObject

@property (nonatomic, retain) NSManagedObjectContext *context;
@property (nonatomic, retain) NSManagedObjectModel *model;
@property (nonatomic, retain) SMCoreDataStore *coreDataStore;
@property (nonatomic, retain) dispatch_queue_t dispatch_queue;//Task dispatch queue runs in serial
@property (nonatomic, retain) dispatch_queue_t coredata_queue;//coredata queue runs in serial
@property (nonatomic, retain) NSTimer *serverUpdateTimer;
/**
 *The date that last sync with server
 */
@property (nonatomic, retain) NSDate *lastChecked;
/**
 This is considered thread safe way to call context for current thread
 */
@property (nonatomic, retain) NSManagedObjectContext *currentContext;


+ (EWDataStore *)sharedInstance;
- (void)save;
//- (void)registerPushNotification;
- (void)checkAlarmData;

//data
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


/**
 * Register the server update process, which will run periodically to sync with server data
 */
- (void)registerServerUpdateService;

//CoreData
+ (SMRequestOptions *)optionFetchCacheElseNetwork;
+ (SMRequestOptions *)optionFetchNetworkElseCache;
+ (NSManagedObjectContext *)currentContext;
+ (id)objectForCurrentContext:(NSManagedObject *)obj;
/**
 *Using block to save ManagedObject in designated background thread serial queue.
 *When change occured in given context
 */
//+ (void)saveDataInBackgroundInBlock:(void(^)(NSManagedObjectContext *currentContext))saveBlock completion:(void(^)(void))completion;

/**
 * User obj's id to fetch from server on another thread
 */
//+ (NSManagedObject *)refreshObjectWithServer:(NSManagedObject *)obj;

/**
 * The thread safe way to get current user
 */
+ (EWPerson *)user;
@end
