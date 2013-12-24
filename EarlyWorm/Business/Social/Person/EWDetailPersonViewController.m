//
//  EWDetailPersonViewController.m
//  EarlyWorm
//
//  Created by Lei on 9/5/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWDetailPersonViewController.h"
#import "StackMob.h"
// Util
#import "EWUIUtil.h"
#import "MBProgressHUD.h"

// Model
#import "EWPerson.h"
#import "EWTaskItem.h"
#import "EWAlarmItem.h"
#import "EWMediaItem.h"
#import "NSDate+Extend.h"

//manager
#import "EWTaskStore.h"
#import "EWAlarmManager.h"
#import "EWPersonStore.h"
#import "EWMediaStore.h"

//view
#import "EWRecordingViewController.h"

@interface EWDetailPersonViewController ()

@property (nonatomic, strong) UITableView *tableView;

@end

@interface EWDetailPersonViewController (UITableView)<UITableViewDataSource, UITableViewDelegate>
@end

@implementation EWDetailPersonViewController
@synthesize tableView = _tableView;
@synthesize person;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initData];
    [self initView];
}


- (void)initData {
    me = [EWPersonStore sharedInstance].currentUser;
}

- (void)initChartView {
/*
    _chart = [[ShinobiChart alloc] initWithFrame:CGRectMake(0, 184, EWScreenWidth, 150)];
    _chart.title = @"Wake up history";
    _chart.licenseKey = kChartLicenseKey;
    
    //auto resize
    //_chart.autoresizingMask = ~UIViewAutoresizingNone;
    //add a pair ox axes
    SChartNumberAxis *xAxis = [[SChartNumberAxis alloc] init];
    xAxis.title = @"Date";
    
    SChartNumberAxis *yAxis = [[SChartNumberAxis alloc] init];
    yAxis.rangePaddingHigh = @(0.1);
    yAxis.rangePaddingLow = @(0.1);
    yAxis.title = @"Time to wake up";
    // enable gestures
    yAxis.enableGesturePanning = YES;
    yAxis.enableGestureZooming = YES;
    xAxis.enableGesturePanning = YES;
    xAxis.enableGestureZooming = YES;
    _chart.xAxis = xAxis;
    _chart.yAxis = yAxis;
    
    _chart.datasource = self;
    //show legend
    _chart.legend.hidden = (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone);
    
    [self.view addSubview:_chart];*/
}

- (void)setPerson:(EWPerson *)p{
    person = p;
    //tasks: only tasks that turned on
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"state == %@", [NSNumber numberWithBool:YES]];
    tasks = [[person.tasks allObjects] filteredArrayUsingPredicate:predicate];
    tasks = [tasks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
    
    //UI
    self.profilePic.image = person.profilePic;
    self.name.text = person.name;
    self.location.text = person.city;
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

- (void)initView {
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"EWPersonInfoView" owner:self options:nil];
    if (views && views.count > 0) {
        self.view = [views objectAtIndex:0];
    }
    
    //========table for tasks========
    
    NSInteger infoViewHeight = 120;
    //NSInteger chartHeight = 0;//_chart.height;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, infoViewHeight, EWScreenWidth, EWScreenHeight - infoViewHeight) style:UITableViewStyleGrouped];
    _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = kCustomLightGray;
    _tableView.backgroundView = nil;
    [self.view addSubview:_tableView];
    
    //Right side bar button
    if ([me.friends containsObject:person]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(unfriend)];

    }else{
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPerson)];
    }
    
    
    //=========Person=========
    self.person = person;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UI Events
- (IBAction)extProfile:(id)sender{
    NSLog(@"Info clicked");
}

- (void)addPerson{
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add friend"
                                message:[NSString stringWithFormat:@"Add %@ as your friend?", person.name]
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
                //OK
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                me = [EWPersonStore sharedInstance].currentUser;
                [me addFriendsObject:person];
                [[SMClient defaultClient].coreDataStore.contextForCurrentThread saveOnSuccess:^{
                    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                    hud.mode = MBProgressHUDModeCustomView;
                    hud.labelText = @"Added";
                    [hud hide:YES afterDelay:1.5];
                } onFailure:^(NSError *error) {
                    [NSException raise:@"Error saving friendship" format:@"Reason: %@", error.description];
                }];
            }
                break;
                
            default:
                break;
        }
    }else if ([alertView.title isEqualToString:@"Unfriend"]){
        if (buttonIndex == 0) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            me = [EWPersonStore sharedInstance].currentUser;
            [me removeFriendedObject:person];
            [[SMClient defaultClient].coreDataStore.contextForCurrentThread saveOnSuccess:^{
                hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                hud.mode = MBProgressHUDModeCustomView;
                hud.labelText = @"Unfriended";
                [hud hide:YES afterDelay:1.5];
            } onFailure:^(NSError *error) {
                [NSException raise:@"Error saving friendship" format:@"Reason: %@", error.description];
            }];
        }
    }
}

- (void)unfriend{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unfriend"
                                                    message:[NSString stringWithFormat:@"Really unfriend %@?", person.name]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"Cancel", nil];
    [alert show];
}

@end



#pragma mark - TableView DataSource

@implementation EWDetailPersonViewController(UITableView)
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return @"Scheduled alarms";
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //alarm shown in sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return tasks.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return _tableView.rowHeight;
}

//make cell
- (UITableViewCell *)makePersonInfoCellForTableView:(UITableView *)tableView{
    
    static NSString *taskCellIdentifier = @"taskCellIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:taskCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:taskCellIdentifier];
    }
    
    cell.backgroundColor = kCustomLightGray;
    cell.textLabel.font = [UIFont fontWithName:@"Avenir Light" size:20];
    cell.textLabel.textColor = kCustomGray;
    cell.detailTextLabel.textColor = kColorMediumGray;
    cell.detailTextLabel.text = @"Alarm description";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}
//display cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self makePersonInfoCellForTableView:tableView];
    
    EWTaskItem *task = [tasks objectAtIndex:indexPath.row];
    cell.textLabel.text = [task.time date2detailDateString];
    if (task.statement) {
        cell.detailTextLabel.text = task.statement;
    }else{
        cell.detailTextLabel.text = @"No description for this task";
    }
    
    
    return cell;
}
//tap cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    EWRecordingViewController *controller = [[EWRecordingViewController alloc] initWithNibName:nil bundle:nil];
    controller.task = tasks[indexPath.row];
    [self presentViewController:controller animated:YES completion:NULL];
    /*
    //voice message
    EWMediaItem *media = [[EWMediaStore sharedInstance] createMedia];//with ramdom audio
    media.author = [EWPersonStore sharedInstance].currentUser;
    [media addTasksObject:tasks[indexPath.row]];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    EWTaskItem *task = [tasks objectAtIndex:indexPath.row];
    hud.labelText = @"Sending";
    NSLog(@"Audio %@ sent to %@ on %@ successfully", media.audioKey, person.name, [task.time date2dayString]);
    //save
    NSManagedObjectContext *context = [[[SMClient defaultClient] coreDataStore] contextForCurrentThread];
    [context saveOnSuccess:^{
        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
        hud.mode = MBProgressHUDModeCustomView;
        hud.labelText = @"Sent";
        [hud hide:YES afterDelay:1.5];
        [context refreshObject:media mergeChanges:YES];
    } onFailure:^(NSError *error) {
        [NSException raise:@"Unable to send media" format:@"Reason: %@", error.description];
    }];*/
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"Accessory button tapped");
}

@end
