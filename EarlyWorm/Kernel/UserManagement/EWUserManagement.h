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
- (void)registerWeibo;
- (void)registerFacebook;
- (void)updateUserData:(NSDictionary<FBGraphUser> *)user;
@end
