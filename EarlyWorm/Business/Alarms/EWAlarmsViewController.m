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

// Manager
#import "EWAlarmManager.h"
#import "EWPersonStore.h"
#import "EWTaskStore.h"
#import "EWDatabaseDefault.h"

// Model
#import "EWPerson.h"
#import "EWAlarmItem.h"

// Business
#import "TestViewController.h"
#import "EWEditAlarmViewController.h"
#import "EWWakeUpViewController.h"
#import "EWHistoryViewController.h"

//backend
#import "StackMob.h"
@interface EWAlarmsViewController ()

//@property (nonatomic, strong) UITableView *tableView;
//@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end
/*
@interface EWAlarmsViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>
@end
*/

@implementation EWAlarmsViewController
@synthesize me, alarms, tasks;
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
        self.tabBarItem.image = [UIImage imageNamed:@"alarm_icon.png"];
        //launch with local notif
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentWakeUpView:) name:UIApplicationLaunchOptionsLocalNotificationKey object:nil];
        //listen to user log in
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn) name:kPersonLoggedIn object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadView) name:kTaskNewNotification object:nil];
        //UI
        
        self.hidesBottomBarWhenPushed = NO;
        
        //alarmPages
        _alarmPages = [[NSMutableArray alloc] initWithCapacity:7];
    }
    return self;
}

- (void)userLoggedIn{
    self.me = [EWPersonStore sharedInstance].currentUser;
    //start working
    [self viewDidLoad];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (me) {
        [self initData];
        [self initView];
        [self reloadView];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //reload
    if (me) {
        [self reloadView];
    }
    
    
}

- (void)initData {
    //init alarm page container
    for (unsigned i = 0; i < self.alarms.count; i++) {
        [_alarmPages addObject:[NSNull null]];
    }
}

- (void)initView {
    //schedule button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(OnScheduleAlarm)];
    
#ifndef CLEAR_TEST
    //test view
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStylePlain target:self action:@selector(OnTest)];
#endif
    
    //owner info
    self.profileImageView.image = self.me.profilePic;
    self.nameLabel.text = self.me.name;
    self.locationLabel.text = [NSString stringWithFormat:@"%@", self.me.city];
    self.rankLabel.text = @"Early Bird";
    
    //paging
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _pageView.currentPage = 0;
    
    //[self reloadView]; //preload
    
}

- (void)reloadView {
    if (self.me) {
        _pageView.numberOfPages = self.alarms.count;
        
        [self loadScrollViewWithPage:_pageView.currentPage - 1];
        [self loadScrollViewWithPage:_pageView.currentPage];
        [self loadScrollViewWithPage:_pageView.currentPage + 1];
        [self.view setNeedsDisplay];
        [self.scrollView setNeedsDisplay];
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - launch option
- (void)presentWakeUpView{
    EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
    
    [self presentViewController:navigationController animated:YES completion:^{}];
}

#pragma mark - Accessors
- (EWPerson *)me{
    return [EWPersonStore sharedInstance].currentUser;
}

- (NSArray *)alarms{
    return [EWAlarmManager sharedInstance].allAlarms;
}

- (NSArray *)tasks{
    return [EWTaskStore sharedInstance].allTasks;
}

#pragma mark - UI Events

- (void)OnCancel {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)OnHistoryButtonTapped:(id)sender {
    
    // Show History ViewController
    EWHistoryViewController *controller = [[EWHistoryViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
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
    //get alarm schedule
    //edit alarm queue
    for (EWAlarmItem *a in [EWAlarmManager.sharedInstance allAlarms]) {
        NSLog(@"Updating alarm at weekday %d", [a.time weekdayNumber]);
    }
}

//main loading function
- (void)loadScrollViewWithPage:(NSInteger)page {
    if (page < 0 || page >= self.alarms.count) {
        return;
    }
    
	// Data
    if (_alarmPages.count==0) {
        return;
    }
    EWAlarmPageView *alarmPage = [_alarmPages objectAtIndex:page];
    // replace the placeholder if necessary
    if ((NSNull *)alarmPage == [NSNull null]) {
        alarmPage = [[EWAlarmPageView alloc] init];
    }
    
    //data
    //EWAlarmItem *alarm = _alarms[page];
    //page also means future day count
    EWTaskItem *task = EWTaskStore.sharedInstance.allTasks[page];
    
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
    EWEditAlarmViewController *controller = [[EWEditAlarmViewController alloc] init];
    controller.task = task;
    //controller.isNewAlarm = NO;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    [self presentViewController:navigationController animated:YES completion:^{}];
}






@end

