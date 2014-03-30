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

extern NSManagedObjectContext *context;
extern SMClient *client;
extern SMPushClient *pushClient;
extern AmazonSNSClient *snsClient;
extern NSDate *lastChecked;

@interface EWDataStore : NSObject

@property (nonatomic, retain) NSManagedObjectContext *context;
@property (nonatomic) NSManagedObjectModel *model;
@property (nonatomic) SMCoreDataStore *coreDataStore;
@property (nonatomic) dispatch_queue_t dispatch_queue;
@property (nonatomic, retain) NSTimer *serverUpdateTimer;
/**
 This is considered thread safe way to call context for current thread
 */
@property (nonatomic) NSManagedObjectContext *currentContext;


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
 */
- (NSString *)localPathForUrl:(NSString *)url;

//Update the data for key
- (void)updateCacheForKey:(NSString *)key withData:(NSData *)data;

//check cache data
- (NSDate *)lastModifiedDateForObjectAtKey:(NSString *)key;


/**
 * Register the server update process, which will run periodically to sync with server data
 */
- (void)registerServerUpdateService;


@end
