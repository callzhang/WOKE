//
//  EWWeiboManager.h
//  EarlyWorm
//
//  Created by shenslu on 13-9-24.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WeiboSDK.h"

#define kWeiboSDKAppKey  @"314286162"

@protocol EWWeiboManagerDelegate <NSObject>

- (void)EWWeiboManagerDidGotFriendList:(NSArray *)friendList isAll:(BOOL)isAll;

@end

@interface EWWeiboManager : NSObject

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSDictionary *userInfo;

+ (EWWeiboManager *)sharedInstance;
+ (void)destroyInstance;
+ (void)unregisterInstanceDelegate;

- (void)RegisterDelegate:(id<EWWeiboManagerDelegate>)delegate;
- (void)UnregisterDelegate;

// Weibo SDK Call Event
- (void)registerApp;
- (void)doAuth;
- (void)logoutWeibo;

// Social
- (void)inviteFriend;
- (void)getFriendList;
- (void)appendFriendList;

// Send Message
- (void)sendWebLink;

// Weibo SDK CallBacks
/**
 收到一个来自微博客户端程序的请求
 收到微博的请求后,第三方应用应该按照请求类型进行处理,处理完后必须通过 [WeiboSDK sendResponse:] 将结果回传给微博
 @param request 具体的请求对象
 */
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request;

/**
 收到一个来自微博客户端程序的响应
 收到微博的响应后,第三方应用可以通过响应类型、响应的数据和 [WBBaseResponse userInfo] 中的数据完成自己的功能
 @param response 具体的响应对象
 */
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response;

/**
 收到一个来自微博SDK的响应
 
 收到微博SDK对于发起的接口请求的请求的响应
 @param JsonObject 具体的响应返回内容
 @param error 当有网络错误时返回的NSError，无网络错误返回nil
 */

- (void)didReceiveWeiboSDKResponse:(id)JsonObject err:(NSError *)error;


@end
