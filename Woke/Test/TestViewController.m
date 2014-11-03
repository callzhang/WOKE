//
//  TestViewController.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-2.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "TestViewController.h"
#import "EWUIUtil.h"
#import "EWAppDelegate.h"
#import "EWServer.h"

#import "EWWakeUpViewController.h"
#import "TestShakeViewController.h"
#import "TestSocailSDKViewController.h"
#import "EWLocalNotificationViewController.h"
#import "EWFirstTimeViewController.h"
#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWLogInViewController.h"
#import "EWTaskManager.h"
#import "EWWakeUpManager.h"
#import "EWMediaManager.h"
#import "EWMedia.h"
#import "EWTaskItem.h"
#import "EWUserManagement.h"
#import "EWSocialGraphManager.h"
#import "EWNotification.h"
#import "EWNotificationManager.h"
#import "EWBackgroundingManager.h"
#import "EWAlarm.h"
#import "EWAlarmManager.h"
#import "EWSession.h"

@interface TestViewController ()

@property (nonatomic, strong) UITableView *tableView;

@end

@interface TestViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>
@end

@implementation TestViewController{
    NSArray *titles;
    NSArray *subTitles;
}
@synthesize tableView = _tableView;

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    [self initData];
    [self initView];
}


- (void)initData {
    titles = @[@"Wake up in 30s",
               @"Shake test",
               @"Social Network API",
               @"Local Notifications",
               @"Clear all Alarms & Tasks",
               @"Test buzz",
               @"Test Alarm Timer",
               @"Add some media",
               @"Update facebook friends",
               @"Notification Center",
               @"Address book",
               @"Facebook post"];
    
    subTitles = @[@"Update task's time that is due in 30s.",
                  @"Test shake",
                  @"Test social networking capabilities",
                  @"List local notifications",
                  @"Delete all alarm & tasks.  Use it only when data is corrupted",
                  @"Send self a buzz",
                  @"Test alarm timer event. Cloase app after this!",
                  @"Add some medias to next task, takes 20s.",
                  @"Test for facebook friends list and store",
                  @"Create some notifications",
                  @"Read addressbook and find friends by matching email",
                  @"Send a facebook story"];
}

- (void)initView {
    self.title = @"Test Sheet";
    
    [EWUIUtil addTransparantNavigationBarToViewController:self
                                             withLeftItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(OnBack)]
                                                rightItem:nil];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.05];
    [self.view addSubview:_tableView];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)OnBack {
    [self dismissBlurViewControllerWithCompletionHandler:NULL];
}

@end

@implementation TestViewController (UITableView)

#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return titles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kStandardUITableViewCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row >= titles.count) {
        return nil;
    }
    
    static NSString *identifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        //This method dequeues an existing cell if one is available or creates a new one using the class or nib file you previously registered. If no cell is available for reuse and you did not register a class or nib file, this method returns nil.
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    cell.textLabel.text = titles[indexPath.row];
    cell.detailTextLabel.text = subTitles[indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor clearColor];
}

#pragma mark - TableView Delegate

