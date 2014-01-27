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

extern NSManagedObjectContext *context;
extern SMClient *client;
extern SMPushClient *pushClient;

@interface EWDataStore : NSObject

@property (nonatomic) NSManagedObjectContext *context;
@property (nonatomic) NSManagedObjectModel *model;
@property (nonatomic) SMCoreDataStore *coreDataStore;

+ (EWDataStore *)sharedInstance;
- (void)save;
- (void)registerPushNotification;
- (void)checkAlarmData;

//data
/**
 get Amazon S3 storage data with key from StackMob backend
 */
- (NSData *)getRemoteDataWithKey:(NSString *)key;
@end
