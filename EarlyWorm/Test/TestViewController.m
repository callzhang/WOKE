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

- (void)initData {
    _dataSource = @[@"Voicetone View", @"Shake test", @"Social Network API", @"Local Notifications", @"Clear Alarms & Tasks", @"Test push notification"];
}

- (void)initView {
    self.title = @"Test";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(OnBack)];

    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, EWScreenWidth, EWScreenHeight)];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initData];
    [self initView];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    cell.textLabel.text = [_dataSource objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - TableView Delegate

- (void)OnCancel {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0: {
            
            EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
            //controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
            controller.person = currentUser;
            [self presentViewController:navigationController animated:YES completion:^{}];
            
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
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [EWServer pushMedia:@"" ForUsers:@[currentUser] ForTask:@""];
            });
            
            //dismiss self to present popup view
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
            break;
        default:
            break;
    }
    
}

@end