- (void)OnCancel {
    [self dismissBlurViewControllerWithCompletionHandler:NULL];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0: {
            //Modify alarm that is due in 30s
            for (EWAlarm *alarm in [EWSession sharedSession].currentUser.alarms.copy) {
                if (alarm.time.weekdayNumber == [NSDate date].weekdayNumber) {
                    //add time 30s
                    NSDate *t = alarm.time;
                    alarm.time = [[NSDate date] dateByAddingTimeInterval:30];
                    DDLogInfo(@"chenged alarm time from %@ to %@", t.date2String, alarm.time.date2String);
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmTimeChangedNotification object:alarm userInfo:@{@"alarm": alarm}];
                    [EWSync saveWithCompletion:^{
                        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:^{
                            [rootViewController.view showSuccessNotification:@"Exit app and wait for next alarm"];
                        }];
                    }];
                }
            }
            
            break;
        }
        case 1: {
            //shake test
            TestShakeViewController *controller = [[TestShakeViewController alloc] init];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
            
            [self presentViewController:navigationController animated:YES completion:^{
                
            }];
            
            break;
        }
        case 2:{
            EWAlert(@"Function unavailable now");
//            TestSocailSDKViewController *controller = [[TestSocailSDKViewController alloc] init];
//            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
//            controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
//            [self presentViewController:navigationController animated:YES completion:^{
//            }];
            
            break;
        }
        case 3:{
            //local notification
            EWLocalNotificationViewController *controller = [[EWLocalNotificationViewController alloc] init];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
            [self presentViewController:navigationController animated:YES completion:NULL];
            break;
        }
        case 4:{
            [EWUserManagement purgeUserData];
            [self dismissViewControllerAnimated:YES completion:NULL];
            break;
        }
            
        case 5:{
            
            //send to self a push
            [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
            //dismiss self to present popup view
            [self dismissBlurViewControllerWithCompletionHandler:^{
                [EWServer buzz:@[[EWSession sharedSession].currentUser]];
            }];
            break;
        }
            
        case 6:{
            //alarm timer
            [[EWBackgroundingManager sharedInstance] startBackgrounding];
            [rootViewController dismissBlurViewControllerWithCompletionHandler:^{
                [rootViewController.view showSuccessNotification:@"Exit app now!"];
            }];
            
            //handle alarm timer
            [[EWWakeUpManager class] performSelector:@selector(handleAlarmTimerEvent:) withObject:nil afterDelay:5];
            
            break;
        }
        
        case 7:{//add some media
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            if ([EWAlarmManager myNextAlarm]) {
                //voice
                EWMedia *media = [[EWMediaManager sharedInstance] getWokeVoice];
                //[task addMediasObject:media];
                media.author = [EWSession sharedSession].currentUser;
                [EWSync save];
                
            }
            
            

            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
            break;
        }
            
        case 8:{//facebook friends get
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            EWSocialGraph *graph = [[EWSocialGraphManager sharedInstance] socialGraphForPerson:[EWSession sharedSession].currentUser];
            graph.facebookUpdated = nil;
            [EWUserManagement getFacebookFriends];
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            break;
        }
            
            
        case 9:{//add some notification
            
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            //create notifications
            EWNotification *notice_friending = [EWNotification newNotification];
            EWNotification *notice_friended = [EWNotification newNotification];
            EWNotification *notice_newMedia = [EWNotification newNotification];
            EWNotification *notice_system = [EWNotification newNotification];
            //1
            notice_friending.type = kNotificationTypeFriendRequest;
            notice_friending.owner = [EWSession sharedSession].currentUser;
            NSArray *people = [[EWPersonManager sharedInstance] everyone];
            NSInteger k = arc4random_uniform((uint32_t)people.count);
            EWPerson *user = people[k];
            notice_friending.sender = user.objectId;
            //2
            notice_friended.type = kNotificationTypeFriendAccepted;
            notice_friended.owner = [EWSession sharedSession].currentUser;
            k = arc4random_uniform((uint32_t)people.count);
            EWPerson *user2 = people[k];
            notice_friended.sender = user2.objectId;
            //3
            notice_newMedia.type = kNotificationTypeNextTaskHasMedia;
            notice_newMedia.owner = [EWSession sharedSession].currentUser;
            k = arc4random_uniform((uint32_t)people.count);
            EWPerson *user3 = people[k];
            notice_newMedia.sender = user3.objectId;
            //4
            notice_system.type = kNotificationTypeSystemNotice;
            notice_system.owner = [EWSession sharedSession].currentUser;
            NSDictionary *dic = @{@"title": @"Test system notice", @"content": @"This is a test notice. An alert show pop up if you tap me.", @"link": @"WokeAlarm.com"};
            notice_system.userInfo = dic;
            notice_system.sender = nil;
            //save
            [EWSync save];
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
            break;
        }
        case 10:{//address book
            [EWServer searchForFriendsOnServer];
        }
        case 11:{//facebook story post
            [EWServer uploadOGStoryWithPhoto:[EWSession sharedSession].currentUser.profilePic];
        }
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

