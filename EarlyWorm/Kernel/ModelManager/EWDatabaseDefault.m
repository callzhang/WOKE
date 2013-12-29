//
//  EWDatabaseDefault.m
//  EarlyWorm
//
//  Created by Lei on 10/18/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWDatabaseDefault.h"
#import "EWDefines.h"

#import "EWPersonStore.h"
#import "EWPerson.h"

#import "EWMediaStore.h"
#import "EWMediaItem.h"

#import "EWGroup.h"
#import "EWGroupStore.h"

#import "EWAlarmItem.h"
#import "EWAlarmManager.h"

#import "EWTaskItem.h"
#import "EWTaskStore.h"

#import "EWIO.h"

#import "EWLogInViewController.h"
#import "EWAppDelegate.h"

@implementation EWDatabaseDefault
@synthesize defaults;
@synthesize ringtoneList;


+(EWDatabaseDefault *)sharedInstance{
    static EWDatabaseDefault *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWDatabaseDefault alloc] init];
    });
    return sharedStore_;
}

- (void)initData{
    //data
    ringtoneList = ringtoneNameList;
}

- (NSDictionary *)defaults {
    
    return @{@"DefaultTone": @"Autumn Spring.caf",
              @"SocialLevel":@"Social Network Only",
              @"DownloadConnection":@"Cellular and Wifi",
              @"BedTimeNotification":@YES,
              @"SleepDuration":@8.0,
              @"PrivacyLevel":@"Privacy info",
              @"SystemID":@"0",
              @"FirstTime":@YES,
              @"SkipTutorial":@NO,
              @"Region":@"America",
              @"alarmTime":@"08:00"};
}

- (void)setDefault{
    //check alarm
    BOOL alarmGood = [EWAlarmManager.sharedInstance checkAlarms];
    if (!alarmGood) {
        NSLog(@"Alarm not set up yet");
        [[EWAlarmManager sharedInstance] scheduleAlarm];
    }
    
    //check task
    BOOL taskGood = [EWTaskStore.sharedInstance checkTasks];
    if (!taskGood) {
        NSLog(@"Task not set up yet");
        [EWTaskStore.sharedInstance scheduleTasks];
    }
    
    //check friends
    [[EWPersonStore sharedInstance] checkRelations];
    
    //check local notif
    [EWTaskStore.sharedInstance checkScheduledNotifications];
}

- (void)cleanData{
    NSLog(@"Cleaning all cache and server data");
    //Alarm
    [EWAlarmManager.sharedInstance deleteAllAlarms];
    //task
    [EWTaskStore.sharedInstance deleteAllTasks];
    
    //alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clean Data" message:@"All data has been cleaned." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    
    [[SMClient defaultClient].coreDataStore.contextForCurrentThread saveOnSuccess:^{
        //log out
        [[SMClient defaultClient] logoutOnSuccess:^(NSDictionary *result) {
            EWLogInViewController *controller = [[EWLogInViewController alloc] init];
            EWAppDelegate *delegate = (EWAppDelegate *)[UIApplication sharedApplication].delegate;
            [delegate.window.rootViewController presentViewController:controller animated:YES completion:NULL];
        } onFailure:^(NSError *error) {
            [NSException raise:@"Error log out" format:@"Reason: %@", error.description];
        }];
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error in save after clean" format:@"Reason: %@", error.description];
    }];
}


