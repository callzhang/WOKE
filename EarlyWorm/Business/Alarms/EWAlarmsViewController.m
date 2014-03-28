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
#import "EWAppDelegate.h"
#import "NSString+Extend.h"
#import "NSDate+Extend.h"
#import "UIViewController+Blur.h"
#import "EWServer.h"

// Manager
#import "EWAlarmManager.h"
#import "EWPersonStore.h"
#import "EWTaskStore.h"

// Model
#import "EWPerson.h"
#import "EWAlarmItem.h"

// UI
#import "TestViewController.h"
#import "EWWakeUpViewController.h"
#import "EWAlarmScheduleViewController.h"
#import "EWPersonViewController.h"
#import "EWLogInViewController.h"
#import "EWCollectionPersonCell.h"
#import "EWSettingsViewController.h"
#import "EWRecordingViewController.h"

//backend
#import "StackMob.h"

@interface EWAlarmsViewController (){
    NSMutableArray *allPeople;
    NSInteger selectedPersonIndex;
}
@end

@implementation EWAlarmsViewController
@synthesize alarms, tasks;
@synthesize scrollView = _scrollView;
@synthesize pageView = _pageView;
@synthesize profileImageView = _profileImageView;
@synthesize nameLabel = _nameLabel;
@synthesize locationLabel = _locationLabel;
@synthesize rankLabel = _rankLabel;
@synthesize collectionView = _collectionView;

- (id)init {
    self = [super init];
    if (self) {
        
        //self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemHistory tag:0];
        //launch with local notif
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentWakeUpView:) name:UIApplicationLaunchOptionsLocalNotificationKey object:nil];
        //listen to user log in, and updates its view
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView) name:kPersonLoggedIn object:nil];
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView) name:kTaskNewNotification object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView) name:kTaskChangedNotification object:nil];//TODO: update specific alarm
        //user KVO
        [currentUser addObserver:self forKeyPath:@"profilePic" options:NSKeyValueObservingOptionNew context:NULL];
        //UI
        self.hidesBottomBarWhenPushed = NO;
    }
    return self;
}

- (void)refreshView{
    [self initData];
    [self initView];
    [self reloadAlarmPage];
    [_collectionView reloadData];
    [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initView];
}

- (void)initData {
    //init alarm page container
    if (currentUser) {
        alarms = [EWAlarmManager sharedInstance].allAlarms;
        tasks = [EWTaskStore sharedInstance].allTasks;
        if (alarms.count != 7 || tasks.count != 7 * nWeeksToScheduleTask) {
            NSLog(@"===== Something wrong with the Alarm(%ld) or Task(%lu) data, please check! =====", (long)alarms.count, (unsigned long)tasks.count);
            //[[EWDataStore sharedInstance] checkAlarmData];
            alarms = nil;
            tasks = nil;
        }else{
           //alarmPages
            _alarmPages = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
        }
        
        //person
        allPeople = [[[EWPersonStore sharedInstance] everyone] mutableCopy];
        
    }else{
        alarms = nil;
        tasks = nil;
        allPeople = nil;
        [_alarmPages removeAllObjects];
    }
}

- (void)initView {
    
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
    
    //collection view
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.contentInset = UIEdgeInsetsMake(_collectionView.frame.size.height, _collectionView.frame.size.width, _collectionView.frame.size.height, _collectionView.frame.size.width);
    [_collectionView registerClass:[EWCollectionPersonCell class] forCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier];
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.tag = kHexagonViewIdentifier;
    
    //paging
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.tag = kAlarmPageViewIdentifier;
    _pageView.currentPage = 0;
    
    //add button
    self.addBtn.alpha = (alarms.count == 0) ? 1:0;
    
}

