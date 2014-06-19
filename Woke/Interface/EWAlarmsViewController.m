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
#import "NGAParallaxMotion.h"

// Manager
#import "EWAlarmManager.h"
#import "EWPersonStore.h"
#import "EWTaskStore.h"

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

//backend


//definition
#define kIndicatorHideTimer            2

@interface EWAlarmsViewController (){
    //NSMutableArray *allPeople;
    NSMutableArray *cellChangeArray;
    NSInteger selectedPersonIndex;
    NSTimer *indicatorHideTimer;
    UICollectionViewCell *cell0;
}

@property (nonatomic, retain) NSFetchedResultsController *fetchController;

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView) name:kPersonLoggedIn object:nil];
        
        //initial value
        people = [[NSUserDefaults standardUserDefaults] objectForKey:@"peopleList"];
        if (!people) people = @[@"Dummy"];
        _alarmPages = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
        cellChangeArray = [NSMutableArray new];
    }
    return self;
}

- (void)refreshView{
    //add observer to myTasks
    [me addObserver:self forKeyPath:@"tasks" options:NSKeyValueObservingOptionNew context:nil];
    //update data and view
    [self initData];
    [self.fetchController performFetch:NULL];
    [self reloadAlarmPage];
    [self centerView];
    
    [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
}

- (void)centerView{
    if([rootViewController.view viewWithTag:kMenuTag]){
        //cancel if popout is present
        return;
    }
    if ([_collectionView numberOfItemsInSection:0]>0) {
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredVertically | UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
    }
    

}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self centerView];
//    [self refreshView];
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
        people = [[EWPersonStore sharedInstance] everyone];
        id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchController.sections[0];
        NSUInteger n = [sectionInfo numberOfObjects];
        if (people.count > n) {
            NSLog(@"Updated user list to %lu", (unsigned long)people.count);
            //[self.fetchController performFetch:NULL];
        }
        
        
    }else{
        alarms = nil;
        tasks = nil;
        [_alarmPages removeAllObjects];
    }
}

- (void)initView {
    
    //collection view
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    //_collectionView.contentInset = UIEdgeInsetsMake(200, 100, 200, 100);
    //[_collectionView registerClass:[EWCollectionPersonCell class] forCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier];
    UINib *nib = [UINib nibWithNibName:@"EWCollectionPersonCell" bundle:nil];
    [_collectionView registerNib:nib forCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier];
    _collectionView.backgroundColor = [UIColor clearColor];
    //UIImageView *bgImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Triangle_Tile"]];
    _collectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Triangle Tile Half"]];
    
    //paging
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _pageView.currentPage = 0;
    _pageView.hidden = YES;
    
    //add blur bar
    UIToolbar *blurBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 478, 320, 90)];
    blurBar.barStyle = UIBarStyleBlack;
    [self.view insertSubview:blurBar aboveSubview:_collectionView];
    
    //load page
    [self reloadAlarmPage];
    
    //parallax
    self.background.parallaxIntensity = -100;
    //self.collectionView.parallaxIntensity = 20;
    
    //indicator center
    self.youIndicator.layer.anchorPoint = CGPointMake(0.5, 0.5);
}



#pragma mark - Fetch Controller
- (NSFetchedResultsController *)fetchController{
    if (fetchController) {
        return fetchController;
    }
    
    //predicate
    //SMPredicate *locPredicate = [SMPredicate predicateWhere:@"lastLocation" isWithin:10 milesOfGeoPoint:me.lastLocation];
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY tasks.time BETWEEN %@", @[[NSDate date], [[NSDate date] timeByAddingMinutes:60]]];
    
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"username IN %@", people];
    
    
    //sort
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
    
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
    
    if (alarms.count == 0 || tasks.count == 0) {
        //empty task and alarm, stop
        
        self.addBtn.hidden = NO;
        self.addBtn.backgroundColor = [UIColor clearColor];
        [self.alarmloadingIndicator stopAnimating];
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
        
        
    }else if(alarms.count<7 || tasks.count < 7* nWeeksToScheduleTask){
        //task or alarm incomplete, schedule
        
        self.addBtn.hidden = YES;
        [self.alarmloadingIndicator startAnimating];
        [[EWAlarmManager sharedInstance] scheduleAlarm];
        [[EWTaskStore sharedInstance] scheduleTasks];
        
        return;
    }else{
        //start loading alarm
        
        self.addBtn.hidden = YES;
        [self.alarmloadingIndicator stopAnimating];
    }
    
    
    
    
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
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Preferences", @"Test sheet", @"Refresh", nil];
    sheet.tag = kOptionsAlert;
    [sheet showFromRect:self.actionBtn.frame inView:self.view animated:YES];
    
}

- (IBAction)showNotification:(id)sender {
    EWNotificationViewController *controller = [[EWNotificationViewController alloc] initWithNibName:nil bundle:nil];
    [self presentViewControllerWithBlurBackground:controller];
}


- (IBAction)scheduleInitialAlarms:(id)sender {
    [self scheduleAlarm];
}

