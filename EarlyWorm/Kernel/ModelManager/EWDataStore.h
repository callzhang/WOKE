//
//  EWStore.h
//  EarlyWorm
//
//  This class is a singleton object that manages Core Data related properties and functions, such as context and model.
//  It also manages backend objects like StockMob related stuff
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
- (NSData *)getRemoteDataWithKey:(NSString *)key;
@end
