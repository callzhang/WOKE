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
#import "EWSocialViewController.h"
#import "EWSettingsViewController.h"
#import "EWWakeUpViewController.h"
#import "EWAlarmManager.h"
#import "EWTaskStore.h"
#import "EWPersonStore.h"

//tools
#import "TestFlight.h"
#import "FSAudioStream.h"
#import "AVManager.h"

//model
#import "EWTaskItem.h"
#import "EWMediaItem.h"
#import "EWDownloadManager.h"
#import "EWServer.h"
#import "EWUserManagement.h"
#import "EWDataStore.h"

//global view for HUD
UIViewController *rootViewController;

//Private

@interface EWAppDelegate(){
    EWTaskItem *taskInAction;
    NSTimer *myTimer;
    long count;
    FSAudioStream *_audioStream;
}

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic, strong) NSMutableArray *musicList;

@end


@implementation EWAppDelegate
@synthesize backgroundTaskIdentifier;
//@synthesize myTimer;
//@synthesize count;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //test flight
    [TestFlight takeOff:TESTFLIGHT_ACCESS_KEY];
    
    //background fetch
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    //window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //controller
    EWAlarmsViewController *alarmController = [[EWAlarmsViewController alloc] init];
    UINavigationController *alarmsNavigationController = [[UINavigationController alloc] initWithRootViewController:alarmController];
    
    EWSocialViewController *taskController = [[EWSocialViewController alloc] init];
    UINavigationController *tasksNavigationController = [[UINavigationController alloc] initWithRootViewController:taskController];

    
    EWSettingsViewController *settingsController = [[EWSettingsViewController alloc] init];
    UINavigationController *settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsController];
    
    self.tabBarController = [[UITabBarController alloc] init];
    //self.tabBarController.delegate = self;
    self.tabBarController.viewControllers = @[alarmsNavigationController, tasksNavigationController, settingsNavigationController];
    self.window.rootViewController = self.tabBarController;
    rootViewController = self.window.rootViewController;
    
    //local notification entry
    if (launchOptions) {
        UILocalNotification *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        //Let server class to handle notif info
        if (localNotif) {
            NSLog(@"Launched with local notification: %@", localNotif);
            [EWServer handleAppLaunchNotification:localNotif];
        }else if (remoteNotif){
            NSLog(@"Launched with push notification: %@", remoteNotif);
            [EWServer handleAppLaunchNotification:remoteNotif];
        }
    }
    
    //User login
    [[EWUserManagement sharedInstance] login];
    
    //last step
    [self.window makeKeyAndVisible];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
    NSLog(@"Canceled HUD");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"Entered background with active time left: %f", application.backgroundTimeRemaining);
    
    //detect multithreading
    BOOL result = NO;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]){
        result = [[UIDevice currentDevice] isMultitaskingSupported];
    }if (!result) {
        return;
    }

#ifdef BACKGROUND_TEST
    
//    //开启一个后台任务
//    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
//        
//        NSLog(@"The first BG task will end (%ld)", count);
//    }];
//    
//    // keep active
//    if ([myTimer isValid]) [myTimer invalidate];
//    myTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(keepAlive:) userInfo:nil repeats:YES];
//    NSLog(@"Scheduled background task when app enters background with time left: %f", application.backgroundTimeRemaining);
#endif
    
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    //[[UIApplication sharedApplication] clearKeepAliveTimeout];
    
    
    if (backgroundTaskIdentifier != UIBackgroundTaskInvalid){
        //end background task
        [application endBackgroundTask:backgroundTaskIdentifier];
        //stop timer
        if ([myTimer isValid]) [myTimer invalidate];
    }
    
    NSLog(@"Entered foreground and cleaned bgID and timer");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSession.activeSession handleDidBecomeActive];
    
    //audio session
    [[AVManager sharedManager] registerAudioSession];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    //[FBSession.activeSession close];
    NSLog(@"App is about to terminate");
//    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
//        NSLog(@"%ld", count++);
//    }];
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
    
    return [FBSession.activeSession handleOpenURL:url];
}



#pragma mark - Background fetch method (this is called periodocially
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"======== Launched in background due to background fetch event ==========");
    for (EWTaskItem *task in currentUser.tasks) {
        
        //refresh
        [context refreshObject:task mergeChanges:YES];
        
        //check
        if ([lastChecked isEarlierThan:task.lastmoddate]) {
            NSLog(@"Find task on %@ has possible updates", task.time.weekday);
            [[AVManager sharedManager] playSoundFromFile:@"tock.caf"];
            
            //download
            [[EWDownloadManager sharedInstance] downloadTask:task];
        }
    }
    
    //update checked time
    lastChecked = [NSDate date];
    
    completionHandler(UIBackgroundFetchResultNewData);
}

//Keep alive
- (void) keepAlive:(NSTimer *)paramSender{
    
    UIApplication *application = [UIApplication sharedApplication];
    
    //结束旧的后台任务
    [application endBackgroundTask:backgroundTaskIdentifier];
    
    //开启一个新的后台
    NSInteger ct = count;
    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"BG task will end (%ld)", (long)ct);
    }];
    
    
    NSLog(@"Background task is still working with time left %f (%ld)",[UIApplication sharedApplication].backgroundTimeRemaining , count++);

}

- (BOOL) isMultitaskingSupported {
    
    BOOL result = NO;
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]){
        result = [[UIDevice currentDevice] isMultitaskingSupported];
    }
    return result;
}

