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
//#import "NGAParallaxMotion.h"

// Manager
#import "EWAlarmManager.h"
#import "EWPersonStore.h"
#import "EWTaskStore.h"
#import "EWNotificationManager.h"
#import "TestFlight.h"

// Model
#import "EWPerson.h"
#import "EWAlarmItem.h"
#import "EWTaskItem.h"

// UI
#import "TestViewController.h"
#import "EWWakeUpViewController.h"
#import "EWAlarmScheduleViewController.h"
#import "EWPersonViewController.h"
#import "EWLogInViewController.h"
#import "EWCollectionPersonCell.h"
#import "EWSettingsViewController.h"
#import "EWRecordingViewController.h"
#import "EWNotificationViewController.h"
#import "NavigationControllerDelegate.h"
#import "EWFeedbackViewController.h"

//backend


//definition
#define kIndicatorHideTimer            2

@interface EWAlarmsViewController (){
    //NSMutableArray *allPeople;
    NSMutableArray *cellChangeArray;
    NSInteger selectedPersonIndex;
    NSTimer *indicatorHideTimer;
    NSTimer *collectionUpdateTimer;
    BOOL taskScheduled;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchController;
@property (nonatomic, strong) NavigationControllerDelegate *navDelegate;
@end

@implementation EWAlarmsViewController

@synthesize alarms, tasks, people; //data source
@synthesize scrollView = _scrollView;
@synthesize pageView = _pageView;
@synthesize collectionView = _collectionView;
@synthesize fetchController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        //listen to user log in, and updates its view
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView) name:kPersonLoggedIn object:nil];
        [[EWPersonStore sharedInstance] addObserver:self forKeyPath:@"currentUser" options:NSKeyValueObservingOptionNew context:nil];
        
        //initial value
        people = [[NSUserDefaults standardUserDefaults] objectForKey:@"peopleList"]?:@[];
        _alarmPages = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
        cellChangeArray = [NSMutableArray new];
        taskScheduled = NO;
    }
    return self;
}

- (void)refreshView{
    //add observer to myTasks
    [me addObserver:self forKeyPath:@"tasks" options:NSKeyValueObservingOptionNew context:nil];
    //listen to schedule signal
    [[EWTaskStore sharedInstance] addObserver:self forKeyPath:@"isSchedulingTask" options:NSKeyValueObservingOptionNew context:nil];
    [me addObserver:self forKeyPath:@"notifications" options:NSKeyValueObservingOptionNew context:nil];
    
    //update data and view
    [self initData];
    [self reloadAlarmPage];
    [self centerView];
    
    [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //static UI stuff (do it once)
    //collection view
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    UINib *nib = [UINib nibWithNibName:@"EWCollectionPersonCell" bundle:nil];
    [_collectionView registerNib:nib forCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier];
    _collectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Triangle Tile Half"]];
    //UIImageView *pattern = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Triangle Tile Half"]];
    UIImageView *background = [[UIImageView alloc] initWithFrame:_collectionView.frame ];
    background.image = [UIImage imageNamed:@"Background"];
    [self.view insertSubview:background belowSubview:_collectionView];
    
    //paging
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _pageView.currentPage = 0;
    _pageView.hidden = YES;
    
    
    //add blur bar
//    UIToolbar *blurBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 478, 320, 90)];
//    blurBar.barStyle = UIBarStyleBlack;
//    [self.view insertSubvieØw:blurBar aboveSubview:_collectionView];
    
    //parallax
//    self.background.parallaxIntensity = -100;
//    self.collectionView.parallaxIntensity = 20;
    
    //indicator center
    self.youIndicator.layer.anchorPoint = CGPointMake(0.5, 0.5);
    
    //dynamic UI stuff
    [self initData];
    [self initView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self centerView];

}

- (void)initData {
    
    //init alarm page container
    if (me) {
        alarms = [EWAlarmManager myAlarms];
        tasks = [EWTaskStore myTasks];
        if (alarms.count != 7 || tasks.count != 7 * nWeeksToScheduleTask) {
            NSLog(@"%s: Alarm(%ld) and Task(%ld)", __func__, (long)alarms.count, (long)tasks.count);
            alarms = nil;
            tasks = nil;
            
        }else{
            //alarmPages
            _alarmPages = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
            for (EWAlarmPageView *view in _scrollView.subviews) {
                [view removeFromSuperview];
            }
        }
        
        //fetch everyone
        dispatch_async([EWDataStore sharedInstance].dispatch_queue, ^{
            [[EWPersonStore sharedInstance] everyone];
        });
        
    }else{
        alarms = nil;
        tasks = nil;
        [_alarmPages removeAllObjects];
    }
}

- (void)initView {
    
    //show loading indicator
    [self showAlarmPageLoading:YES];
    
    //load page
    [self reloadAlarmPage];
}


#pragma mark - Fetch Controller
- (NSFetchedResultsController *)fetchController{
    if (fetchController) {
        return fetchController;
    }
    
    //predicate
    //NSArray *usernameList = [people valueForKey:@"username"];
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"username IN %@", usernameList];
    
    //sort
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO];
    
    //request
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWPerson"];
    //request.predicate = predicate;
    request.sortDescriptors = @[sort];
    
    //controller
    fetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                          managedObjectContext:[EWDataStore currentContext]
                                                            sectionNameKeyPath:nil
                                                                     cacheName:@"com.wokealarm.fetchControllerCache"];
    fetchController.delegate = self;
    request.fetchLimit = 100;
    
    //fetch everyone
    NSError *err;
    if (![self.fetchController performFetch:&err]) {
        NSLog(@"*** Failed to fetch everyone: %@", err);
    }
    
    return fetchController;
}



