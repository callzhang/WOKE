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

// 业务界面
#import "EWWakeUpViewController.h"
#import "TestShakeViewController.h"
#import "TestSocailSDKViewController.h"
#import "EWLocalNotificationViewController.h"
#import "EWFirstTimeViewController.h"
#import "EWPerson.h"
#import "EWPersonStore.h"
#import "EWLogInViewController.h"
#import "StackMob.h"
#import "EWTaskStore.h"
#import "EWWakeUpManager.h"

@interface TestViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *dataSource;

@end

@interface TestViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>
@end

@implementation TestViewController
@synthesize tableView = _tableView;
@synthesize dataSource = _dataSource;

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
    _dataSource = @[@"Voicetone View", @"Shake test", @"Social Network API", @"Local Notifications", @"Clear Alarms & Tasks", @"Test push notification", @"Test Alarm Timer"];
}

- (void)initView {
    self.title = @"Test";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(OnBack)];
    CGRect tableFrame = self.view.frame;
    
    //title view
    if (self.navigationController == nil) {
        //header view
        UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 30, 18, 30)];
        [backBtn setImage:[UIImage imageNamed:@"back_btn"] forState:UIControlStateNormal];
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
    return _dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kStandardUITableViewCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row >= _dataSource.count) {
        return nil;
    }
    
    static NSString *identifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        //This method dequeues an existing cell if one is available or creates a new one using the class or nib file you previously registered. If no cell is available for reuse and you did not register a class or nib file, this method returns nil.
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    cell.textLabel.text = [_dataSource objectAtIndex:indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    
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
                controller.person = currentUser;
                [rootViewController presentViewController:controller animated:YES completion:NULL];
            }];
            
        }
            break;
        case 1: {
            
            TestShakeViewController *controller = [[TestShakeViewController alloc] init];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
            
            [self presentViewController:navigationController animated:YES completion:^{
                
            }];
            
        }
            break;
        case 2:{
            TestSocailSDKViewController *controller = [[TestSocailSDKViewController alloc] init];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
            [self presentViewController:navigationController animated:YES completion:^{
            }];

        }
            break;
        case 3:{
            EWLocalNotificationViewController *controller = [[EWLocalNotificationViewController alloc] init];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
            [self presentViewController:navigationController animated:YES completion:NULL];
        }
            break;
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
        }
            break;
            
        case 5:{
            //send to self a push
            
            //Delay execution of my block for 10 seconds.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [EWServer buzz:@[currentUser]];
            });
            
            //dismiss self to present popup view
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
            break;
            
        case 6:{
            //alarm timer in 10s
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [EWWakeUpManager handleAlarmTimerEvent];
            });
            [rootViewController dismissBlurViewControllerWithCompletionHandler:^{
                [rootViewController.view showSuccessNotification:@"Exit app in 10s"];
            }];
        }
            break;
            
        default:
            break;
    }
    
}

@end
