//
//  EWWakeUpManager.m
//  EarlyWorm
//
//  Created by Lei on 3/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWWakeUpManager.h"
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWPersonStore.h"
#import "AVManager.h"
#import "EWAppDelegate.h"
#import "EWMediaItem.h"
#import "EWMediaStore.h"
#import "EWDownloadManager.h"
#import "UIViewController+Blur.h"
#import "EWDownloadManager.h"
#import "EWNotificationManager.h"
#import "EWPerson.h"
#import "EWUserManagement.h"
#import "EWServer.h"
#import "ATConnect.h"


//UI
#import "EWWakeUpViewController.h"
#import "EWSleepViewController.h"


@interface EWWakeUpManager()
//retain the controller so that it won't deallocate when needed
@property (nonatomic, retain) EWWakeUpViewController *controller;
@end


@implementation EWWakeUpManager
@synthesize isWakingUp = _isWakingUp;

+ (EWWakeUpManager *)sharedInstance{
    static EWWakeUpManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWWakeUpManager alloc] init];
        manager.isWakingUp = NO;
    });
    return manager;
}

- (BOOL)isWakingUp{
    @synchronized(self){
        return _isWakingUp;
    }
}

- (void)setIsWakingUp:(BOOL)isWakingUp{
    @synchronized(self){
        _isWakingUp = isWakingUp;
    }
}