#pragma mark - ScrollView
- (void)reloadAlarmPage {
    //data
    alarms = [EWAlarmManager myAlarms];
    tasks = [EWTaskStore myTasks];
    
    if (alarms.count == 0 || tasks.count == 0) {
        //init state
        
        //remove all page
        for (EWAlarmPageView *view in _scrollView.subviews) {
            if ([view isKindOfClass:[EWAlarmPageView class]]) {
                [view removeFromSuperview];
            }
        }
        //reset the page
        [_alarmPages removeAllObjects];
        _alarmPages = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
        _scrollView.contentSize = CGSizeMake(_scrollView.width * self.alarms.count, _scrollView.height);
        
        return;
        
        
    }else if(alarms.count != 7 || tasks.count != 7* nWeeksToScheduleTask){
        //task or alarm incomplete, schedule
        //init state
        
        alarms = [[EWAlarmManager sharedInstance] scheduleNewAlarms];
        tasks = [[EWTaskStore sharedInstance] scheduleTasks];
        return;
    }
    
    self.addBtn.hidden = YES;
    [self.alarmloadingIndicator stopAnimating];
    _pageView.numberOfPages = tasks.count;
    //determine if scroll need flash
    bool flash = NO;
    if ([_alarmPages[0] isEqual: @NO]){
        NSLog(@"First time, need flash scroll");
        flash = YES;
    }
    
    [self loadScrollViewWithPage:[self currentPage] - 1];
    [self loadScrollViewWithPage:[self currentPage]];
    [self loadScrollViewWithPage:[self currentPage] + 1];
    [self.view setNeedsDisplay];
    [self.scrollView setNeedsDisplay];
    
    //flash
    if (flash) [_scrollView flashScrollIndicators];
    
}


