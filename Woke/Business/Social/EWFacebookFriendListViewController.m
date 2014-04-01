//
//  EWFacebookFriendListViewController.m
//  EarlyWorm
//
//  Created by shenslu on 13-10-4.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWFacebookFriendListViewController.h"
#import "EWUIUtil.h"

#import "EWFacebookManager.h"

@interface EWFacebookFriendListViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic) BOOL isFriendListLoadAll;

@end

@interface EWFacebookFriendListViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>
@end

@interface EWFacebookFriendListViewController (FacebookManager) <EWFacebookManagerDelegate>
@end

@implementation EWFacebookFriendListViewController
@synthesize tableView = _tableView;
@synthesize dataSource = _dataSource;
@synthesize isFriendListLoadAll = _isFriendListLoadAll;

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)initData {
    
    _dataSource = [NSMutableArray array];
    
    EWFacebookManager *fbMgr = [EWFacebookManager sharedInstance];
    [fbMgr RegisterDelegate:self];
    [fbMgr getFriendList];
}

- (void)initView {
    self.title = @"Facebook好友列表";
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

@implementation EWFacebookFriendListViewController(UITableView)

#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (_dataSource.count == 0) {
        return 0;
    }
    
    if (_isFriendListLoadAll) {
        return _dataSource.count;
    }
    
    return _dataSource.count+1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kStandardUITableViewCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_dataSource.count == 0) {
        return nil;
    }
    
    if (indexPath.row > _dataSource.count) {
        return nil;
    }
    
    if (indexPath.row == _dataSource.count) {
        if (!_isFriendListLoadAll) {
            static NSString *loadMoreCell = @"loadMoreCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:loadMoreCell];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:loadMoreCell];
            }
            cell.textLabel.textColor = [UIColor redColor];
            cell.textLabel.text = @"加载更多";
            
            return cell;
        }
    }
    
    static NSString *identifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    NSDictionary *dict = [_dataSource objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [dict objectForKey:@"name"];
    cell.detailTextLabel.text = [dict objectForKey:@"id"];
    return cell;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _dataSource.count) {
        // load more
        EWFacebookManager *fbMgr = [EWFacebookManager sharedInstance];
        [fbMgr appendFriendList];
    }
}

@end

@implementation EWFacebookFriendListViewController (FacebookManager)

- (void)EWFacebookManagerDidGotFriendList:(NSArray *)friendList isAll:(BOOL)isAll {
    
    _isFriendListLoadAll = isAll;
    
    if (friendList.count > 0) {
        [_dataSource removeAllObjects];
        [_dataSource addObjectsFromArray:friendList];
        
        [_tableView reloadData];
    }
}

@end

