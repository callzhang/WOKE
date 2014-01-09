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
#import "EWUserManagement.h"

//tools
#import "TestFlight.h"
#import "EWDownloadMgr.h"
#import "AVManager.h"

//global view for HUD
UIView *rootview;

//Private
@interface EWAppDelegate(){
    EWTaskItem *taskInAction;
}

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic) UIBackgroundTaskIdentifier oldBackgroundTaskIdentifier;

@property (nonatomic, strong) NSTimer *myTimer;
@property (nonatomic) long count;

@property (nonatomic, strong) NSMutableArray *musicList;

@end

@interface EWAppDelegate (DownloadMgr)<EWDownloadMgrDelegate>
@end

@implementation EWAppDelegate
@synthesize backgroundTaskIdentifier;
@synthesize oldBackgroundTaskIdentifier;
@synthesize myTimer;
@synthesize count;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //test flight
    [TestFlight takeOff:@"e1ffe70a-26bf-4db0-91c8-eb2d1d362cb3"];
    
    //background fetch
    [application setMinimumBackgroundFetchInterval:kBackgroundFetchInterval];
    //background download
    count = 0;
    self.musicList = [NSMutableArray array];
    
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
    rootview = self.window.rootViewController.view;
    
    //local notification entry
    if (launchOptions) {
        NSLog(@"LaunchOption: %@", launchOptions);
        UILocalNotification *localNotif =
        [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        //This block only works when app starts at the first time
        if (localNotif) {
            NSString *taskID = [localNotif.userInfo objectForKey:kLocalNotificationUserInfoKey];
            
            /*
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Local notification"
             message:taskID
             delegate:nil
             cancelButtonTitle:@"OK"
             otherButtonTitles:nil];
             [alert show];*/
            
            NSLog(@"Entered app with local notification when app is not alive");
            NSLog(@"Get task id: %@", taskID);
            EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
            controller.task  = [[EWTaskStore sharedInstance] getTaskByID:taskID];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            
            [self.window.rootViewController presentViewController:navigationController animated:YES completion:NULL];
        }
    }
    
    //User login
    [MBProgressHUD showHUDAddedTo:rootview animated:YES];
    EWUserManagement *userMger = [EWUserManagement sharedInstance];
    [userMger login];
    [MBProgressHUD hideAllHUDsForView:rootview animated:YES];
    
    //last step
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if (![self isMultitaskingSupported]){
        return;
    }
    
#ifdef BACKGROUND_TEST
    [self performSelectorInBackground:@selector(backgroundDownload) withObject:nil];
#endif
    //开启一个后台任务
    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
//        [self backgroundDownload];
        
    }];
    oldBackgroundTaskIdentifier = backgroundTaskIdentifier;
    if ([self.myTimer isValid]) {
        [self.myTimer invalidate];
    }
    self.myTimer = [NSTimer scheduledTimerWithTimeInterval:serverUpdateInterval target:self selector:@selector(timerMethod:) userInfo:nil repeats:YES];
    NSLog(@"Scheduled background task");
//    self.myTimer = nil;

    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
//    [[UIApplication sharedApplication] clearKeepAliveTimeout];
    
    if (backgroundTaskIdentifier != UIBackgroundTaskInvalid){
        [application endBackgroundTask:backgroundTaskIdentifier];
        if ([self.myTimer isValid]) {
            [self.myTimer invalidate];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [FBSession.activeSession close];
}

/*
#pragma mark - Weibo
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [WeiboSDK handleOpenURL:url delegate:self];
}

#pragma mark - Facebook
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    return [FBSession.activeSession handleOpenURL:url];
}

*/

- (BOOL) isMultitaskingSupported {
    
    BOOL result = NO;
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]){
            result = [[UIDevice currentDevice] isMultitaskingSupported];
    }
    return result;
}

#pragma mark - Background download
- (void) timerMethod:(NSTimer *)paramSender{
    count++;
    NSLog(@"Background downloading is still working");
    UIApplication *application = [UIApplication sharedApplication];
    
    //开启一个新的后台
    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        
        // Download
//            [self backgroundDownload];
    }];
    
    //结束旧的后台任务
    [application endBackgroundTask:backgroundTaskIdentifier];
    oldBackgroundTaskIdentifier = backgroundTaskIdentifier;
    
#ifdef BACKGROUND_TEST

    NSLog(@"%ld",count);
#endif
}

- (void)backgroundDownload {
    
    EWDownloadMgr *mgr = [[EWDownloadMgr alloc] init];
    mgr.urlString = @"http://med.a5mp3.com/ttpod/11612.mp3";
    mgr.delegate = self;
    
    NSString *fileName = nil;
    if (mgr.description && mgr.description.length > 0) {
        fileName = [NSString stringWithFormat:@"%@.mp3",mgr.description];
    }
    else {
        //get file name
        NSArray *array = [mgr.urlString componentsSeparatedByString:@"/"];
        if (array && array.count > 0) {
            fileName = [array objectAtIndex:array.count-1];
        }
    }

    if (fileName) {
        NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@", fileName]];
        
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        if (fileExists) {
            
            // test
            [self.musicList addObject:filePath];
            
            // 播放 test
            [self playDownloadedMusic:filePath];
            return;
        }
    }
    
//    [mgr startDownload];
    
    NSData *data = [mgr syncDownloadByGet];
    
    [self handleDownlownedData:data fromManager:mgr];
}

