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
#import "EWPersonStore.h"
#import "EWLogInViewController.h"
#import "EWTaskStore.h"
#import "EWWakeUpManager.h"
#import "EWMediaStore.h"
#import "EWMediaItem.h"
#import "EWTaskItem.h"
#import "EWUserManagement.h"
#import "EWSocialGraphManager.h"
#import "EWNotification.h"
#import "EWNotificationManager.h"

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
    titles = @[@"Wake Up View",
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
    
    subTitles = @[@"Pop up the WakeUp View with all medias of mine",
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
    [self dismissViewControllerAnimated:YES completion:^{}];
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
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0: {//wake up view
            [EWWakeUpManager presentWakeUpView];
            
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
            [self dismissViewControllerAnimated:YES completion:^{
                [EWServer buzz:@[me]];
            }];
            break;
        }
            
        case 6:{
            //alarm timer
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            //alarm timer in 10s
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [EWWakeUpManager handleAlarmTimerEvent:nil];
            });
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [rootViewController dismissBlurViewControllerWithCompletionHandler:^{
                [rootViewController.view showSuccessNotification:@"Exit app now!"];
            }];
            break;
        }
        
        case 7:{//add some media
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:me];
            NSInteger m = 6 - task.medias.count;
            for (unsigned i=0; i< m; i++) {
                NSInteger x = arc4random_uniform(2);
                if (x==0) {
                    //buzz
                    EWMediaItem *media = [[EWMediaStore sharedInstance] createBuzzMedia];
                    [task addMediasObject:media];
                    [EWDataStore save];
                }else{
                    //voice
                    EWMediaItem *media = [[EWMediaStore sharedInstance] getWokeVoice];
                    //[task addMediasObject:media];
                    [media addTasksObject:task];
                    [EWDataStore save];
                }
                
            }
            
            

            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
            break;
        }
            
        case 8:{//facebook friends get
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            EWSocialGraph *graph = [[EWSocialGraphManager sharedInstance] socialGraphForPerson:me];
            graph.facebookUpdated = nil;
            [EWUserManagement getFacebookFriends];
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            break;
        }
            
            
        case 9:{//add some notification
            
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            //create notifications
            EWNotification *notice_friending = [EWNotificationManager newNotification];
            EWNotification *notice_friended = [EWNotificationManager newNotification];
            EWNotification *notice_newMedia = [EWNotificationManager newNotification];
            EWNotification *notice_system = [EWNotificationManager newNotification];
            //1
            notice_friending.type = kNotificationTypeFriendRequest;
            notice_friending.owner = me;
            NSArray *people = [[EWPersonStore sharedInstance] everyone];
            NSInteger k = arc4random_uniform((uint32_t)people.count);
            EWPerson *user = people[k];
            notice_friending.sender = user.objectId;
            //2
            notice_friended.type = kNotificationTypeFriendAccepted;
            notice_friended.owner = me;
            k = arc4random_uniform((uint32_t)people.count);
            EWPerson *user2 = people[k];
            notice_friended.sender = user2.objectId;
            //3
            notice_newMedia.type = kNotificationTypeNextTaskHasMedia;
            notice_newMedia.owner = me;
            k = arc4random_uniform((uint32_t)people.count);
            EWPerson *user3 = people[k];
            notice_newMedia.sender = user3.objectId;
            //4
            notice_system.type = kNotificationTypeNotice;
            notice_system.owner = me;
            NSDictionary *dic = @{@"title": @"Test system notice", @"content": @"This is a test notice. An alert show pop up if you tap me.", @"link": @"WokeAlarm.com"};
            notice_system.userInfo = dic;
            notice_system.sender = nil;
            //save
            [EWDataStore save];
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
            break;
        }
        case 10:{//address book
            [EWServer searchForFriendsOnServer];
        }
        case 11:{//facebook story post
            [EWServer uploadOGStoryWithPhoto:me.profilePic];
        }
        default:
            break;
    }
    
    
}

@end