#pragma mark - Handle push notification
+ (void)handlePushNotification:(NSDictionary *)notification{
    NSString *type = notification[kPushTypeKey];
    NSString *mediaID = notification[kPushMediaKey];
    NSString *taskID = notification[kPushTaskKey];
    
//    if (!mediaID) {
//        NSLog(@"Push doesn't have media ID, abort!");
//        return;
//    }

    
    EWMediaItem *media = [[EWMediaStore sharedInstance] getMediaByID:mediaID];
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextValidTaskForPerson:me];
    
    
    if ([type isEqualToString:kPushTypeBuzzKey]) {
        // ============== Buzz ===============
        NSParameterAssert(mediaID);
        NSLog(@"Received buzz from %@", media.author.name);
        
        //sound
        NSString *buzzSoundName = media.buzzKey?:me.preference[@"buzzSound"];
        NSDictionary *sounds = buzzSounds;
        NSString *buzzSound = sounds[buzzSoundName];
        
#ifdef DEBUG
        EWPerson *sender = media.author;
        //alert
        [[[UIAlertView alloc] initWithTitle:@"Buzz 来啦" message:[NSString stringWithFormat:@"Got a buzz from %@. This message will not display in release.", sender.name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        
#endif
        
        if (task.completed || [[NSDate date] timeIntervalSinceDate:task.time] > kMaxWakeTime) {
            
            //============== the buzz window has passed ==============
            NSLog(@"@@@ Buzz window has passed, save it to next day");
            
            //do nothing
            
            return;
            
        }else if ([[NSDate date] isEarlierThan:task.time]){
            
            //============== buzz earlier than alarm, schedule local notif ==============
            
            UILocalNotification *notif = [[UILocalNotification alloc] init];
            //time: a random time after
            NSDate *fireTime = [task.time timeByAddingSeconds:(150 + arc4random_uniform(5)*30)];
            notif.fireDate = fireTime;
            //sound
            
            notif.soundName = buzzSound;
            //message
            notif.alertBody = [NSString stringWithFormat:@"Buzz from %@", media.author.name];
            notif.userInfo = @{kPushTaskKey: task.objectId, kPushMediaKey: mediaID, kLocalTaskKey: task.objectID.URIRepresentation.absoluteString};
            //schedule
            [[UIApplication sharedApplication] scheduleLocalNotification:notif];
            
            NSLog(@"Scheduled local notif on %@", [fireTime date2String]);
            
        }else{
            
            //============== struggle ==============
            
            [EWWakeUpManager presentWakeUpViewWithTask:task];
            
            //broadcast event so that wakeup VC can play it
            //[[NSNotificationCenter defaultCenter] postNotificationName:kNewBuzzNotification object:self userInfo:@{kPushTaskKey: task.objectId}];
            
            [task addMediasObject:media];
            [EWSync save];
        }
        

        
    }else if ([type isEqualToString:kPushTypeMediaKey]){
        // ============== Media ================
        NSParameterAssert(mediaID);
        NSLog(@"Received voice type push");
        

        //download media
        NSLog(@"Downloading media: %@", media.objectId);
        
        //[[EWDownloadManager sharedInstance] downloadMedia:media];//will play after downloaded in test mode+
        
        //determin action based on task timing
        if ([[NSDate date] isEarlierThan:task.time]) {
            
            //============== pre alarm -> download ==============
            
        }else if (!task.completed && [[NSDate date] timeIntervalSinceDate:task.time] < kMaxWakeTime){
            
            //============== struggle ==============
            
            [EWWakeUpManager presentWakeUpViewWithTask:task];
            
            //broadcast so wakeupVC can react to it
            //[[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:self userInfo:@{kPushMediaKey: mediaID, kPushTaskKey: task.objectId}];
            
            //use KVO
            [task addMediasObject:media];
            [EWSync save];
            
        }else{
            
            //Woke state -> assign media to next task, download
            if (![me.mediaAssets containsObject:media]) {
                [me addMediaAssetsObject:media];
                
                NSSet *tasks = [media.tasks filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"owner = %@", me]];
                for (EWTaskItem *task in tasks) {
                    
                    //need to move to media pool
                    [media removeTasksObject:task];
                    [EWSync save];
                }
            }
            
        }
        
#ifdef DEBUG
        [[[UIAlertView alloc] initWithTitle:@"Voice来啦" message:@"收到一条神秘的语音."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#endif
        
        
    }else if([type isEqualToString:kPushTypeTimerKey]){
        // ============== Timer ================
        //TODO: test if the push is correct
        //first find the task ID
        //then test if the tesk time is matched
        //also the task should not be completed
        //also make sure it's not too early or too late
        if (![taskID isEqualToString:task.objectId]) {
            NSLog(@"Task from push is not the next task");
            return;
        }
        //...
        
        [EWWakeUpManager handleAlarmTimerEvent:notification];
        
        
    }else if([type isEqualToString:@"test"]){
        
        // ============== Test ================
        
        NSLog(@"Received === test === type push");
        [UIApplication sharedApplication].applicationIconBadgeNumber = 9;
        
        [[AVManager sharedManager] playSystemSound:[NSURL URLWithString:media.audioKey]];
        
    }else{
        // Other push type not supported
        NSString *str = [NSString stringWithFormat:@"Unknown push type received: %@", notification];
        NSLog(@"Received unknown type of push msg");
        EWAlert(str);
    }
}

+ (void)handleAlarmTimerEvent:(NSDictionary *)info{
    NSParameterAssert([NSThread isMainThread]);
    if ([EWWakeUpManager sharedInstance].isWakingUp) {
        NSLog(@"WakeUpManager is already handling alarm timer, skip");
        return;
    }
    
    BOOL isLaunchedFromLocalNotification = NO;
    BOOL isLanchedFromRemoteNotification = NO;
    
    //get target task
    EWTaskItem *task;
    if (info) {
        NSString *taskID = info[kPushTaskKey];
        NSString *taskLocalID = info[kLocalTaskKey];
        NSParameterAssert(taskID || taskLocalID);
        if (taskID) {
            task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
        }else if (taskLocalID){
            isLaunchedFromLocalNotification = YES;
            task = (EWTaskItem *)[EWTaskItem findFirstByAttribute:kParseObjectID withValue:taskID];
        }
        
    }else{
        task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:me];
    }
    
    NSLog(@"Start handle timer event");
    if (!task) {
        NSLog(@"*** %s No task found for next task, abord", __func__);
        return;
    }
    
    if (task.state == NO) {
        NSLog(@"Task is OFF, skip today's alarm");
        return;
    }
    
    if (task.completed) {
        // task completed
        NSLog(@"Task has completed at %@, skip.", task.completed.date2String);
        return;
    }
    if (task.time.timeElapsed > kMaxWakeTime) {
        NSLog(@"Task(%@) from notification has passed the wake up window. Handle is with checkPastTasks.", task.objectId);
        [[EWTaskStore sharedInstance] checkPastTasksInBackgroundWithCompletion:NULL];
        
        return;
    }
    
    //update media
    [[EWMediaStore sharedInstance] checkMediaAssets];
    NSArray *medias = me.mediaAssets.allObjects;
    
    //fill media from mediaAssets, if no media for task, create a pseudo media
    NSInteger nVoice = [[EWTaskStore sharedInstance] numberOfVoiceInTask:task];
    NSInteger nVoiceNeeded = kMaxVoicePerTask - nVoice;
    
    for (EWMediaItem *media in medias) {
        if (!media.targetDate || [media.targetDate timeIntervalSinceNow]<0) {
            
            //find media to add
            [task addMediasObject: media];
            //remove media from mediaAssets, need to remove relation doesn't have inverse relation. This is to make sure the sender doesn't need to modify other person
            [me removeMediaAssetsObject:media];
            [media removeReceiversObject:me];
            
            //stop if enough
            if ([media.type isEqualToString: kMediaTypeVoice]) {
                //reduce the counter
                nVoiceNeeded--;
                if (nVoiceNeeded <= 0) {
                    break;
                }
            }
        }
    }
    
    //add Woke media is needed
    nVoice = [[EWTaskStore sharedInstance] numberOfVoiceInTask:task];
    if (nVoice == 0) {
        //need to create some voice
        EWMediaItem *media = [[EWMediaStore sharedInstance] getWokeVoice];
        [task addMediasObject:media];

    }
    
    //save
    [EWSync save];
    
    //cancel local alarm
    [[EWTaskStore sharedInstance] cancelNotificationForTask:task];
    
    //state change
    [EWWakeUpManager sharedInstance].isWakingUp = YES;
    
    if (isLaunchedFromLocalNotification) {
        
        NSLog(@"Entered from local notification, start wakeup view now");
        [EWWakeUpManager presentWakeUpViewWithTask:task];
        
    }else if (isLanchedFromRemoteNotification){
        
        NSLog(@"Entered from remote notification, start wakeup view now");
        [EWWakeUpManager presentWakeUpViewWithTask:task];
        
    }else{
        //fire an alarm
        NSLog(@"=============> Firing Alarm timer notification <===============");
        UILocalNotification *alarm = [[UILocalNotification alloc] init];
        alarm.alertBody = [NSString stringWithFormat:@"It's time to wake up (%@)", [task.time date2String]];
        alarm.alertAction = @"Wake up!";
        //alarm.soundName = me.preference[@"DefaultTone"];
        alarm.userInfo = @{kLocalTaskKey: task.objectID.URIRepresentation.absoluteString,
                           kLocalNotificationTypeKey: kLocalNotificationTypeAlarmTimer};
        [[UIApplication sharedApplication] scheduleLocalNotification:alarm];
        
        //play sound
        [[AVManager sharedManager] playSoundFromFile:me.preference[@"DefaultTone"]];
        
        //play sounds after 30s - time for alarm
        double d = 30;
#ifdef DEBUG
        d = 5;
#endif
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(d * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //present wakeupVC and paly when displayed
            [[AVManager sharedManager] volumeFadeWithCompletion:^{
                [EWWakeUpManager presentWakeUpViewWithTask:task];
            }];
            
        });
    }
}

#pragma mark - Utility
+ (BOOL)isRootPresentingWakeUpView{
    //determin if WakeUpViewController is presenting
    UIViewController *vc = rootViewController.presentedViewController;
    if ([vc isKindOfClass:[EWWakeUpViewController class]]) {
        return YES;
    }
    
    return NO;
}

+ (void)presentWakeUpView{
    //get absolute next task
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:me];
    //present
    [EWWakeUpManager presentWakeUpViewWithTask:task];
}

