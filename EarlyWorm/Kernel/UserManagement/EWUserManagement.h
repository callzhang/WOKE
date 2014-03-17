//
//  EWUserManagement.h
//  EarlyWorm
//
//  Created by Lei on 1/3/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StackMob.h"
#import <FacebookSDK/FacebookSDK.h>


@interface EWUserManagement : NSObject
+ (EWUserManagement *)sharedInstance;

- (void)login;
- (void)logout;
- (void)registerAPNS;
- (void)registerLocation;
- (void)registerWeibo;
- (void)registerFacebook;
- (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user;
- (void)registerPushNotification;

/**
 Login with username for cached coredata info
 */
- (void)loginWithCachedDataStore:(NSString *)username withCompletionBlock:(void (^)(void))completionBlock;

/**
 Login with local plist or ADID
 */
- (void)loginWithDeviceIDWithCompletionBlock:(void (^)(void))block;

@end