- (void)loadScrollViewWithPage:(NSInteger)page {
    
    //page also means future day count
    
    //skip if page is out of bound
    if (page < 0 || page >= _alarmPages.count) return;
    
    //data
    EWTaskItem *task = tasks[page];
    
    
	// View
    // replace the placeholder if necessary
    if ((BOOL)[_alarmPages[page] isKindOfClass: [EWAlarmPageView class]]) {
        EWAlarmPageView *pageView = (EWAlarmPageView *)_alarmPages[page];
        pageView.task = task;
        return;
    }
    
    //check
    for (UIView *view in self.scrollView.subviews) {
        if (view.frame.origin.x == self.scrollView.frame.size.width * page) {
            //[NSException raise:@"Duplicated alarm page" format:@"Please check"];
            NSLog(@"@@@@ Duplicated alarm page at %ld", (long)page);
        }
    }
    
    //if page empty, add that to the page array
    //EWAlarmPageView *alarmPage = [[EWAlarmPageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height*(7/8), self.view.frame.size.width, self.view.frame.size.height/8)];
    
    EWAlarmPageView *alarmPage =  [[[NSBundle mainBundle] loadNibNamed:@"EWAlarmPage" owner:self options:nil] firstObject];
    
    _alarmPages[page] = alarmPage;
    
    //fill info
    alarmPage.task = task;
    
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

#pragma mark - UI Events

- (IBAction)mainActions:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Preferences", @"Test sheet", @"Refresh", @"Feedback", nil];
    sheet.tag = kOptionsAlert;
    [sheet showFromRect:self.actionBtn.frame inView:self.view animated:YES];
    
}

- (IBAction)showNotification:(id)sender {
    EWNotificationViewController *controller = [[EWNotificationViewController alloc] initWithNibName:nil bundle:nil];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewControllerWithBlurBackground:navController];
}


- (IBAction)scheduleInitialAlarms:(id)sender {
    [self scheduleAlarm];
}


- (void)OnTest {
#ifndef CLEAR_TEST
    TestViewController *controller = [[TestViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navigationController animated:YES completion:^{}];
#endif
}

- (IBAction)youBtn:(id)sender {
    [self centerView];
}



- (IBAction)pinched:(UIPinchGestureRecognizer *)sender {
    if (sender.scale < 0.5) {
        EWHexagonFlowLayout *layout = (EWHexagonFlowLayout *)self.collectionView.collectionViewLayout;
        [layout resetLayoutWithRatio:1.0];
    }else if (sender.scale > 2){
        EWHexagonFlowLayout *layout = (EWHexagonFlowLayout *)self.collectionView.collectionViewLayout;
        [layout resetLayoutWithRatio:2.0];
    }
}


- (void)showAlarmPageLoading:(BOOL)on{
    if (on) {
        [self.alarmloadingIndicator startAnimating];
        self.addBtn.hidden = YES;
    }else{
        
        [self.alarmloadingIndicator stopAnimating];
        self.addBtn.hidden = NO;
    }
}



- (void)centerView{
    //根据tag值判断是否创建meun
    if([rootViewController.view viewWithTag:kMenuTag]){
        return;
    }
    BOOL scrolling = [self.collectionView.layer animationForKey:@"bounds"] !=nil;
    if (scrolling) {
        return;
    }
    if ([_collectionView numberOfItemsInSection:0]>0) {
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredVertically | UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
    }
}

#pragma mark - KVO & Notification
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if ([object isKindOfClass:[EWPersonStore class]]) {
        if (me) {
            [self refreshView];
        }
    }else if ([object isKindOfClass:[EWPerson class]]) {
        
        if ([keyPath isEqualToString:@"tasks"]){
            static NSTimer *alarmPagetimer;
            NSInteger nTask = me.tasks.count;
            if (nTask == 7*nWeeksToScheduleTask || nTask == 0){
                [alarmPagetimer invalidate];
                alarmPagetimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(reloadAlarmPage) userInfo:nil repeats:NO];
                if (nTask == 0){
                    if (taskScheduled) {
                        [self showAlarmPageLoading:NO];
                    }else{
                        [self showAlarmPageLoading:YES];
                    }
                }
            }else{
                [self showAlarmPageLoading:YES];
            }
            
        }else if ([keyPath isEqualToString:@"notifications"]){
            //notification count
            NSInteger nUnread = [EWNotificationManager myNotifications].count;
            [self.notificationBtn setTitle:[NSString stringWithFormat:@"%ld", (long)nUnread] forState:UIControlStateNormal];
            if (nUnread == 0) {
                [UIView animateWithDuration:0.5 animations:^{
                    self.notificationBtn.alpha = 0.1;
                }];
            }else{
                [UIView animateWithDuration:0.5 animations:^{
                    self.notificationBtn.alpha = 1;
                }];
            }
        }
        
    }else if ([object isKindOfClass:[EWTaskStore class]]){
        if ([EWTaskStore sharedInstance].isSchedulingTask) {
            NSLog(@"Detected %@ is scheduling", [object class]);
            [self showAlarmPageLoading:YES];
            taskScheduled = NO;
        }else{
            NSLog(@"%@ finished scheduling", [object class]);
            [self showAlarmPageLoading:NO];
            taskScheduled = YES;
        }
    }else{
        NSLog(@"@@@ Unhandled observation: %@", [object class]);
    }
}