- (void)handleDownlownedData:(NSData *)data fromManager:(EWDownloadMgr *)mgr {
    if (!data) {
        return;
    }
    
    NSString *fileName = nil;
    if (mgr.description && mgr.description.length > 0) {
        fileName = [NSString stringWithFormat:@"%@.mp3",mgr.description];
    }
    else {
        NSArray *array = [mgr.urlString componentsSeparatedByString:@"/"];
        if (array && array.count > 0) {
            fileName = [array objectAtIndex:array.count-1];
        }
        else {
            NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
            fileName = [NSString stringWithFormat:@"%f.mp3",timeInterval];
        }
    }
    
    NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@", fileName]];
    [data writeToFile:filePath atomically:YES];
    
    NSLog(@"write to local file: %@", filePath);
    [self.musicList addObject:filePath];
    
    // 播放 test
    [self playDownloadedMusic:filePath];
}

- (void)playDownloadedMusic:(NSString *)path {
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL: [NSURL fileURLWithPath:path] error: nil];
    [player prepareToPlay];
    
    //    [player play];
    
    [player performSelectorOnMainThread:@selector(play) withObject:nil waitUntilDone:NO];
}

#pragma mark - Push Notification registration
//Presist the device token
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [[token componentsSeparatedByString:@" "] componentsJoinedByString:@""];//become a string
    
    // Persist token
    NSString *username = currentUser.username;
    if(!username) username = kPushTokenUserAvatarKey;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *tokenByUserArray = (NSMutableArray *)[defaults objectForKey:kPushTokenKey];
    if (!tokenByUserArray) tokenByUserArray = [[NSMutableArray alloc] init];
    for (NSDictionary *tokenByUserDict in tokenByUserArray) {
        if ([tokenByUserDict[kPushTokenUserKey] isEqualToString:username]) {
            //exsiting user, check if token is the same
            if ([tokenByUserDict[kPushTokenByUserKey] isEqualToString:token]) {
                //same token, userLoggedIn event has already triggered the push registeration on StackMob
                return;
            }
        }else{
            NSLog(@"User has not registered token on this device");
        }
    }
    //write to plist
    NSDictionary *tokenByUser = @{kPushTokenUserKey: username, kPushTokenByUserKey: token};
    [tokenByUserArray addObject:tokenByUser];
    [defaults setObject:tokenByUserArray forKey:kPushTokenKey];
    [defaults synchronize];
    
    //Register Push on StackMob
    [[EWDataStore sharedInstance] registerPushNotification];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    //[NSException raise:@"Failed to regiester push token with apple" format:@"Reason: %@", err.description];
    NSLog(@"Failed to regiester push token with apple. Error: %@", err.description);
}

//entrance of Local Notification
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    NSLog(@"Received local notification: %@ when app is in background", notification);
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
        
        
        if (self.musicList.count > 0) {
            [self playDownloadedMusic:[self.musicList objectAtIndex:self.musicList.count-1]];
        }
        NSString *taskID = [notification.userInfo objectForKey:kLocalNotificationUserInfoKey];
        NSLog(@"The task is %@", taskID);
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
        controller.task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        [self.window.rootViewController presentViewController:navigationController animated:YES completion:^(void){}];
    }
}

//Receive remote notification
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    NSLog(@"Push Notification received: %@ when app in in background", userInfo);
    //if ([application applicationState] == UIApplicationStateActive) {
    NSString *message = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
    NSString *title = @"New Voice Tone";
    NSString *taskID = userInfo[kLocalNotificationUserInfoKey];
    NSLog(@"The task is %@", taskID);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        taskInAction = [[EWTaskStore sharedInstance] getTaskByID:taskID];
        if (taskInAction) {
            //notification
            [[NSNotificationCenter defaultCenter] postNotificationName:kTaskChangedNotification object:self userInfo:@{@"task": taskInAction}];
            //main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                                    message:[message stringByAppendingString:@" (The show option will be removed in release)"]
                                                                   delegate:self
                                                          cancelButtonTitle:@"Close"
                                                          otherButtonTitles:@"Show", nil];
                [alertView show];
            });
        }else{
            //Other message
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
                [alertView show];
            });
        }
    });
}

#pragma mark - Alert Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if ([alertView.title isEqualToString:@"New Voice Tone"]) {
        if (buttonIndex == 1) {
            //show
            if (taskInAction) {
                //got taskInAction
                EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
                controller.task = taskInAction;
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
                [self.window.rootViewController presentViewController:navigationController animated:YES completion:NULL];
            }
            taskInAction = nil;
        }
    }else if ([alertView.title isEqualToString:@"Woke Alarm"]) {
        if (buttonIndex == 1) {
            //show
            if (taskInAction) {
                //got taskInAction
                EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
                controller.task = taskInAction;
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
                [self.window.rootViewController presentViewController:navigationController animated:YES completion:NULL];
            }
            taskInAction = nil;
        }
    }
    
}



@end

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
