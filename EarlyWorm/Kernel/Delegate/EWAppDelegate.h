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
//StackMob
#import "StackMob.h"
#import "SMPushClient.h"

@interface EWAppDelegate : UIResponder <UIApplicationDelegate, WeiboSDKDelegate,WeiboSDKJSONDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;
@property (nonatomic) SMClient *client;
@property (nonatomic) SMPushClient *pushClient;
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) SMCoreDataStore *coreDataStore;


@end