#pragma mark - UIScrollViewDelegate
- (NSInteger)currentPage{
    CGFloat pageWidth = _scrollView.frame.size.width;
    return lroundf(_scrollView.contentOffset.x / pageWidth);
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    if (sender.tag == kCollectionViewTag) {
        
        //indicator
        static float const maxX = 120;
        static float const maxY = 190;
        
        CGPoint frameCenter = _collectionView.center;
        //UICollectionViewCell *cell0 = [self collectionView:_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        UICollectionViewLayoutAttributes *attribute = [_collectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        CGPoint center = [_collectionView convertPoint:attribute.center toView:self.view];
        float X = center.x - frameCenter.x;
        float Y = center.y - frameCenter.y;
        
        if (fabsf(X)<160 && fabsf(Y)<250) {
            //in the screen
            if (self.youIndicator.alpha == 1) {
                [self hideIndicator];
            }
        }else{
            //out of screen
            float x1 = X;
            float y1 = Y;
            if (X > maxX) {
                x1 = maxX;
            }else if (X < -maxX){
                x1 = -maxX;
            }
            if (Y > maxY) {
                y1 = maxY;
            } else if(Y<-maxY) {
                y1 = -maxY;
            }
            float degree = atan2f(Y, X) + M_PI_4 + M_PI_2;
            
            if (self.youIndicator.hidden) {
                self.youIndicator.hidden = NO;
                [UIView transitionWithView:self.youIndicator duration:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.youIndicator.transform = CGAffineTransformMakeTranslation(x1, y1);
                    self.youBtn.transform = CGAffineTransformMakeRotation(degree);
                    self.youIndicator.alpha = 1;
                } completion:^(BOOL finished) {
                    //
                }];
            }else{
                self.youIndicator.transform = CGAffineTransformMakeTranslation(x1, y1);
                self.youBtn.transform = CGAffineTransformMakeRotation(degree);
            }
        }
                                       
        
        //center collectionview
        [indicatorHideTimer invalidate];
        indicatorHideTimer = [NSTimer scheduledTimerWithTimeInterval:kIndicatorHideTimer target:self selector:@selector(hideIndicator) userInfo:nil repeats:NO];
    }
}