/*
-(void)createPerson{
    //create test person
    EWPerson *p1 = [EWPersonStore.sharedInstance createPerson];
    EWPerson *p2 = [EWPersonStore.sharedInstance createPerson];
    EWPerson *p3 = [EWPersonStore.sharedInstance createPerson];
    EWPerson *p4 = [EWPersonStore.sharedInstance createPerson];
    EWPerson *p5 = [EWPersonStore.sharedInstance createPerson];
    EWPerson *p6 = [EWPersonStore.sharedInstance createPerson];
    p1.name = @"磊哥";
    p1.systemID = EWIO.UUID;
    p1.userName = @"leiz";
    p1.profilePicKey = @"portrait2_s.png";
    p1.bgImageKey = @"bgImage.jpg";
    p1.region = @"North America";
    p1.city = @"New York";
    p1.lastSeenDate = [NSDate date];
    p1.facebook = @"leizhang0121";
    p1.weibo = @"磊哥在纽约";
    p1.statement = @"让梦想叫醒我！";
    [[NSUserDefaults standardUserDefaults] setObject:p1.systemID forKey:@"SystemID"];//save to the local
    NSLog(@"Onwer ID %@ has been set", p1.systemID);
    
    p2.name = @"小树";
    p2.systemID = EWIO.UUID;
    p2.userName = @"shens";
    p2.profilePicKey = @"profile2.png";
    p2.bgImageKey = @"bgImage.jpg";
    p2.region = @"Asia Pacific";
    p2.city = @"Shanghai";
    p2.lastSeenDate = [NSDate date];
    p2.facebook = @"leizhang0121";
    p2.weibo = @"Sam";
    p1.statement = @"I want to imbrace the sunshine in the morning. Let's do it together!";
    
    p3.name = @"铿哥";
    p3.systemID = EWIO.UUID;
    p3.userName = @"kenghe";
    p3.profilePicKey = @"profile3.png";
    p3.bgImageKey = @"bgImage.jpg";
    p3.region = @"Asia Pacific";
    p3.city = @"Shanghai";
    p3.lastSeenDate = [NSDate date];
    p3.facebook = @"leizhang0121";
    p3.weibo = @"Lisa";
    p1.statement = @"I want to imbrace the sunshine in the morning.";
    
    p4.name = @"天伟";
    p4.systemID = EWIO.UUID;
    p4.userName = @"tw";
    p4.profilePicKey = @"profile4.png";
    p4.bgImageKey = @"bgImage.jpg";
    p4.region = @"Asia Pacific";
    p4.city = @"Shanghai";
    p4.lastSeenDate = [NSDate date];
    p4.facebook = @"leizhang0121";
    p4.weibo = @"Lisa";
    p4.statement = @"I want to imbrace the sunshine in the morning.";
    
    p5.name = @"可可";
    p5.systemID = EWIO.UUID;
    p5.userName = @"doris";
    p5.profilePicKey = @"profile5.png";
    p5.bgImageKey = @"bgImage.jpg";
    p5.region = @"Asia Pacific";
    p5.city = @"Shanghai";
    p5.lastSeenDate = [NSDate date];
    p5.facebook = @"leizhang0121";
    p5.weibo = @"Lisa";
    p5.statement = @"I want to imbrace the sunshine in the morning.";

    p6.name = @"Kenny";
    p6.systemID = EWIO.UUID;
    p6.userName = @"Kenny";
    p6.profilePicKey = @"profile1.png";
    p6.bgImageKey = @"bgImage.jpg";
    p6.region = @"Asia Pacific";
    p6.city = @"Shanghai";
    p6.lastSeenDate = [NSDate date];
    p6.facebook = @"leizhang0121";
    p6.weibo = @"Lisa";
    p6.statement = @"I want to imbrace the sunshine in the morning.";
    
    [EWPersonStore.sharedInstance save];
}

-(void)createMediaItem{
    //create all media item
    EWMediaItem * p1 = [EWMediaStore.sharedInstance createMediaItem];
    EWMediaItem * p2 = [EWMediaStore.sharedInstance createMediaItem];
    EWMediaItem * p3 = [EWMediaStore.sharedInstance createMediaItem];
    EWMediaItem * p4 = [EWMediaStore.sharedInstance createMediaItem];
    EWMediaItem * p5 = [EWMediaStore.sharedInstance createMediaItem];
    EWMediaItem * p6 = [EWMediaStore.sharedInstance createMediaItem];
    p1.audioKey = @"vm1.m4a";
    p1.title = @"早上好";
    p1.message = @"早起的虫子更好";
    //EWPerson *p = [EWPersonStore.sharedInstance getPersonByName:@"Sam"];
    NSString *pID = [[NSUserDefaults standardUserDefaults] valueForKey:@"SystemID"];
    p2.audioKey = @"vm1.m4a";
    p2.title = @"Good morning";
    p2.message = @"It's another wonderful day! \n Test with short sound";
    p1.author = [EWPersonStore.sharedInstance getPersonByID:pID];
    
    p2.audioKey = @"vm2.m4a";
    p2.title = @"Good morning";
    p2.message = @"It's another wonderful day! \n Test with short sound";
    p2.author = [EWPersonStore.sharedInstance.allPerson objectAtIndex:2];
    
    p3.audioKey = @"vm3.m4a";
    p3.title = @"Good morning~";
    p3.message = @"It's a wonderful day! \n Let's imbrace the sunshine!";
    p3.author = [EWPersonStore.sharedInstance.allPerson objectAtIndex:3];
    
    p4.audioKey = @"vm4.m4a";
    p4.title = @"Hello morning!";
    p4.message = @"起床啦，快起床啦！";
    p4.author = [EWPersonStore.sharedInstance.allPerson objectAtIndex:4];
    
    p5.audioKey = @"vm5.m4a";
    p5.title = @"起床咯";
    p5.message = @"快起床，再不起就要迟到啦！";
    p5.author = [EWPersonStore.sharedInstance.allPerson objectAtIndex:5];
    
    p6.audioKey = @"vm6.m4a";
    p6.title = @"Good morning~";
    p6.message = @"Another day to fight! \n What's your plan today?";
    p6.author = [EWPersonStore.sharedInstance.allPerson objectAtIndex:1];
    
    [EWMediaStore.sharedInstance save];
}

-(void)createGroup{
    EWGroup *g1 = [EWGroupStore.sharedInstance createGroup];
    EWGroup *g2 = [EWGroupStore.sharedInstance createGroup];
    
    g1.name = @"Tennis";
    g1.statement = @"Let's become more healthy!";
    g1.topic = @"Sports";
    g1.created = [NSDate date];
    g1.image = [UIImage imageNamed:@"tennisGroup.png"];
    g1.wakeupTime = [NSDate date];
    if (EWPersonStore.sharedInstance.allPerson.count > 0) {
        [g1 addAdminObject:[EWPersonStore.sharedInstance.allPerson objectAtIndex:0]];
    }
    
    g2.name = @"Work work!";
    g2.statement = @"我们是快乐的打工仔";
    g2.topic = @"Work";
    g2.created = [NSDate date];
    g2.image = [UIImage imageNamed:@"workGroup.png"];
    g2.wakeupTime = [NSDate date];
    if (EWPersonStore.sharedInstance.allPerson.count > 1) {
        [g2 addAdminObject:[EWPersonStore.sharedInstance.allPerson objectAtIndex:1]];
    }
    
    [EWGroupStore.sharedInstance save];
}
 */

@end
