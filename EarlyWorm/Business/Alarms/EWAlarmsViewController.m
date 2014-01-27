//
//  EWAlarmsViewController.m.m
//  EarlyWorm
//
//  Created by shenslu on 13-7-11.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWAlarmsViewController.h"

// Util
#import "EWUIUtil.h"
#import "NSDate+Extend.h"
#import "MBProgressHUD.h"

// Manager
#import "EWAlarmManager.h"
#import "EWPersonStore.h"
#import "EWTaskStore.h"

// Model
#import "EWPerson.h"
#import "EWAlarmItem.h"

// Business
#import "TestViewController.h"
#import "EWWakeUpViewController.h"
#import "EWAlarmScheduleViewController.h"
#import "EWPersonViewController.h"
#import "EWLogInViewController.h"

//backend
#import "StackMob.h"

//view
extern UIView *rootview;

@interface EWAlarmsViewController ()

//@property (nonatomic, strong) UITableView *tableView;
//@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end
/*
@interface EWAlarmsViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>
@end
*/

@implementation EWAlarmsViewController
@synthesize alarms, tasks;
@synthesize scrollView = _scrollView;
@synthesize pageView = _pageView;
@synthesize profileImageView = _profileImageView;
@synthesize nameLabel = _nameLabel;
@synthesize locationLabel = _locationLabel;
@synthesize rankLabel = _rankLabel;

- (id)init {
    self = [super init];
    if (self) {
        self.title = LOCALSTR(@"Alarms");
        
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemHistory tag:0];
        //launch with local notif
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentWakeUpView:) name:UIApplicationLaunchOptionsLocalNotificationKey object:nil];
        //listen to user log in, and updates its view
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn) name:kPersonLoggedIn object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn) name:kPersonLoggedOut object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initView) name:kPersonProfilePicDownloaded object:nil];
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadView) name:kTaskNewNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadView) name:kTaskChangedNotification object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn) name:kAlarmsAllNewNotification object:nil];//this event occurs before tasks created, it will cause the reloadView fail
        //UI
        self.hidesBottomBarWhenPushed = NO;
        
        //alarmPages
        _alarmPages = [[NSMutableArray alloc] initWithCapacity:7];
    }
    return self;
}

