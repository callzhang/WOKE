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
@end
