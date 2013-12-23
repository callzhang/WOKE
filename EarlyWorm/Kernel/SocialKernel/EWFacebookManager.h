//
//  EWFacebookManager.h
//  EarlyWorm
//
//  Created by shenslu on 13-10-4.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

#define kFacebookAppID @"226235527539229"

@protocol EWFacebookManagerDelegate <NSObject>

- (void)EWFacebookManagerDidGotFriendList:(NSArray *)friendList isAll:(BOOL)isAll;

@end

@interface EWFacebookManager : NSObject

@property (strong, nonatomic) FBSession *session;

//@property (nonatomic, strong) NSString *accessToken;

+ (EWFacebookManager *)sharedInstance;
+ (void)destroyInstance;
+ (void)unregisterInstanceDelegate;

- (void)RegisterDelegate:(id<EWFacebookManagerDelegate>)delegate;
- (void)UnregisterDelegate;

// Facebook SDK Call Event
- (void)activeFacebookApp;
- (void)doAuth;
- (void)logoutFacebook;

// Social
- (void)getFriendList;
- (void)appendFriendList;

// Send Message
- (void)sendWebLink;

@end