+ (void)presentWakeUpViewWithTask:(EWTaskItem *)task{
    if (![EWWakeUpManager isRootPresentingWakeUpView]) {
        //init wake up view controller
        __block EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] initWithTask:task];
        //save to manager
        [EWWakeUpManager sharedInstance].controller = controller;
        
        //dispatch to main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Presenting wakeUpView");
            if (rootViewController.presentedViewController) {
                [rootViewController dismissBlurViewControllerWithCompletionHandler:^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [rootViewController presentViewControllerWithBlurBackground:controller];
                    });
                }];
            }else{
                [rootViewController presentViewControllerWithBlurBackground:controller];
            }
            
            //start playing regardless
            [controller startPlayCells];
        });
        
        
        
    }else{
        //save controller if not
        id controller = rootViewController.presentedViewController;
        if ([controller isKindOfClass:[EWWakeUpViewController class]]) {
            [EWWakeUpManager sharedInstance].controller = controller;
        } else {
            NSLog(@"*** Something wrong with detecting presented VC! Please cheeck!");
            [EWWakeUpManager presentWakeUpView];
        }
    }
}

//indicate that the user has woke
+ (void)woke:(EWTaskItem *)task{
    [EWWakeUpManager sharedInstance].controller = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kWokeNotification object:nil];
    [EWWakeUpManager sharedInstance].isWakingUp = NO;
    
    //handle wakeup signel
    [[ATConnect sharedConnection] engage:kWakeupSuccess fromViewController:rootViewController];
    
    //set wakeup time
    if ([task.time isEarlierThan:[NSDate date]] && !task.completed) {
        if (task.time.timeElapsed > kMaxWakeTime) {
            task.completed = [task.time dateByAddingTimeInterval:kMaxWakeTime];
        }else{
            task.completed = [NSDate date];
        }
        [[EWTaskStore sharedInstance] scheduleTasksInBackgroundWithCompletion:NULL];
    }
    
    
    //TODO: something to do in the future
    //notify friends and challengers
    //update history stats
}


