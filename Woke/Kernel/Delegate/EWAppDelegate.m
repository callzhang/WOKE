
//
//  EWAppDelegate.m
//  EarlyWorm
//
//  Created by shenslu on 13-7-11.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWAppDelegate.h"
//view controller
#import "EWAlarmsViewController.h"
#import "EWWakeUpManager.h"
#import "EWUtil.h"
#import "EWFirstTimeViewController.h"
//tools
//#import "TestFlight.h"
//#import "TestFlight+ManualSessions.h"
#import "AVManager.h"
#import "UIViewController+Blur.h"
#import <Parse/Parse.h>

//Manager
#import "EWMediaStore.h"
#import "EWServer.h"
#import "EWUserManagement.h"
#import "EWDataStore.h"

#import "ATConnect.h"
//global view for HUD
#import <Crashlytics/Crashlytics.h>
#import "EWSocialGraphManager.h"

UIViewController *rootViewController;

//Private
@interface EWAppDelegate()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end


@implementation EWAppDelegate
@synthesize backgroundTaskIdentifier;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //crash
    [Crashlytics startWithAPIKey:@"6ec9eab6ca26fcd18d51d0322752b861c63bc348"];
    
    //test flight
//    [TestFlight setOptions:@{ TFOptionManualSessions : @YES }];
//    [TestFlight takeOff:TESTFLIGHT_ACCESS_KEY];
//    [TestFlight manuallyStartSession];
    
    //log
    EWLogInit();
    
    // appetitive
    [ATConnect sharedConnection].apiKey = KATConnectKey;
    
    //Parse
    [Parse setApplicationId:kParseApplicationId clientKey:kParseClientKey];
    //Analytics
    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double
        // counting the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    
    
    //background fetch
    [application setMinimumBackgroundFetchInterval:7200]; //fetch interval: 2hr
    
    //window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    EWAlarmsViewController *controler = [[EWAlarmsViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = controler;
    rootViewController = self.window.rootViewController;
    
    //init coredata and backend server
    [EWDataStore sharedInstance];
    
    //window
    [self.window makeKeyAndVisible];
    
    //User login
    [EWUserManagement login];
    
    //local notification entry
    if (launchOptions) {
        UILocalNotification *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        //Let server class to handle notif info
        if (localNotif) {
            DDLogVerbose(@"Launched with local notification: %@", localNotif);
            [EWServer handleLocalNotification:localNotif];
        }else if (remoteNotif){
            DDLogVerbose(@"Launched with push notification: %@", remoteNotif);
            [EWServer handlePushNotification:remoteNotif];
        }
    }
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];

    return YES;
}

#pragma mark - BACKGROUNDING
//=================>> Point to enter background <<===================
- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    DDLogVerbose(@"Entered background with active time left: %f", application.backgroundTimeRemaining>999?999:application.backgroundTimeRemaining);
    
    //save core data
    [EWSync save];
    
    //clean badge
    application.applicationIconBadgeNumber = 0;
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [FBSession.activeSession close];
    DDLogInfo(@"App is about to terminate");

    //[TestFlight manuallyEndSession];
}


#pragma mark - Weibo
/*
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [WeiboSDK handleOpenURL:url delegate:self];
}*/

#pragma mark - Facebook
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    BOOL handled_1 = [FBSession.activeSession handleOpenURL:url];
    BOOL handled_2 =  [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
    
    return handled_1 && handled_2;
}



#pragma mark - Background fetch method (this is called periodocially
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DDLogVerbose(@"======== Launched in background due to background fetch event ==========");
    //enable audio session and keep audio port
    //[[AVManager sharedManager] registerAudioSession];
    [[AVManager sharedManager] playSystemSound:nil];
    
    //check media assets
    BOOL newMedia = [[EWMediaStore sharedInstance] checkMediaAssets];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        DDLogVerbose(@"Returned background fetch handler with %@", newMedia?@"new data":@"no data");
        if (newMedia) {
            completionHandler(UIBackgroundFetchResultNewData);
        }else{
            completionHandler(UIBackgroundFetchResultNoData);
        }
        
    });
    
}



#pragma mark - Push Notification registration
//Presist the device token
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    
    //Register Push on Server
    [EWServer registerPushNotificationWithToken:deviceToken];
    
 
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    //[NSException raise:@"Failed to regiester push token with apple" format:@"Reason: %@", err.description];
    DDLogVerbose(@"*** Failed to regiester push token with apple. Error: %@", err.description);
    NSString *str = [NSString stringWithFormat:@"Unable to regiester Push Notifications. Reason: %@", err.localizedDescription];
    EWAlert(str);
}

//entrance of Local Notification
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    [EWServer handleLocalNotification:notification];
}

//Receive remote notification in background or in foreground
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    
    if (application.applicationState == UIApplicationStateInactive) {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    
    if (!me) {
        return;
    }
    
    if ([application applicationState] == UIApplicationStateActive) {
        DDLogVerbose(@"Push Notification received when app is running: %@", userInfo);
    }else{
        DDLogVerbose(@"Push Notification received when app is in background(%ld): %@", (long)application.applicationState, userInfo);
    }
    
    //handle push
    [EWServer handlePushNotification:userInfo];
    
    //return handler
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(29.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        DDLogVerbose(@"@@@@@@@ Push conpletion handle returned. @@@@@@@@@");
        completionHandler(UIBackgroundFetchResultNewData);
    });
}

#pragma mark - Background transfer event

//Store the completion handler. The completion handler is invoked by the view controller's checkForAllDownloadsHavingCompleted method (if all the download tasks have been completed).
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    DDLogVerbose(@"%s: APP received message and need to handle the background transfer events", __func__);
    //store the completionHandler
    //EWDownloadManager *manager = [EWDownloadManager sharedInstance];
	//manager.backgroundSessionCompletionHandler = completionHandler;
}



@end

/*
@implementation EWAppDelegate (DownloadMgr)

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFailedDownload:(NSError *)error {
    
}

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFinishedDownload:(NSData *)result {
    DDLogVerbose(@"Dowload Success %@, %@ ",mgr.description, mgr.urlString);
    
    [self handleDownlownedData:result fromManager:mgr];
}

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFinishedDownloadString:(NSString *)resultString{
    //
}

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFinishedDownloadData:(NSData *)resultData{
    //
}
@end
*/
