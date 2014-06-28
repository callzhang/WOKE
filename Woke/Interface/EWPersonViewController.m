//
//  EWPersonViewController.m
//  EarlyWorm
//
//  Created by Lei on 9/5/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWPersonViewController.h"
#import "UINavigationController+Blur.h"
// Util
#import "EWUIUtil.h"
#import "UIViewController+Blur.h"

// Model
#import "EWPerson.h"
#import "EWTaskItem.h"
#import "EWAlarmItem.h"
#import "EWMediaItem.h"
#import "NSDate+Extend.h"
#import "EWAchievement.h"

//manager
#import "EWTaskStore.h"
#import "EWAlarmManager.h"
#import "EWPersonStore.h"
#import "EWMediaStore.h"
#import "EWStatisticsManager.h"

//view
#import "EWRecordingViewController.h"
#import "EWLogInViewController.h"
#import "EWTaskHistoryCell.h"
#import "EWCollectionPersonCell.h"
#import "EWAppDelegate.h"
#import "EWMyFriendsViewController.h"
#import "EWMyProfileViewController.h"
#define kProfileTableArray              @[@"Friends", @"People woke her up", @"People her woke up", @"Last Seen", @"Next wake-up time", @"Wake-ability Score"]


static NSString *taskCellIdentifier = @"taskCellIdentifier";
NSString *const profileCellIdentifier = @"ProfileCell";
@interface EWPersonViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>

@end

@interface EWPersonViewController (UICollectionViewAdditions) <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end


@implementation EWPersonViewController
@synthesize person, taskTableView;
//@synthesize collectionView;
@synthesize tabView;

- (EWPersonViewController *)initWithPerson:(EWPerson *)p{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.person = p;
       
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
     profileItemsArray = kProfileTableArray;
    
    //login event
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn) name:kPersonLoggedIn object:nil];
    
    //navigation
     self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MoreButton"] style:UIBarButtonItemStylePlain target:self action:@selector(more:)];
//    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(close:)];// 图片变小了
                                             //========table for tasks========
    taskTableView.dataSource = self;
    taskTableView.delegate = self;
    taskTableView.backgroundColor = [UIColor clearColor];
    taskTableView.backgroundView = nil;
    UINib *taskNib = [UINib nibWithNibName:@"EWTaskHistoryCell" bundle:nil];
    [taskTableView registerNib:taskNib forCellReuseIdentifier:taskCellIdentifier];
    
    //tab view
    //tabView.layer.backgroundColor = [[UIColor colorWithWhite:1.0f alpha:0.5f] CGColor];
    tabView.selectedSegmentIndex = 0;//initial tab
    
    //default state
    [EWUIUtil applyHexagonMaskForView:self.profilePic];
    self.name.text = @"";
    self.location.text = @"";
    self.statement.text = @"";
    
    
    
    
    [taskTableView reloadData];
    
}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    
    if (person) {
        [self initData];
        [self initView];
    }
}

- (void)initData {
    if (person) {
        tasks = [[EWTaskStore sharedInstance] pastTasksByPerson:person];
        stats = [[EWStatisticsManager alloc] init];
        stats.person = person;
    }
}


- (void)initView {
    
    //======= Person =======
    if (person) {
        /*
         *  add friends button
         */
        if (person.isMyFriend) {
            [self.addFriendButton setImage:[UIImage imageNamed:@"FriendedIcon"] forState:UIControlStateDisabled];
            [self.addFriendButton setEnabled:NO];
        }

        
        
        if (person.isMe && !person.facebook) {
            self.loginBtn.hidden = NO;
        }else{
            self.loginBtn.hidden = YES;
        }
        [taskTableView reloadData];
        //UI
        self.profilePic.image = person.profilePic;
        self.name.text = person.name;
        self.location.text = person.city;
        if (person.lastLocation && !person.isMe) {
            CLLocation *loc0 = me.lastLocation;
            CLLocation *loc1 = person.lastLocation;
            float distance = [loc0 distanceFromLocation:loc1]/1000;
            if (person.city) {
                self.location.text =[NSString stringWithFormat:@"%@ | ",person.city];
                self.location.text = [self.location.text stringByAppendingString:[NSString stringWithFormat:@"%1.f km",distance]];
            }
            else
            {
                self.location.text = [NSString stringWithFormat:@"%1.f km",distance];
            }
//            self.location.text = [NSString stringWithFormat:@"%@ | %.1f km", person.city, distance];
          
        }
        
        //statement
        EWTaskItem *t = tasks.firstObject;
        if (person.statement) {
            self.statement.text = person.statement;
        }else if (t.statement){
            self.statement.text = t.statement;
        }else{
            self.statement.text = @"No statement written by this owner";
        }
        
        [self.view setNeedsDisplay];
    }
}



