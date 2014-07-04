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
#import "UINavigationController+Blur.h"

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
#import "EWNotificationManager.h"

//view
#import "UIView+HUD.h"
#import "EWRecordingViewController.h"
#import "EWLogInViewController.h"
#import "EWTaskHistoryCell.h"
#import "EWCollectionPersonCell.h"
#import "EWAppDelegate.h"
#import "EWMyFriendsViewController.h"
#import "EWMyProfileViewController.h"
#import "EWActivityHeadView.h"
#define kProfileTableArray              @[@"Friends", @"People woke her up", @"People I woke up", @"Last Seen", @"Next wake-up time", @"Wake-ability Score"]


static NSString *taskCellIdentifier = @"taskCellIdentifier";
NSString *const profileCellIdentifier = @"ProfileCell";
NSString *const activitiyCellIdentifier = @"ActivityCell";
@interface EWPersonViewController()
- (void)showSuccessNotification:(NSString *)alert;

@end

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
        _canSeeFriendsDetail = YES;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
     profileItemsArray = kProfileTableArray;
    
    //login event
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn) name:kPersonLoggedIn object:nil];
    
    //navigation
    [EWUIUtil addTransparantNavigationBarToViewController:self withLeftItem:nil rightItem:nil];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MoreButton"] style:UIBarButtonItemStylePlain target:self action:@selector(more:)];
    
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

- (void)refresh{
    [self initData];
    [self initView];
}


- (void)initView {
    if (!person) return;
    //======= Person =======
    
    
    if (!person.isMe) {//other user
        self.loginBtn.hidden = YES;
        if (person.isFriend) {
            [self.addFriend setImage:[UIImage imageNamed:@"FriendedIcon"] forState:UIControlStateNormal];
        }else if (person.friendWaiting){
            [self.addFriend setImage:[UIImage imageNamed:@"Add Friend Button"] forState:UIControlStateNormal];
        }else if(person.friendPending){
            [self.addFriend setImage:[UIImage imageNamed:@"Add Friend Button"] forState:UIControlStateNormal];
            self.addFriend.alpha = 0.2;
        }else{
            [self.addFriend setImage:[UIImage imageNamed:@"Add Friend Button"] forState:UIControlStateNormal];
        }
    }else{//self
        if(!person.facebook){
            [self.loginBtn setTitle:@"Log in" forState:UIControlStateNormal];
            self.addFriend.hidden = YES;
        }else{
            self.addFriend.hidden = YES;
            [self.loginBtn setTitle:@"Edit" forState:UIControlStateNormal];
        }
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
    if (person.isFriend) {
        //is friend: do nothing
        return;
    } else if(person.friendWaiting){
        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Accept friend", @"Send Voice Greeting", nil];
        [as showInView:self.view];
        return;
    }else if (person.friendPending){
        [[[UIAlertView alloc] initWithTitle:@"Friendship pending" message:@"You have already requested friendship to this person." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }else{
        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add friend", @"Send Voice Greeting", nil];
        [as showInView:self.view];
    }
}

- (IBAction)close:(id)sender {
    if (_canSeeFriendsDetail&& [[self.navigationController viewControllers] objectAtIndex:0] == self) {
        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];

    }
    [self.navigationController popViewControllerWithBlur];
}

- (IBAction)login:(id)sender {
    
    if (person.facebook) {
        EWMyProfileViewController *controller = [[EWMyProfileViewController alloc] init];
        
        [self.navigationController pushViewControllerWithBlur:controller];
        
        return;
    }
    
    EWLogInViewController *loginVC = [[EWLogInViewController alloc] init];
    [loginVC connect:nil];
}

- (IBAction)tabTapped:(UISegmentedControl *)sender {
    
    [taskTableView reloadData];
    

}


- (IBAction)more:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Close" destructiveButtonTitle:nil otherButtonTitles: nil];
    if (person.isMe) {
        [sheet addButtonWithTitle:@"Edit"];
        if (DEV_TEST) {
            [sheet addButtonWithTitle:@"Send test friend request"];
        }
    }else{
        [sheet addButtonWithTitle:@"Flag"];
        sheet.destructiveButtonIndex = 0;
        [sheet addButtonWithTitle:@"Send friend request"];
        if (person.isFriend) {
            [sheet addButtonWithTitle:@"Friend history"];
            [sheet addButtonWithTitle:@"Send Voice Greeting"];
        }else if (DEV_TEST) {
            [sheet addButtonWithTitle:@"Send Voice Greeting"];
        }
    }
    
    [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

#pragma mark - Actionsheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"Add friend"]) {
        
        //friend
        [me addFriendsObject:person];
        [EWDataStore save];
        [EWNotificationManager sendFriendRequestNotificationToUser:person];
        
    }else if ([title isEqualToString:@"Unfriend"]){
        
        //unfriend
        [me removeFriendsObject:person];
        [person removeFriendsObject:me];
        [EWDataStore save];
        [self.view showSuccessNotification:@"Unfriended"];
        
    }else if ([title isEqualToString:@"Accept friend"]){
        
        [me addFriendsObject:person];
        [EWDataStore save];
        [EWNotificationManager sendFriendAcceptNotificationToUser:person];
        [self showSuccessNotification:@"Added"];
        
    }else if ([title isEqualToString:@"Send Voice Greeting"]){
        [self sendVoice];
    }else if ([title isEqualToString:@"Flag"]){
        //
    }else if ([title isEqualToString:@"Friendship history"]){
        //
    }else if ([title isEqualToString:@"Send test friend request"]){
        [EWNotificationManager sendFriendRequestNotificationToUser:me];
    }
        
    [self initView];
}

- (void)showSuccessNotification:(NSString *)alert{
    [self initView];
    [self.view showNotification:alert WithStyle:hudStyleSuccess];
}

- (void)sendVoice{
    EWRecordingViewController *controller = [[EWRecordingViewController alloc] initWithPerson:self.person];
    [self.navigationController pushViewController:controller animated:YES];
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
        case 1:
            return tasks.count;
        default:
            return 0;
            break;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tabView.selectedSegmentIndex==0) {
         return profileItemsArray.count;
    }
    else
    {
//        NSArray *taskArray = person
//        EWTaskItem *task  = EWTask;
        return 1;
        
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tabView.selectedSegmentIndex == 0) {
        return 45;
    }
    else
    {
        return 50;
    }
    
    
}



