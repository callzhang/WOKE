//
//  TestWeiboViewController.m
//  EarlyWorm
//
//  Created by shenslu on 13-10-1.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "TestSocailSDKViewController.h"
#import "EWUIUtil.h"

#import "EWWeiboManager.h"
#import "EWFacebookManager.h"

#import "EWWeiboFriendListViewController.h"		
#import "EWFacebookFriendListViewController.h"

@interface TestSocailSDKViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *dataSource;

@end

@interface TestSocailSDKViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>
@end

@implementation TestSocailSDKViewController
@synthesize tableView = _tableView;
@synthesize dataSource = _dataSource;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)initData {
    
    _dataSource = @[@{@"name":@"Facebook", @"data":@[@"发Facebook消息", @"Facebook授权", @"注销Facebook授权", @"获取Facebook好友列表", @"邀请Facebook好友"]},@{@"name":@"新浪微博", @"data":@[@"发微博", @"微博授权", @"注销微博授权", @"获取微博好友列表",@"邀请微博好友"]}];
}

- (void)initView {
    
    self.title = @"社交SDK功能测试";
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, EWScreenWidth, EWContentHeight)];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initData];
    [self initView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Events
- (void)OnCancel {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end

@implementation TestSocailSDKViewController (UITableView)

#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSDictionary *dict = [_dataSource objectAtIndex:section];
    NSArray *array = [dict objectForKey:@"data"];
    return array.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kStandardUITableViewCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *dict = [_dataSource objectAtIndex:indexPath.section];
    NSArray *array = [dict objectForKey:@"data"];

    static NSString *identifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = [array objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - TableView Delegate

- (void)handleFacebook:(NSIndexPath *)indexPath {
    
    EWFacebookManager *fbManger = [EWFacebookManager sharedInstance];

    switch (indexPath.row) {
        case 0: { // send message
            [fbManger sendWebLink];
        }
            break;
        case 1: {
            [fbManger doAuth];
        }
            break;
        case 2: {
            [fbManger logoutFacebook];
        }
            break;
        case 3: {
            EWFacebookFriendListViewController *controller = [[EWFacebookFriendListViewController alloc] init];
            
            [self.navigationController pushViewController:controller animated:YES];
        }
            break;
            
        case 4: {//invite
            
        }
            break;
        default:
            break;
    }
}

- (void)handleWeibo:(NSIndexPath *)indexPath {
    EWWeiboManager *weiboManger = [EWWeiboManager sharedInstance];
    
    switch (indexPath.row) {
        case 0: { // sendcontent
            [weiboManger sendWebLink];
        }
            break;
        case 1: { // do auth
            [weiboManger doAuth];
        }
            break;
        case 2:{
            [weiboManger logoutWeibo];
        }
            break;
        case 3:{
            EWWeiboFriendListViewController *controller = [[EWWeiboFriendListViewController alloc] init];
            
            [self.navigationController pushViewController:controller animated:YES];
        }
            break;
        case 4: {
            
            [weiboManger inviteFriend];

        }
            break;
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case 0: { // fb
            [self handleFacebook:indexPath];
        }
            break;
        case 1: { // wb
            [self handleWeibo:indexPath];
        }
            break;
        default:
            break;
    }
}

@end

