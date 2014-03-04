//
//  EWAppDelegate.h
//  EarlyWorm
//
//  Created by shenslu on 13-7-11.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WeiboSDK.h"
#import <FacebookSDK/FacebookSDK.h>

extern UIViewController *rootViewController;

@interface EWAppDelegate : UIResponder <UIApplicationDelegate, WeiboSDKDelegate, WeiboSDKJSONDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;

@end
