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
               @"Notification Center"];
    
    subTitles = @[@"Pop up the WakeUp View with all medias of mine",
                  @"Test shake",
                  @"Test social networking capabilities",
                  @"List local notifications",
                  @"Delete all alarm & tasks.  Use it only when data is corrupted",
                  @"Send self a buzz",
                  @"Test alarm timer event. Cloase app after this!",
                  @"Add some medias to next task, takes 20s.",
                  @"Test for facebook friends list and store",
                  @"Create some notifications"];
}

- (void)initView {
    self.title = @"Test";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(OnBack)];
    CGRect tableFrame = self.view.frame;
    
    //title view
    if (self.navigationController == nil) {
        //header view
        UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(30, 30, 18, 30)];
        [backBtn setImage:[UIImage imageNamed:@"BackButton"] forState:UIControlStateNormal];
        [backBtn addTarget:self action:@selector(OnBack) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:backBtn];
        
        tableFrame.origin.y += MADEL_HEADER_HEIGHT;
        tableFrame.size.height -= MADEL_HEADER_HEIGHT;
    }
    
    _tableView = [[UITableView alloc] initWithFrame:tableFrame];
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
        case 0: {
            [self dismissViewControllerAnimated:YES completion:^{
                EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
                controller.person = me;
                [rootViewController presentViewControllerWithBlurBackground:controller];
            }];
            
            break;
        }
        case 1: {
            
            TestShakeViewController *controller = [[TestShakeViewController alloc] init];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
            
            [self presentViewController:navigationController animated:YES completion:^{
                
            }];
            
            break;
        }
        case 2:{
//            TestSocailSDKViewController *controller = [[TestSocailSDKViewController alloc] init];
//            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
//            controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
//            [self presentViewController:navigationController animated:YES completion:^{
//            }];
            
            break;
        }
        case 3:{
            
            EWLocalNotificationViewController *controller = [[EWLocalNotificationViewController alloc] init];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
            [self presentViewController:navigationController animated:YES completion:NULL];
            break;
        }
        case 4:{
            [EWPersonStore.sharedInstance purgeUserData];
            [self dismissViewControllerAnimated:YES completion:NULL];
            //cannot log out yet since the background need premission to delete on server
            /*
            EWLogInViewController *controller = [[EWLogInViewController alloc] init];
            
            [[SMClient defaultClient] logoutOnSuccess:^(NSDictionary *result) {
                [[UIAlertView alloc] initWithTitle:@"Cleaned" message:@"You have been successfully logged out and data has been purged" delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
            } onFailure:^(NSError *error) {
                //
            }];
            [self presentViewController:controller animated:YES completion:NULL];
             */
            break;
        }
            
        case 5:{
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            //send to self a push
            //Delay execution of my block for 10 seconds.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [EWServer buzz:@[me]];
            });
            
            //dismiss self to present popup view
            [self dismissViewControllerAnimated:YES completion:NULL];
            break;
        }
            
        case 6:{
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            //alarm timer in 10s
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
            EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskAtDayCount:0 ForPerson:[EWPersonStore me]];
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
                    EWMediaItem *media = [[EWMediaStore sharedInstance] createPseudoMedia];
                    //[task addMediasObject:media];
                    [media addTasksObject:task];
                    [EWDataStore save];
                }
                
            }
            
            

            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
            break;
        }
            
        case 8:{
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            EWSocialGraph *graph = [[EWSocialGraphManager sharedInstance] socialGraphForPerson:me];
            graph.facebookUpdated = nil;
            [EWUserManagement getFacebookFriends];
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            break;
        }
            
            
        case 9:{
            
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
            
        }
        default:
            break;
    }
    
    
}

@end