- (void)hideIndicator{
    [UIView animateWithDuration:0.3 animations:^{
        self.youIndicator.alpha = 0;
    } completion:^(BOOL finished) {
        self.youIndicator.hidden = YES;
    }];
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView.tag == kAlarmPageTag) {
            // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
            // Switch the indicator when more than 50% of the previous/next page is visible
            NSInteger page = [self currentPage];
            _pageView.currentPage = page;
            [self reloadAlarmPage];
    }
    
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
    if (actionSheet.tag == kOptionsAlert) {
        //main action
        switch (buttonIndex) {
            case 0:{//Preference
                EWSettingsViewController *controller = [[EWSettingsViewController alloc] initWithNibName:nil bundle:nil];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
                [self presentViewControllerWithBlurBackground:nav];
                break;
            }
                
            case 1:{ //test view
                TestViewController *controller = [[TestViewController alloc] init];
                [self presentViewControllerWithBlurBackground:controller];
                
                break;
            }
                
            case 2:{
                [self refreshView];
            }
                
            case 3:{
                EWFeedbackViewController *controller = [[EWFeedbackViewController alloc] initWithNibName:nil bundle:nil];
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
                [self presentViewControllerWithBlurBackground:navController];
            }
                
            default:
                break;
        }
        
    }else if (actionSheet.tag == kCollectionViewCellAlert){
        //person cell action sheet
        EWPerson *person = [self.fetchController objectAtIndexPath:[NSIndexPath indexPathForItem:selectedPersonIndex inSection:0]];
        switch (buttonIndex) {
            case 0:{
                
                EWPersonViewController *controller = [[EWPersonViewController alloc] initWithNibName:nil bundle:nil];
                controller.person = person;
                [self presentViewControllerWithBlurBackground:controller];
                
                break;
            }
            case 1:{
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                [EWServer buzz:@[person]];
                
                break;
            }
            case 2:{
                EWRecordingViewController *controller = [[EWRecordingViewController alloc] initWithPerson:person];
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
    EWAlarmScheduleViewController *controller = [[EWAlarmScheduleViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewControllerWithBlurBackground:navController];
    
}

#pragma mark - CollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchController.sections[section];
    return [sectionInfo numberOfObjects];
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    NSArray *sections = self.fetchController.sections;
    if (sections) {
        return sections.count;
    }
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    //Cell
    EWCollectionPersonCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier forIndexPath:indexPath];
    
    //Data
    EWPerson *person = [self.fetchController objectAtIndexPath:indexPath];
    
    //shallow update
    //it's not a good place to update, as it will contently updating when cell is being displayed
//    [person refreshShallowWithCompletion:^{
//        NSLog(@"Person %@(%@) shallow updated", person.name, person.objectId);
//    }];
    
    cell.person = person;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //if me
#ifdef DEV_TEST
    
#else
    EWPerson *person = [self.fetchController objectAtIndexPath:indexPath];
    if (person.isMe) {
        EWPersonViewController *controller = [[EWPersonViewController alloc] initWithPerson:person];
        controller.canSeeFriendsDetail = YES;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        navDelegate = [[NavigationControllerDelegate alloc] init];
        navController.delegate = navDelegate;
        [self presentViewControllerWithBlurBackground:navController completion:NULL];
        return;
    }
#endif
    
    //get cell
    EWCollectionPersonCell *cell = (EWCollectionPersonCell *)[collectionView cellForItemAtIndexPath:indexPath];
    selectedPersonIndex = indexPath.row;

    //根据tag值判断是否创建meun
    if([rootViewController.view viewWithTag:kMenuTag]){
        return;
    }
    

    
    //create menu with cell
    EWPopupMenu *menu = [[EWPopupMenu alloc] initWithCell:cell];
    menu.tag = kMenuTag;
    __weak EWPopupMenu *weakMenu = menu;
    
    //create button block
    menu.toProfileButtonBlock = ^{
        
        EWPerson *person = [self.fetchController objectAtIndexPath:[NSIndexPath indexPathForItem:selectedPersonIndex inSection:0]];
        EWPersonViewController *controller = [[EWPersonViewController alloc] initWithPerson:person];
        controller.canSeeFriendsDetail = YES;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        
        [weakMenu closeMenuWithCompletion:^{
            [self presentViewControllerWithBlurBackground:navController completion:NULL];
        }];
    };
    
    menu.toBuzzButtonBlock = ^{
        EWPerson *person = [self.fetchController objectAtIndexPath:[NSIndexPath indexPathForItem:selectedPersonIndex inSection:0]];
        //[MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
        [EWServer buzz:@[person]];
        [weakMenu closeMenu];
    };
    
    menu.toVoiceButtonBlock = ^{
        EWPerson *person = [self.fetchController objectAtIndexPath:[NSIndexPath indexPathForItem:selectedPersonIndex inSection:0]];
        EWRecordingViewController *controller = [[EWRecordingViewController alloc] initWithPerson:person];
        
        [weakMenu closeMenuWithCompletion:^{
            [self presentViewControllerWithBlurBackground:controller];
        }];
    };
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


#pragma mark - FetchedResultController delegate
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type{
    NSLog(@"FetchController detected session change");
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:{
            __block BOOL duplicated = NO;
            [cellChangeArray enumerateObjectsUsingBlock:^(NSDictionary *change, NSUInteger idx, BOOL *stop) {
                if([change[@(type)] isEqual:newIndexPath]){
                    duplicated = YES;
                }
            }];
            if(!duplicated) change[@(type)] = newIndexPath;
        }
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:{
            __block BOOL duplicated = NO;
            [cellChangeArray enumerateObjectsUsingBlock:^(NSDictionary *change, NSUInteger idx, BOOL *stop) {
                if([change[@(type)] isEqual:newIndexPath]){
                    duplicated = YES;
                }
            }];
            change[@(type)] = indexPath;
        }
            
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [cellChangeArray addObject:change];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller{
    //NSLog(@"Content of collection view will change");
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    //Lesson learned: do not update collectionView in parts, as the final count may not be equal to inserts/deletes applied partially.
    //Also, do not delay the update, as the count may not hold when accumulated with a lot of updates.
    static NSDate *lastUpdated;
    if (cellChangeArray.count > 0){
        if ([self shouldReloadCollectionViewToPreventKnownIssue] || self.collectionView.window == nil) {
            // This is to prevent a bug in UICollectionView from occurring.
            // The bug presents itself when inserting the first object or deleting the last object in a collection view.
            // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
            // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
            // http://openradar.appspot.com/12954582
            [self.collectionView reloadData];
            
        } else {
            //prevent updating too fast
            if(lastUpdated.timeElapsed < 0.5 && cellChangeArray.count == 1){
                [cellChangeArray removeAllObjects];
                return;
            }
            
            //NSLog(@"Updating CollectionView at %@: %@", [NSDate date], cellChangeArray);
            //need to record the time at the beginning
            lastUpdated = [NSDate date];
            
            [self.collectionView performBatchUpdates:^{
                
                for (NSDictionary *change in cellChangeArray)
                {
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                        
                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        switch (type)
                        {
                            case NSFetchedResultsChangeInsert:
                                [self.collectionView insertItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeDelete:
                                [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeUpdate:{
                                //                        if ([obj isEqual:[NSIndexPath indexPathForRow:0 inSection:0]]) {
                                //                            return;
                                //                        }
                                [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                            }
                                break;
                            case NSFetchedResultsChangeMove:
                                [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                                break;
                        }
                    }];
                }
                
            }completion:^(BOOL finished){
                if (finished) {
                    //center when changed
                    static NSTimer *viewCenterTimer;
                    [viewCenterTimer invalidate];
                    viewCenterTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(centerView) userInfo:nil repeats:NO];
                }else{
                    NSLog(@"*** Update of collection view failed");
                }
                
            }];
            
        }
        
        //after reload, we still need to update the view, do not clean the changeArray until updating the view.
        [cellChangeArray removeAllObjects];
    }
}


- (BOOL)shouldReloadCollectionViewToPreventKnownIssue {
    __block BOOL shouldReload = NO;
    for (NSDictionary *change in cellChangeArray) {
        [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSFetchedResultsChangeType type = [key unsignedIntegerValue];
            NSIndexPath *indexPath = obj;
            switch (type) {
                case NSFetchedResultsChangeInsert:
                    if ([self.collectionView numberOfItemsInSection:indexPath.section] == 0) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeDelete:
                    if ([self.collectionView numberOfItemsInSection:indexPath.section] == 1) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeUpdate:
                    shouldReload = NO;
                    break;
                case NSFetchedResultsChangeMove:
                    shouldReload = NO;
                    break;
            }
        }];
    }
    
    return shouldReload;
}

@end

