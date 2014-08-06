//
//  EWSleepManager.m
//  SleepManager
//  Manage the backgrounding. Currently only support backgrounding during sleep.
//  Will support sleep music and statistics later
//
//  Created by Lee on 8/6/14.
//  Copyright (c) 2014 Woke. All rights reserved.
//

#import "EWBackgroundingManager.h"
#import "EWTaskItem.h"
#import "EWWakeUpManager.h"
#import "AVManager.h"


@interface EWBackgroundingManager(){
    NSTimer *backgroundingtimer;
    UIBackgroundTaskIdentifier backgroundTaskIdentifier;
    UILocalNotification *backgroundingFailNotification;
}

@end

@implementation EWBackgroundingManager

+ (EWBackgroundingManager *)sharedInstance{
    static EWBackgroundingManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWBackgroundingManager alloc] init];
    });
    
    return manager;
}

- (id)init{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didbecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

+ (BOOL)supportBackground{
    BOOL supported;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]){
        supported = [[UIDevice currentDevice] isMultitaskingSupported];
    }else {
        EWAlert(@"Your device doesn't support background task. Alarm will not fire. Please change your settings.");
        supported = NO;
    }
    return supported;
}

- (void)enterBackground{
    if (self.sleeping) {
        [self startSleep];
    }
}

- (void)enterForeground{
    if (!self.sleeping) {
        [self endSleep];
    }
}


- (void)willResignActive{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    //temporarily end backgrounding
    
    //Timer will fail automatically
    //backgroundTask will stop automatically
    //notification needs to be cancelled (or delayed)
    
    if (backgroundingFailNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:backgroundingFailNotification];
    }
}

- (void)didbecomeActive{
    // This method is called to let your app know that it moved from the inactive to active state. This can occur because your app was launched by the user or the system.
    //resume backgrounding
    UILocalNotification *notif = [[UILocalNotification alloc] init];
    notif.alertBody = @"Woke become active!";
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    
    if (self.sleeping) {
        [self startSleep];
    }
}

- (void)startSleep{
    self.sleeping = YES;
    [self backgroundKeepAlive:nil];
    NSLog(@"Start Sleep");
}

- (void)endSleep{
    NSLog(@"End Sleep");
    self.sleeping = NO;
    
    UIApplication *application = [UIApplication sharedApplication];
    
    if (backgroundTaskIdentifier != UIBackgroundTaskInvalid){
        //end background task
        [application endBackgroundTask:backgroundTaskIdentifier];
    }
    //stop timer
    if ([backgroundingtimer isValid]){
        [backgroundingtimer invalidate];
    }
    
    //stop backgrounding fail notif
    if (backgroundingFailNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:backgroundingFailNotification];
    }
}


- (void)backgroundKeepAlive:(NSTimer *)timer{
    UIApplication *application = [UIApplication sharedApplication];
    NSMutableDictionary *userInfo;
    if (timer) {
        NSInteger count;
        NSDate *start = timer.userInfo[@"start_date"];
        count = [(NSNumber *)timer.userInfo[@"count"] integerValue];
        NSLog(@"Backgrounding started at %@ is checking the %ld times", start.date2detailDateString, (long)count);
        count++;
        timer.userInfo[@"count"] = @(count);
        userInfo = timer.userInfo;
    }else{
        //first time
        userInfo = [NSMutableDictionary new];
        userInfo[@"start_date"] = [NSDate date];
        userInfo[@"count"] = @0;
    }
    
    //schedule timer
    if ([backgroundingtimer isValid]) [backgroundingtimer invalidate];
    NSInteger randomInterval = kAlarmTimerCheckInterval + arc4random_uniform(60);
    backgroundingtimer = [NSTimer scheduledTimerWithTimeInterval:randomInterval target:self selector:@selector(backgroundTaskKeepAlive:) userInfo:userInfo repeats:NO];
    
    //start silent sound
    [[AVManager sharedManager] playSilentSound];
    
    //end old background task
    [application endBackgroundTask:backgroundTaskIdentifier];
    //begin a new background task
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        //[self backgroundTaskKeepAlive:nil];
        NSLog(@"The backgound task ended!");
    }];
    
    //check time left
    if (backgroundingFailNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:backgroundingFailNotification];
    }
    double timeLeft = application.backgroundTimeRemaining;
    NSLog(@"Background time left: %.1f", timeLeft>999?999:timeLeft);
    //alert user
    backgroundingFailNotification= [[UILocalNotification alloc] init];
    backgroundingFailNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:200];
    backgroundingFailNotification.alertBody = @"Woke stopped running in background. Tap here to reactivate me.";
    backgroundingFailNotification.alertAction = @"Activate Woke";
    backgroundingFailNotification.userInfo = @{kLocalNotificationTypeKey: kLocalNotificationTypeReactivate};
    backgroundingFailNotification.soundName = @"new.caf";
    [[UIApplication sharedApplication] scheduleLocalNotification:backgroundingFailNotification];
    
    //alarm timer check
    [EWWakeUpManager alarmTimerCheck];
}


@end