- (void)userLoggedIn{
    [self initData];
    [self initView];
    [self reloadView];
    [MBProgressHUD hideAllHUDsForView:rootview animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (currentUser) {
        [self initData];
        [self initView];
        [self reloadView];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //reload
    if (currentUser) {
        //[self reloadView];
    }
}

- (void)initData {
    //init alarm page container
    if (currentUser) {
        alarms = [EWAlarmManager sharedInstance].allAlarms;
        tasks = [EWTaskStore sharedInstance].allTasks;
        /*
        for (unsigned i = 0; i < self.alarms.count; i++) {
            _alarmPages[i] = [NSNull null];
        }*/
        _alarmPages = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
    }else{
        alarms = nil;
        tasks = nil;
        [_alarmPages removeAllObjects];
    }
    
}

- (void)initView {
    //schedule button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(OnScheduleAlarm)];
    
#ifndef CLEAR_TEST
    //test view
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStylePlain target:self action:@selector(OnTest)];
#endif
    
    //owner info
    if (currentUser) {
        self.profileImageView.image = currentUser.profilePic;
        self.nameLabel.text = currentUser.name;
        self.locationLabel.text = currentUser.city ? currentUser.city : @"Somewhere";
        self.rankLabel.text = [NSString stringWithFormat:@"Last activity: %@", [currentUser.createddate date2numberDateString]];
    }else{
        self.profileImageView.image = [UIImage imageNamed:@"profile"];
        self.nameLabel.text = @"";
        self.locationLabel.text = @"";
        self.rankLabel.text = @"";
    }
    
    
    //nav bar
    //self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.169 green:0.373 blue:0.192 alpha:0.9];
    //self.navigationController.navigationBar.translucent = YES;
    
    //paging
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _pageView.currentPage = 0;
    
    //add button
    self.addBtn.alpha = (alarms.count == 0) ? 1:0;
    
}

- (void)reloadView {
    
    _pageView.numberOfPages = self.alarms.count;
    if (alarms.count == 0 || tasks.count == 0) {
        for (EWAlarmPageView *view in _scrollView.subviews) {
            if ([view isKindOfClass:[EWAlarmPageView class]]) {
                [view removeFromSuperview];
            }
        }
        _alarmPages = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
        _scrollView.contentSize = CGSizeMake(_scrollView.width * self.alarms.count, _scrollView.height);
        return;
    }
    
    [self loadScrollViewWithPage:_pageView.currentPage - 1];
    [self loadScrollViewWithPage:_pageView.currentPage];
    [self loadScrollViewWithPage:_pageView.currentPage + 1];
    [self.view setNeedsDisplay];
    [self.scrollView setNeedsDisplay];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UI Events

- (void)OnCancel {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#ifndef CLEAR_TEST
- (void)OnTest {
    TestViewController *controller = [[TestViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navigationController animated:YES completion:^{}];
}
#endif


- (void)OnScheduleAlarm{
    //pop up alarmScheduleView
    if (alarms.count == 0 && tasks.count == 0) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[EWAlarmManager sharedInstance] scheduleAlarm];
        [[EWTaskStore sharedInstance] scheduleTasks];
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        //refresh
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [self initData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self initView];
                [self reloadView];
            });
            
        });
    }
    //pop up alarmScheduleView
    EWAlarmScheduleViewController *controller = [[EWAlarmScheduleViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

//main loading function
- (void)loadScrollViewWithPage:(NSInteger)page {
    if (page < 0 || page >= _alarmPages.count) {
        return;
    }
    
    
	// View
    EWAlarmPageView *alarmPage;
    // replace the placeholder if necessary
    if (![_alarmPages[page] isKindOfClass: [EWAlarmPageView class]]) {
        alarmPage = [[EWAlarmPageView alloc] init];
        _alarmPages[page] = alarmPage;
    }else{
        return;
    }
    
    //data
    //page also means future day count
    //EWAlarmItem *alarm = alarms[page];
    EWTaskItem *task = tasks[page];
    
    //fill info
    alarmPage.task = task;
    
    if (page == 0) {
        alarmPage.typeText.text = @"Next";
    }
    else {
        alarmPage.typeText.text = @"Upcoming";
    }
    
    alarmPage.delegate = self;
    
    //replace
    [_alarmPages replaceObjectAtIndex:page withObject:alarmPage];
    
    
    // add the controller's view to the scroll view
    if (alarmPage.superview == nil) {
        CGRect frame = _scrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        alarmPage.frame = frame;
        [_scrollView addSubview:alarmPage];
    }
    
    _scrollView.contentSize = CGSizeMake(_scrollView.width * self.alarms.count, _scrollView.height);
}

- (IBAction)scheduleInitialAlarms:(id)sender {
    [self OnScheduleAlarm];
}

- (IBAction)profile:(id)sender {
    EWPersonViewController *controller = [[EWPersonViewController alloc] init];
    controller.person = currentUser;
    [self presentViewController:controller animated:YES completion:NULL];
    
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)sender {
    

	
    // A possible optimization would be to unload the views+controllers which are no longer visible
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = _scrollView.frame.size.width;
    NSInteger page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _pageView.currentPage = page;
    [self reloadView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
//    CGFloat pageWidth = scrollView.frame.size.width;
}

- (IBAction)changePage:(id)sender {
    NSInteger page = _pageView.currentPage;
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    // update the scroll view to the appropriate page
    CGRect frame = _scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [_scrollView scrollRectToVisible:frame animated:YES];
}



#pragma mark - EWAlarmItemEditProtocal
- (void)editTask:(EWTaskItem *)task forPage:(EWAlarmPageView *)page{
    //EWEditAlarmViewController *controller = [[EWEditAlarmViewController alloc] init];
    //controller.task = task;
    //controller.isNewAlarm = NO;
    //UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    //[self presentViewController:navigationController animated:YES completion:^{}];
}


#pragma mark - launch option
- (void)presentWakeUpView:(NSNotification *)notification{
    NSLog(@"Entered app with local notification");
    EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
    EWTaskItem *task = notification.userInfo[kLocalNotificationUserInfoKey];
    controller.task  = task;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    [self presentViewController:navigationController animated:YES completion:NULL];
}



@end