//display cell
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //static NSString *CellIdentifier = @"cell";
  
    if (tabView.selectedSegmentIndex == 1) {
          NSLog(@"%ld,%ld",indexPath.section,indexPath.row);
        
        EWTaskItem *task = tasks[indexPath.section];
        UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:activitiyCellIdentifier];
        if (!cell) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:activitiyCellIdentifier];
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = [NSString stringWithFormat:@"Woke up at %@ %@ by %ld people",[task.completed timeInString],[task.completed date2am],[task.medias count]];
            
                break;
            case 1:
//                cell.textLabel.text = [NSString stringWithFormat:@"Woke up %d people",task.]
                break;
            default:
                break;
        }
        return cell;
    }
    
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:profileCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:profileCellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    cell.textLabel.text = [profileItemsArray objectAtIndex:indexPath.row];
    if (indexPath.row== 1&&[person.gender isEqualToString:@"male"]) {
        
        cell.textLabel.text = @"People woke him up";
    }
    
    switch (indexPath.row) {
        case 0:
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)person.friends.count];
//            NSLog(@"%ld",person.friends.count);
            break;
        case 1:
        {
            NSArray *receivedMedias = [[EWMediaStore sharedInstance] mediasForPerson:person];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)receivedMedias.count];
        }
            break;
        case 2:
        {
            NSArray *medias = [[EWMediaStore sharedInstance] mediaCreatedByPerson:person];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)medias.count];
           
        }
             break;
        case 3:
        {
            NSDate *date = person.updatedAt;
            cell.detailTextLabel.text = [date date2MMDD] ;
            break;
        }
        case 4://next task time
        {
            NSDate *date = person.cachedInfo[kNextTaskTime];
            cell.detailTextLabel.text = [[date time2HMMSS] stringByAppendingString:[date date2am]];
            break;
        }
        case 5://wake-ability
        {
            cell.detailTextLabel.text =  [NSString stringWithFormat:@"%ld",(long) stats.wakability];
            break;
        }
            
        default:
            break;
    }
    
    
    return cell;
}
//change cell bg color
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor clearColor];
}

//tap cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSInteger tapItem =  [tabView selectedSegmentIndex];//if we selectnum is
    if (tapItem == 1) {
        return;
    }
    
    UIViewController *controller ;
    switch (indexPath.row) {
        case 0:
        {
            if ([self.navigationController.viewControllers count] <kMaxPersonNavigationConnt) {
                EWMyFriendsViewController *tempVc= [[EWMyFriendsViewController alloc] initWithPerson:person];
                tempVc.cellSelect =_canSeeFriendsDetail;
                controller = tempVc;
                //[self.navigationController pushViewController:controller animated:YES]
                [self.navigationController pushViewControllerWithBlur:controller];
                break;
            }
      
        }
        
    }
    
    //选择动画
//    [UIView  beginAnimations:nil context:NULL];
//    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
//    [UIView setAnimationDuration:0.75];
//    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:NO];
//    [UIView commitAnimations];
    
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tabView.selectedSegmentIndex == 0) {
        return  [[UIView alloc] initWithFrame:CGRectZero];
    }
    EWActivityHeadView *headView = [[EWActivityHeadView alloc]initWithFrame:CGRectMake(0, 0, 320, 80)];
    EWTaskItem *task = tasks[section];
    headView.titleLabel.text = [task.time time2MonthDotDate];
    
    return headView;
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
