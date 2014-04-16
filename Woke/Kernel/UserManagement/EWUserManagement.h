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

/**
 Main point of login
 */
- (void)login;

/**
 Login with username for cached coredata info
 */
- (void)loginWithCachedDataStore:(NSString *)username withCompletionBlock:(void (^)(void))completionBlock;

/**
 Login with local plist or ADID
 */
- (void)loginWithDeviceIDWithCompletionBlock:(void (^)(void))block;

/**
 Cache user's data
 */
- (void)cacheUserData;

//Log out
+ (void)logout;

//Handle new user
+ (void)handleNewUser;



//logged in tasks
- (void)registerAPNS;
- (void)registerLocation;
- (void)registerPushNotification;
- (void)updateLastSeen;

//facebook
+ (NSArray *)facebookPermissions;
+ (void)loginUsingFacebookWithCompletion:(void (^)(void))block;
- (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user;
- (void)getFacebookFriends;
+ (void)handleFacebookException:(NSError *)exception;


//weibo
- (void)registerWeibo;




@end