#pragma mark - Push Notification registration
//Presist the device token
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [[token componentsSeparatedByString:@" "] componentsJoinedByString:@""];//become a string
    
    // Persist token
    /*
     userDefaults{
        kPushTokenDicKey: {
            username: token,
            ...
        }
        kAWSEndPointDicKey: {
            username: ARN,
            ...
        }
        ...
     }
     */
    NSString *username = currentUser.username;
    if(!username) [NSException raise:@"User didn't log in" format:@"Check your login sequense"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *tokenByUserDic = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:kPushTokenDicKey]];
    //determin if user exsits
    NSString *token_old = [tokenByUserDic objectForKey:username];
    if (!token_old || ![token_old isEqualToString:token]) {
        //new token
        [tokenByUserDic setObject:token forKey:username];
        //save
        [defaults setObject:tokenByUserDic forKey:kPushTokenDicKey];
        [defaults synchronize];
    }
    
    //Register Push on StackMob
    [[EWUserManagement sharedInstance] registerPushNotification];
    NSLog(@"Registered device token: %@", token);
    
    
    //AWS
    NSMutableDictionary *arnByUserDic = [[defaults objectForKey:kAWSEndPointDicKey] mutableCopy];
    //NSMutableDictionary *topicByUserDic = [[defaults objectForKey:kAWSTopicDicKey] mutableCopy];
    NSString *endPoint = arnByUserDic[username];
    //NSString *topicArn = topicByUserDic[username];
    if (!endPoint/* || !topicArn*/) {
        //create endPint (user)
        SNSCreatePlatformEndpointRequest *request = [[SNSCreatePlatformEndpointRequest alloc] init];
        request.token = token;
        request.customUserData = currentUser.username;
        request.platformApplicationArn = AWS_SNS_APP_ARN;
        SNSCreatePlatformEndpointResponse *response;
        NSString *endPointARN;
        @try {
            response = [snsClient createPlatformEndpoint:request];
        }
        @catch (NSException *exception) {
            
            if ([exception isKindOfClass:[SNSInvalidParameterException class]]) {
                //SNSInvalidParameterException *aws_e = (SNSInvalidParameterException *)exception;
                NSString *des = exception.description;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"arn:aws.*?\\s"
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:NULL];
                NSRange result = [regex rangeOfFirstMatchInString:des options:0 range:NSMakeRange(0, [des length])];
                NSString *endPointARN = [des substringWithRange:result];
                //register the endpoint arn to user
                if (result.length > 0) {
                    endPointARN = [endPointARN stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSLog(@"Intercepted endpointArn: %@", endPointARN);
                    currentUser.aws_id = endPointARN;
                }else{
                    @throw exception;
                }
            }else{
                NSLog(@"%@", exception);
                return;
            }
        }

        if (response) {
            endPointARN = response.endpointArn;
            currentUser.aws_id = endPointARN;
            NSLog(@"Created endpoint on AWS: %@", endPointARN);
        }
        
        //save
        [arnByUserDic setObject:endPointARN forKey:username];
        
        //sync
        [context saveOnSuccess:^{
            //
        } onFailure:^(NSError *error) {
            //
        }];
    }
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    //[NSException raise:@"Failed to regiester push token with apple" format:@"Reason: %@", err.description];
    NSLog(@"Failed to regiester push token with apple. Error: %@", err.description);
    NSString *str = [NSString stringWithFormat:@"Unable to regiester Push Notifications. Reason: %@", err.localizedDescription];
    EWAlert(str);
}

//entrance of Local Notification
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    NSLog(@"Received local notification: %@", notification);
    if ([application applicationState] == UIApplicationStateActive) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Woke Alarm"
                              message:@"It's time to get up!"
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    } else {
        NSLog(@"Entered by local notification");
        /*
        if (self.musicList.count > 0) {
            [self playDownloadedMusic:[self.musicList objectAtIndex:self.musicList.count-1]];
        }*/
        NSString *taskID = [notification.userInfo objectForKey:kLocalNotificationUserInfoKey];
        NSLog(@"The task is %@", taskID);
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
        controller.task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        [self.window.rootViewController presentViewController:navigationController animated:YES completion:^(void){}];
    }
}
/*
//normal handler for remote notification
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    if ([application applicationState] == UIApplicationStateActive) {
        NSLog(@"%s: Push received when app is running: %@", __func__, userInfo);
    }else{
        NSLog(@"%s: Push received when app is in %d : %@", __func__, application.applicationState, userInfo);
    }
}*/

//Receive remote notification in background or in foreground
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    
    if ([application applicationState] == UIApplicationStateActive) {
        NSLog(@"Push Notification received when app is running: %@", userInfo);
    }else{
        NSLog(@"Push Notification received when app is in background(%d): %@", application.applicationState, userInfo);
    }
    
    //handle push
    [EWServer handlePushNotification:userInfo];
    
    //return handler
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"@@@@@@@ Push conpletion handle returned. @@@@@@@@@");
        completionHandler(UIBackgroundFetchResultNewData);
    });
}



//Store the completion handler. The completion handler is invoked by the view controller's checkForAllDownloadsHavingCompleted method (if all the download tasks have been completed).
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    NSLog(@"%s", __func__);
    //store the completionHandler
    EWDownloadManager *manager = [EWDownloadManager sharedInstance];
	manager.backgroundSessionCompletionHandler = completionHandler;
}

@end

/*
@implementation EWAppDelegate (DownloadMgr)

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFailedDownload:(NSError *)error {
    
}

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFinishedDownload:(NSData *)result {
    NSLog(@"Dowload Success %@, %@ ",mgr.description, mgr.urlString);
    
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