- (void)setPerson:(EWPerson *)p{
    //add observer to update when person updates
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePersonChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[EWDataStore currentContext]];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    person = p;
    [self initData];
    [self initView];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    if (p.updatedAt.isOutDated) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [p refreshInBackgroundWithCompletion:^{
            [self initData];
            [self initView];
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        }];
    }
    
}

#pragma mark - UI Events
- (IBAction)extProfile:(id)sender{
    
    if (person.isMe) {
        EWMyProfileViewController *controller = [[EWMyProfileViewController alloc] init];
        
        [self.navigationController pushViewControllerWithBlur:controller];
        
        return;
    }
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add friend", @"Send Voice Greeting", nil];
    [as showInView:self.view];
}

- (IBAction)close:(id)sender {
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
}

- (IBAction)login:(id)sender {
    EWLogInViewController *loginVC = [[EWLogInViewController alloc] init];
    [loginVC connect:nil];
}

- (IBAction)tabTapped:(UISegmentedControl *)sender {
    NSInteger idx = [sender selectedSegmentIndex];
    switch (idx) {
        case 0:
            taskTableView.hidden = NO;
            //collectionView.hidden = YES;
            //[collectionView reloadData];
            break;
            
        case 1:
            taskTableView.hidden = NO;
            //collectionView.hidden = YES;
            //[taskTableView reloadData];
            break;
            
        case 2:
            taskTableView.hidden = YES;
            //collectionView.hidden = NO;
            //[collectionView reloadData];
            break;
            
        default:
            break;
    }
}

//The action view (alert)
- (void)addPerson{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add friend"
                                message:[NSString stringWithFormat:@"Add %@ as your friend?", person.name]
                                delegate:self
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:@"Cancel", nil];
    [alert show];
    
}

- (void)unfriend{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unfriend"
                                                    message:[NSString stringWithFormat:@"Really unfriend %@?", person.name]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"Cancel", nil];
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if ([alertView.title isEqualToString:@"Add friend"]) {
        switch (buttonIndex) {
            case 0:
            {
                //friend
                [me addFriendsObject:person];
                [EWDataStore save];
                [self.view showSuccessNotification:@"Added"];
            }
                break;
                
            default:
                break;
        }
    }else if ([alertView.title isEqualToString:@"Unfriend"]){
        //unfriend
        if (buttonIndex == 0) {
            [me removeFriendsObject:person];
            [EWDataStore save];
            [self.view showSuccessNotification:@"Unfriended"];
            
        }
    }
}


- (IBAction)more:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Close" destructiveButtonTitle:@"Flag" otherButtonTitles:@"Friend history", nil];
    [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

@end



#pragma mark - TableView DataSource

@implementation EWPersonViewController(UITableView)
/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    EWTaskItem *t = tasks[section];
    return [t.time date2MMDD];
}*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //alarm shown in sections
//    return tasks.count;
    NSInteger tapItem =  [tabView selectedSegmentIndex];
    switch (tapItem) {
        case 0:
            
            return 1;
#warning need update
        case 1:
            return 0;
        default:
            return 0;
            break;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return profileItemsArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;//TODO
}