- (void)reloadAlarmPage {
    _pageView.numberOfPages = self.alarms.count;
    if (alarms.count == 0 || tasks.count == 0) {
        NSLog(@"Alarm or Task count is zero, delete all subviews");
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

#pragma mark - UI Events

- (IBAction)mainActions:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Preferences", @"Test sheet", @"Refresh Person", nil];
    sheet.tag = 1002;
    [sheet showFromRect:self.actionBtn.frame inView:self.view animated:YES];
    
}


- (IBAction)scheduleInitialAlarms:(id)sender {
    [self scheduleAlarm];
}

- (IBAction)profile:(id)sender {
    if (!currentUser.facebook) {
        [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
        EWLogInViewController *loginVC = [[EWLogInViewController alloc] init];
        [loginVC loginInBackground];
        
    }else{
        EWPersonViewController *controller = [[EWPersonViewController alloc] init];
        controller.person = currentUser;
        [self presentViewController:controller animated:YES completion:NULL];
    }
    
    
}

- (void)OnTest {
#ifndef CLEAR_TEST
    TestViewController *controller = [[TestViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navigationController animated:YES completion:^{}];
#endif
}


#pragma mark - ScrollView
- (void)loadScrollViewWithPage:(NSInteger)page {
    if (page < 0 || page >= _alarmPages.count) {
        return;
    }
    
    
	// View
    // replace the placeholder if necessary
    if ([_alarmPages[page] isKindOfClass: [EWAlarmPageView class]]) {
        return;
    }
    
    EWAlarmPageView *alarmPage = [[EWAlarmPageView alloc] init];
    _alarmPages[page] = alarmPage;
    
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
    //[_alarmPages replaceObjectAtIndex:page withObject:alarmPage];
    
    
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


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[EWPerson class]]) {
        NSLog(@"Observed change for user: %@", change);
        if ([keyPath isEqualToString:@"profilePic"]) {
            //profile updated
            self.profileImageView.image = currentUser.profilePic;
            [self.view setNeedsDisplay];
        }else if ([keyPath isEqualToString:@"tasks"]){
            NSLog(@"KVO observed tasks changed");
        }else if ([keyPath isEqualToString:@"alarms"]){
            NSLog(@"KVO observed alarms changed");
        }
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)sender {
    
    // A possible optimization would be to unload the views+controllers which are no longer visible
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView.tag == kAlarmPageViewIdentifier) {
        // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
        // Switch the indicator when more than 50% of the previous/next page is visible
        CGFloat pageWidth = _scrollView.frame.size.width;
        NSInteger page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        _pageView.currentPage = page;
        [self reloadAlarmPage];
    }
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

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (actionSheet.tag == 1002) {
        //main action
        switch (buttonIndex) {
            case 0:{//Preference
                EWSettingsViewController *controller = [[EWSettingsViewController alloc] initWithNibName:nil bundle:nil];
                [self presentViewControllerWithBlurBackground:controller];
                break;
            }
                
            case 1:{
                TestViewController *controller = [[TestViewController alloc] init];
                [self presentViewControllerWithBlurBackground:controller];
                
                break;
            }
                
            case 2:{
                [self refreshView];
            }
                
            default:
                break;
        }

    }else if (actionSheet.tag == 1001){
        //person cell action sheet
        switch (buttonIndex) {
            case 0:{
                
                EWPersonViewController *controller = [[EWPersonViewController alloc] initWithNibName:nil bundle:nil];
                controller.person = allPeople[selectedPersonIndex];
                [self presentViewControllerWithBlurBackground:controller];
                
                break;
            }
            case 1:{
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                EWPerson *person = allPeople[selectedPersonIndex];
                [EWServer buzz:@[person]];
                
                break;
            }
            case 2:{
                EWRecordingViewController *controller = [[EWRecordingViewController alloc] init];
                EWTaskItem *task = [[EWTaskStore sharedInstance] nextTaskForPerson:allPeople[selectedPersonIndex]];
                controller.task = task;
                [self presentViewControllerWithBlurBackground:controller];
                break;
            }
                
            default:
                break;
        }
    }
    
}



#pragma mark - EWAlarmItemEditProtocal

- (void)scheduleAlarm{
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
                [self reloadAlarmPage];
            });
            
        });
    }
    //pop up alarmScheduleView
    EWAlarmScheduleViewController *controller = [[EWAlarmScheduleViewController alloc] init];
    //[self presentViewController:controller animated:YES completion:NULL];
    [self presentViewControllerWithBlurBackground:controller];
}

#pragma mark - launch option
- (void)presentWakeUpView:(NSNotification *)notification{
    NSLog(@"Entered app with local notification");
    EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
    EWTaskItem *task = notification.userInfo[kPushTaskKey];
    controller.task  = task;
    
    //[self presentViewController:navigationController animated:YES completion:NULL];
    [self presentViewControllerWithBlurBackground:controller];
}

#pragma mark - CollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (section == 0) {
        return allPeople.count;
    }else{
        return 0;
    }
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    EWCollectionPersonCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier forIndexPath:indexPath];
    EWPerson *person = allPeople[indexPath.row];
    cell.profilePic.image = person.profilePic;
    cell.name.text = person.name;
    
    
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //get cell
    EWCollectionPersonCell *cell = (EWCollectionPersonCell *)[collectionView cellForItemAtIndexPath:indexPath];
    selectedPersonIndex = indexPath.row;
    
    //action sheet
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Profile", @"Buzz", @"Voice", nil];
    sheet.tag = 1001;
    [sheet showFromRect:cell.frame inView:self.view animated:YES];
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

@end

