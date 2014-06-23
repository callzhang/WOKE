//
//  EWUserManagement.h
//  EarlyWorm
//
//  Created by Lei on 1/3/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import <Parse/Parse.h>

@interface EWUserManagement : NSObject
+ (EWUserManagement *)sharedInstance;

#pragma mark - Login/Logout
/**
 Main point of login
 */
+ (void)login;
+ (void)showLoginPanel;
+ (EWPerson *)me;
/**
 Login with PFUser for cached coredata info
 This is a
 */
+ (void)loginWithServerUser:(PFUser *)user withCompletionBlock:(void (^)(void))completionBlock;

/**
 Login with local plist or ADID
 */
+ (void)loginWithDeviceIDWithCompletionBlock:(void (^)(void))block;

/**
 Log in with temporary parse user
 */
//+ (void)loginWithTempUser:(void (^)(void))block;

/**
 Cache user's data
 */
//+ (void)cacheUserData;

//Log out
+ (void)logout;

//Handle new user
+ (void)handleNewUser;


#pragma mark - logged in tasks
+ (void)registerLocation;
+ (void)updateLastSeen;

#pragma mark - facebook
//high level stuff
+ (void)loginParseWithFacebookWithCompletion:(void (^)(void))block;
//+ (void)loginUsingFacebookWithCompletion:(void (^)(void))block;
+ (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user;
+ (void)getFacebookFriends;
+ (void)updateFacebookInfo;
//low level request
+ (NSArray *)facebookPermissions;
+ (void)openFacebookSessionWithCompletion:(void (^)(void))block;
+ (void)handleFacebookException:(NSError *)exception;
//+ (void)facebookSessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error;



#pragma mark - weibo
//+ (void)registerWeibo;




@end