//display cell
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //static NSString *CellIdentifier = @"cell";
    
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:profileCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:profileCellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    switch (indexPath.row) {
        case 0:
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)person.friends.count];
//            NSLog(@"%ld",person.friends.count);
            break;
            
        default:
            break;
    }
    
    
    cell.textLabel.text = [profileItemsArray objectAtIndex:indexPath.row];
    
    
    return cell;
    
//    EWTaskHistoryCell *cell = [table dequeueReusableCellWithIdentifier:taskCellIdentifier];
//    if (!cell) {
//        cell = [[EWTaskHistoryCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:taskCellIdentifier];
//        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
//        cell.backgroundColor = [UIColor clearColor];
//    }
//
//    
//    EWTaskItem *task = [tasks objectAtIndex:indexPath.section];
//    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:task.time];
//    cell.dayOfMonth.text = [NSString stringWithFormat:@"%ld", (long)components.day];
//    //month
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"MMM"];
//    NSString *MON = [formatter stringFromDate:task.time];
//    cell.month.text = MON;
//    
//    if (task.completed) {
//        cell.wakeTime.text = [task.completed date2String];
//        cell.taskInfo.text = [NSString stringWithFormat:@"Woke up by %lu users", (unsigned long)task.waker.count];
//        
//    }else{
//        cell.wakeTime.text = [task.time date2String];
//        cell.taskInfo.text = @"Failed";
//    }
//    
//    return cell;
}
//change cell bg color
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor clearColor];
}

//tap cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSInteger tapItem =  [tabView selectedSegmentIndex];//if we selectnum is 
    UIViewController *controller ;
    switch (indexPath.row) {
        case 0:
        {
            EWMyFriendsViewController *tempVc= [[EWMyFriendsViewController alloc] initWithPerson:person];
            controller = tempVc;
            break;
        }
            
        default:
        {
            controller = [[EWRecordingViewController alloc] initWithPerson:person];

            break;
        }
    }
    
    [UIView  beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.75];
    [self.navigationController pushViewController:controller animated:NO];
    
    //选择动画
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:NO];
    [UIView commitAnimations];
    
//        [self presentViewControllerWithBlurBackground:controller];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"Accessory button tapped");
}


#pragma mark - USER LOGIN EVENT
- (void)userLoggedIn{
    if (self.person.isMe) {
        NSLog(@"PersonVC: user logged in, starting refresh");
        [self initData];
        [self initView];
    }
}

@end



#pragma mark -
@implementation EWPersonViewController (UICollectionViewAdditions)

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (section != 0) return 0;
    if (tabView.selectedSegmentIndex == 0) {
        //friends
        return person.friends.count;//me.achievements.count;
    }else if(tabView.selectedSegmentIndex == 2){
        //achievements
        return person.achievements.count;
    }
    
    NSLog(@"Selected tab for wake up history");
    return 0;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kCollectionViewCellWidth, kCollectionViewCellHeight);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    EWCollectionPersonCell *cell = [cView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier forIndexPath:indexPath];
    if (tabView.selectedSegmentIndex == 0) {
        //friends
        EWPerson *friend = [[person.friends allObjects] objectAtIndex:indexPath.row];
        cell.profilePic.image = friend.profilePic;
        cell.initial.text = [friend.name initial];
        
    }else if (tabView.selectedSegmentIndex == 2){
        //achievements
        EWAchievement *a = [[person.achievements allObjects] objectAtIndex:indexPath.row];
        cell.initial.text = a.name;
        if (a.image) {
            cell.profilePic.image = a.image;
        }else{
            cell.profilePic.image = [UIImage imageNamed:@"music_note"];
        }
    }
    return cell;
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        //add friend
        if (person != me) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [me addFriendsObject:person];
            [EWDataStore save];
            [self.view showSuccessNotification:@"Added"];
            
        }
    }else if (buttonIndex == 1) {
        //send voice greeting
        EWRecordingViewController *controller = [[EWRecordingViewController alloc] initWithPerson:person];
        [self presentViewControllerWithBlurBackground:controller];
    }
}

@end
