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

//backend
#import "StackMob.h"

@interface EWAlarmsViewController (){
    //NSMutableArray *allPeople;
    NSMutableArray *cellChangeArray;
    NSInteger selectedPersonIndex;
    NSTimer *recoilTimer;
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
        
        //launch with local notif
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentWakeUpView:) name:UIApplicationLaunchOptionsLocalNotificationKey object:nil];
        
        //listen to user log in, and updates its view
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView) name:kPersonLoggedIn object:nil];
        
        //Task: only new task will update the view, other changes is observed in alarmPageView
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView) name:kTaskNewNotification object:nil];
        
        //initial value
        people = [[NSUserDefaults standardUserDefaults] objectForKey:@"peopleList"];
        if (!people) people = @[@"Dummy"];
        _alarmPages = [@[@NO, @NO, @NO, @NO, @NO, @NO, @NO] mutableCopy];
        cellChangeArray = [NSMutableArray new];
    }
    return self;
}

- (void)refreshView{
    [self initData];
    [self.fetchController performFetch:NULL];
    [self reloadAlarmPage];
    [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
    [self centerView];
}

- (void)centerView{
    
    [UIView animateWithDuration:0.5 animations:^{
        float w = _collectionView.contentSize.width + _collectionView.contentInset.left + _collectionView.contentInset.right;
        float h = _collectionView.contentSize.height + _collectionView.contentInset.top + _collectionView.contentInset.bottom;
        
        CGRect bounds = _collectionView.bounds;
        bounds.origin.x = w/2 - _collectionView.contentInset.left - self.view.center.x;
        bounds.origin.y = h/2 - _collectionView.contentInset.top - self.view.center.y;
        _collectionView.bounds = bounds;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self centerView];
}

- (void)initData {
    
    //init alarm page container
    if (currentUser) {
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
        SMGeoPoint *location;
        id locData = currentUser.lastLocation;
        if ([locData isKindOfClass:[NSDictionary class]]) {
            location = (SMGeoPoint *)locData;
        }else{
            
            location =  [NSKeyedUnarchiver unarchiveObjectWithData:locData];
            //currentUser.lastLocation = location;
            //[[EWDataStore currentContext] saveOnSuccess:NULL onFailure:NULL];
            //NSLog(@"Unarchived location: %@", location);
        }
        
        [EWServer getPersonAlarmAtTime:[NSDate date] location:location completion:^(NSArray *results) {
            //assign result
            NSMutableArray *newPeople = [NSMutableArray new];
            for (EWPerson *p in results) {
                [newPeople addObject:p.username];
            }
            people = newPeople;
            [[NSUserDefaults standardUserDefaults] setObject:people forKey:@"peopleList"];
            if (people.count == 0 && currentUser) {
                NSLog(@"*** no result from around me fetch, please check!");
            }
            //reflesh
            BOOL success = [self.fetchController performFetch:NULL];
            if (!success) {
                NSLog(@"Fetch failed");
            }
        }];
        
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
    _collectionView.contentInset = UIEdgeInsetsMake(200, 100, 200, 100);
    //[_collectionView registerClass:[EWCollectionPersonCell class] forCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier];
    UINib *nib = [UINib nibWithNibName:@"EWCollectionPersonCell" bundle:nil];
    [_collectionView registerNib:nib forCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier];
    _collectionView.backgroundColor = [UIColor clearColor];
    //UIImageView *bgImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Triangle_Tile"]];
    _collectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Triangle_Tile"]];
    
    //paging
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _pageView.currentPage = 0;
    _pageView.hidden = YES;
    
    //add blur
    UIToolbar *blurBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 478, 320, 90)];
    blurBar.barStyle = UIBarStyleBlack;
    [self.view insertSubview:blurBar aboveSubview:_collectionView];
    
    
    //add button
    self.addBtn.hidden = (tasks.count == 0) ? NO:YES;
    self.addBtn.backgroundColor = [UIColor clearColor];
    
    //load page
    [self reloadAlarmPage];
}



#pragma mark - Fetch Controller
- (NSFetchedResultsController *)fetchController{
    if (fetchController) {
        return fetchController;
    }
    
    //predicate
    //'to-many key not allowed here'
    //SMPredicate *locPredicate = [SMPredicate predicateWhere:@"lastLocation" isWithin:10 milesOfGeoPoint:currentUser.lastLocation];
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY tasks.time BETWEEN %@", @[[NSDate date], [[NSDate date] timeByAddingMinutes:60]]];
    
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"username IN %@", people];
    
    
    //sort
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"lastSeenDate" ascending:NO];
    
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
        NSLog(@"Failed to fetch everyone: %@", err);
    }
    
    return fetchController;
}