- (IBAction)profile:(id)sender {
    //    if (!me.facebook) {
    //        [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    //        EWLogInViewController *loginVC = [[EWLogInViewController alloc] init];
    //        [loginVC loginInBackground];
    //
    //    }else{
    EWPersonViewController *controller = [[EWPersonViewController alloc] init];
    controller.person = me;
    [self presentViewController:controller animated:YES completion:NULL];
    //    }
    
    
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



#pragma mark - KVO & Notification
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{

    if ([object isKindOfClass:[EWPerson class]]) {

        if ([keyPath isEqualToString:@"tasks"]){
            if (me.tasks.count == 7 || me.tasks.count == 0)
            //if (me.tasks)
            {
                NSLog(@"KVO observed tasks changed");
                tasks = [EWTaskStore myTasks];
                alarms = [EWAlarmManager myAlarms];
                [self reloadAlarmPage];
            }
            
        }else if ([keyPath isEqualToString:@"alarms"]){
            NSLog(@"KVO observed alarms changed");
        }else{
            NSLog(@"KVO observed %@ changed %@", keyPath, change);
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

//        //update background paralex effects
//        float margin = 0.2;
//        float w = sender.contentSize.width + sender.contentInset.left + sender.contentInset.right;
//        float h = sender.contentSize.height + sender.contentInset.top + sender.contentInset.bottom;
//        float x = -(sender.bounds.origin.x + sender.contentInset.left);
//        float y = -(sender.bounds.origin.y + sender.contentInset.top);
//        float percentX = x/(w - self.view.frame.size.width);
//        float percentY = y/(h - self.view.frame.size.height);
//        
//        CGRect frame = self.background.frame;
//        float spanX = frame.size.width - self.view.frame.size.width;
//        float spanY = frame.size.height - self.view.frame.size.height;
//        
//        float x1 = percentX * spanX * (1-2*margin) - spanX * margin;
//        float y1 = percentY * spanY * (1-2*margin) - spanY * margin;
//        
//        frame.origin.x = x1;
//        frame.origin.y = y1;
//        self.background.frame = frame;
        
        //indicator
        static float const maxX = 120;
        static float const maxY = 190;
        
        CGPoint frameCenter = _collectionView.center;
        if (!cell0) {
            cell0 = [self collectionView:_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        }
        CGPoint center = [_collectionView convertPoint:cell0.center toView:self.view];
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
    [self presentViewControllerWithBlurBackground:controller];
    
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
    
    BOOL isMe = NO;
    if ([person.username isEqualToString: me.username]) isMe = YES;

    cell.initial.text = [person.name initial];
    if ([person.username isEqualToString: me.username]) {
        cell.initial.text = @"YOU";
    }
    cell.initial.alpha = 1;
    //cell.profilePic.image = [UIImage imageNamed:@"profile"];
    cell.name = person.name;
    
    //profile
    UIImage *profile = person.profilePic;
    cell.profilePic.image = profile;
    //UI
    cell.alpha = 0.0;
    [UIView animateWithDuration:0.4 animations:^{
        cell.alpha = 1;
    }];
    
    //text
    if (!isMe) cell.initial.alpha = 0;
    
    
    //time
    cell.time.text = @"";
    cell.time.alpha = 0;
    if (!isMe) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            EWTaskItem *nextValidTask = [[EWTaskStore sharedInstance] nextValidTaskForPerson:person];
            if (nextValidTask) {
                NSString *timeLeft = [nextValidTask.time timeLeft];
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.time.text = timeLeft;
                    [UIView animateWithDuration:0.4 animations:^{
                        cell.time.alpha = 1;
                    }];
                });
            }
        });
    }
    
    //location
    cell.distance.text = @"";
    cell.distance.alpha = 0;
    if (!isMe && person.lastLocation && me.lastLocation) {
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CLLocation *loc0 = me.lastLocation;
        CLLocation *loc1 = person.lastLocation;
        
        CLLocationDistance distance = [loc0 distanceFromLocation:loc1]/1000;
        //dispatch_async(dispatch_get_main_queue(), ^{
        cell.distance.text = [NSString stringWithFormat:@"%.1lf km", distance];
        [UIView animateWithDuration:0.4 animations:^{
            cell.distance.alpha = 1;
        }];
        //});
        //});
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
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
        
         EWPersonViewController *controller = [[EWPersonViewController alloc] initWithNibName:nil bundle:nil];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
//        [[UINavigationBar appearance] setTintColor:[UIColor clearColor]];
        [[UINavigationBar appearance] setBarTintColor:[UIColor clearColor]];
       
        controller.person = person;
        [self presentViewControllerWithBlurBackground:navController];
        [weakMenu closeMenu];
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
        [self presentViewControllerWithBlurBackground:controller];
        [weakMenu closeMenu];
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
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
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
    if (cellChangeArray.count > 0)
    {
        
        if ([self shouldReloadCollectionViewToPreventKnownIssue] || self.collectionView.window == nil) {
            // This is to prevent a bug in UICollectionView from occurring.
            // The bug presents itself when inserting the first object or deleting the last object in a collection view.
            // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
            // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
            // http://openradar.appspot.com/12954582
            [self.collectionView reloadData];
            
        } else {
            
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
                            case NSFetchedResultsChangeUpdate:
                                [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeMove:
                                [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                                break;
                        }
                    }];
                }
            } completion:^(BOOL finished){
                if (finished) {
                    //NSLog(@"Updates for collection view completed");
                }else{
                    NSLog(@"*** Update of collection view failed");
                }
                
            }];
        }
    }
    
    [cellChangeArray removeAllObjects];
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