#pragma mark - CHECK TIMER
+ (void) alarmTimerCheck{
    //check time
    if (!me) return;
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextValidTaskForPerson:me];
    if (task.state == NO) return;
    
    //alarm time up
    NSTimeInterval timeLeft = [task.time timeIntervalSinceNow];
    if ([EWWakeUpManager sharedInstance].forceAlarm) {
        timeLeft = 10;
    }
    NSLog(@"===========================>> Check Alarm Timer (%ld min left) <<=============================", (NSInteger)timeLeft/60);
    static BOOL timerInitiated = NO;
    if (timeLeft < kServerUpdateInterval && timeLeft > 0 && !timerInitiated) {
        NSLog(@"%s: About to init alart timer in %fs", __func__, timeLeft);
        timerInitiated = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeLeft - 1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [EWWakeUpManager handleAlarmTimerEvent:nil];
        });
    }
    
}

+ (void)sleepTimerCheck{
    //check time
    if (!me) return;
    EWTaskItem *task = [[EWTaskStore sharedInstance] nextValidTaskForPerson:me];
    if (task.state == NO) return;
    
    //alarm time up
    NSNumber *sleepDuration = me.preference[kSleepDuration];
    NSInteger durationInSeconds = sleepDuration.integerValue * 3600;
    NSTimeInterval timeLeft = [task.time timeIntervalSinceNow] - durationInSeconds;
    NSLog(@"===========================>> Check Sleep Timer (%ld min left) <<=============================", (NSInteger)timeLeft/60);
    static BOOL timerInitiated = NO;
    if (timeLeft < kServerUpdateInterval && timeLeft > 0 && !timerInitiated) {
        NSLog(@"%s: About to init alart timer in %fs", __func__, timeLeft);
        timerInitiated = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeLeft - 1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [EWWakeUpManager handleSleepTimerEvent];
        });
    }
}

+ (void)handleSleepTimerEvent{
    
    if (me) {
        //logged in enter sleep mode
        EWSleepViewController *controller = [[EWSleepViewController alloc] initWithNibName:nil bundle:nil];
        [rootViewController presentWithBlur:controller withCompletion:NULL];
    }else{
        [[NSNotificationCenter defaultCenter] addObserverForName:kPersonLoggedIn object:nil queue:nil usingBlock:^(NSNotification *note) {
            EWSleepViewController *controller = [[EWSleepViewController alloc] initWithNibName:nil bundle:nil];
            [rootViewController presentWithBlur:controller withCompletion:NULL];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kPersonLoggedIn object:nil];
        }];
    }
}

@end