#pragma mark - ScrollView
- (void)reloadAlarmPage {
    
    
    if (alarms.count == 0 || tasks.count == 0) {
        self.addBtn.hidden = NO;
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
    }
    
    _pageView.numberOfPages = tasks.count;
    //determine if scroll need flash
    bool flash = NO;
    if ([_alarmPages[0] isEqual: @NO]){
        NSLog(@"First time, need flash scroll");
        flash = YES;
    }
    
    self.addBtn.hidden = YES;
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


- (IBAction)scheduleInitialAlarms:(id)sender {
    [self scheduleAlarm];
}

- (IBAction)profile:(id)sender {
    //    if (!currentUser.facebook) {
    //        [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    //        EWLogInViewController *loginVC = [[EWLogInViewController alloc] init];
    //        [loginVC loginInBackground];
    //
    //    }else{
    EWPersonViewController *controller = [[EWPersonViewController alloc] init];
    controller.person = currentUser;
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





#pragma mark - KVO & Notification
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
//
//    if ([object isKindOfClass:[EWPerson class]]) {
//
//        if ([keyPath isEqualToString:@"profilePicKey"]) {
//            NSLog(@"Observed profile pic changed for user: %@", [(EWPerson *)object name]);
//            //update cell
//            NSInteger i = [allPeople indexOfObject:currentUser];
//            EWCollectionPersonCell *cell = (EWCollectionPersonCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
//            cell.profilePic.image = currentUser.profilePic;
//
//        }else if ([keyPath isEqualToString:@"tasks"]){
//            NSLog(@"KVO observed tasks changed");
//        }else if ([keyPath isEqualToString:@"alarms"]){
//            NSLog(@"KVO observed alarms changed");
//        }else{
//            NSLog(@"KVO observed change %@", change);
//        }
//    }
//}

//- (void)updateProfilePic:(NSNotification *)notif{
//    EWPerson *person = (EWPerson *)([notif.object isKindOfClass:[EWPerson class]]?notif.object:notif.userInfo[@"person"]);
//    NSInteger row = [allPeople indexOfObject:person];
//    EWCollectionPersonCell *cell;
//    if (row < allPeople.count) {
//        cell = (EWCollectionPersonCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
//    }
//    cell.profilePic.image = person.profilePic;
//    //[_collectionView reloadData];
//    [_collectionView setNeedsDisplay];
//}

#pragma mark - UIScrollViewDelegate
- (NSInteger)currentPage{
    CGFloat pageWidth = _scrollView.frame.size.width;
    return lroundf(_scrollView.contentOffset.x / pageWidth);
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    if (sender.tag == kCollectionViewTag) {
        float margin = 0.3;
        float w = sender.contentSize.width + sender.contentInset.left + sender.contentInset.right;
        float h = sender.contentSize.height + sender.contentInset.top + sender.contentInset.bottom;
        float x = -(sender.bounds.origin.x + sender.contentInset.left);
        float y = -(sender.bounds.origin.y + sender.contentInset.top);
        float percentX = x/(w - self.view.frame.size.width);
        float percentY = y/(h - self.view.frame.size.height);
        
        CGRect frame = self.background.frame;
        float spanX = frame.size.width - self.view.frame.size.width;
        float spanY = frame.size.height - self.view.frame.size.height;
        
        float x1 = percentX * spanX * (1-2*margin) - spanX * margin;
        float y1 = percentY * spanY * (1-2*margin) - spanY * margin;
        
        frame.origin.x = x1;
        frame.origin.y = y1;
        self.background.frame = frame;
        
        if ([recoilTimer isValid]) {
            [recoilTimer invalidate];
        }
        recoilTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(centerView) userInfo:nil repeats:NO];
    }
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
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewControllerWithBlurBackground:nav];
    
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
    
    [cell applyHexagonMask];
    //[cell.loadingIndicator startAnimating];
    
    //Data
    EWPerson *person = [self.fetchController objectAtIndexPath:indexPath];
    cell.initial.text = [person.name initial];
    if ([person.username isEqualToString: currentUser.username]) {
        cell.initial.text = @"YOU";
    }
    cell.initial.alpha = 1;
    cell.profilePic.image = [UIImage imageNamed:@"profile"];
    cell.name = person.name;
    
    dispatch_async([EWDataStore sharedInstance].coredata_queue, ^{
        //Data
        
        UIImage *profile = person.profilePic;
        if (profile) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.white.alpha = 1;
                [UIView animateWithDuration:0.2 animations:^{
                    cell.white.alpha = 0;
                }];
                
                //UI
                cell.profilePic.image = profile;
                
                //text
                if (![person.username isEqualToString: currentUser.username]) {
                    cell.initial.alpha = 0;
                }
                
                //[cell.loadingIndicator stopAnimating];
                [cell setNeedsDisplay];
                
            });
        }
        
    });
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //get cell
    EWCollectionPersonCell *cell = (EWCollectionPersonCell *)[collectionView cellForItemAtIndexPath:indexPath];
    selectedPersonIndex = indexPath.row;
    [recoilTimer invalidate];

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
        controller.person = person;
        [self presentViewControllerWithBlurBackground:controller];
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

