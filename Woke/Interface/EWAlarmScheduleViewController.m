//
//  EWAlarmScheduleViewController.m
//  EarlyWorm
//
//  Created by Lei on 10/18/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWAlarmScheduleViewController.h"
#import "EWTaskStore.h"
#import "EWTaskItem.h"
#import "EWAlarmManager.h"
#import "EWAlarmItem.h"
#import "EWAlarmEditCell.h"
#import "EWPersonStore.h"
#import "UIViewController+Blur.h"

//Util
#import "EWUIUtil.h"

//backend
#import "EWDataStore.h"


static NSString *cellIdentifier = @"scheduleAlarmCell";

@implementation EWAlarmScheduleViewController{
    NSInteger selected;
    NSMutableArray *alarmCells;
}

- (void)viewDidLoad{
    //tableview
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
    UINib *cellNib = [UINib nibWithNibName:@"EWAlarmEditCell" bundle:nil];
    [_tableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
    
    //alpha mask
    [EWUIUtil applyAlphaGradientForView:self.tableView withEndPoints:@[@0.15]];
    
    //header view
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(OnDone)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.title = @"Schedule Alarm";
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    
    //data
    [self initData];
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)initData{
    //data source
    alarms = [EWAlarmManager myAlarms];
    tasks = [EWTaskStore myTasks];
    alarmCells = [[NSMutableArray alloc] initWithCapacity:7];
    selected = 99;
}

#pragma mark - View life cycle
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self setEdgesForExtendedLayout:UIRectEdgeAll];
    
    //schedule alarm and tasks
    //pop up alarmScheduleView
    if (alarms.count != 7 || tasks.count != 7) {
        NSLog(@"%s: Need to check the data", __func__);
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        
        alarms = [[EWAlarmManager sharedInstance] scheduleNewAlarms];//initial alarm
        tasks = [[EWTaskStore sharedInstance] scheduleTasks];
        
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        //view
        [_tableView reloadData];
        
    }

}

//refrash data after edited
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)save{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    for (EWAlarmEditCell *cell in alarmCells) {
        
        if (!cell || !cell.alarm || !cell.task) {
            NSLog(@"*** Skip setting alarm because cell, alarm or task doesn't exist");
            continue;
        }
        //state
        if (cell.alarmToggle.selected != cell.alarm.state) {
            NSLog(@"Change alarm state for %@ to %@", cell.alarm.time.weekday, cell.alarmToggle.selected?@"ON":@"OFF");
            cell.alarm.state = cell.alarmToggle.selected?YES:NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmStateChangedNotification object:self userInfo:@{@"alarm": cell.alarm}];
        }
        //music
        if (![cell.myMusic isEqualToString:cell.alarm.tone] && cell.myMusic != nil) {
            NSLog(@"Music changed to %@", cell.myMusic);
            cell.alarm.tone = cell.myMusic;
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmToneChangedNotification object:self userInfo:@{@"alarm": cell.alarm}];
        }
        //time
        if (![cell.myTime isEqual:cell.task.time]) {
            NSLog(@"Time updated to %@", [cell.myTime date2detailDateString]);
            cell.alarm.time = cell.myTime;
            //save alarm time to user defaults
            [[EWAlarmManager sharedInstance] setSavedAlarmTime:cell.alarm];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmTimeChangedNotification object:self userInfo:@{@"alarm": cell.alarm}];
        }
        //statement
        if (cell.statement.text.length && ![cell.statement.text isEqualToString:cell.task.statement]) {
            cell.task.statement = cell.statement.text;
            
        }
        //save
        [EWDataStore save];
    }
    
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

#pragma mark - UI events
- (void)OnDone{
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    [self save];
}

- (void)OnCancel{
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item{
    
    return YES;
}


#pragma mark - tableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return alarms.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //reusable cell
    EWAlarmEditCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    //data
    if (!cell.task) {
        EWTaskItem *task = tasks[indexPath.row];
        cell.task = task;//alarm set automatically
    }
    
    //breaking MVC pattern to get ringtonVC work
    cell.presentingViewController = self;
    
    //save cell
    alarmCells[indexPath.row] = cell;
    
    //return
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    //CGFloat alpha = indexPath.row%2?0.05:0.06;
    cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	// If our cell is selected, return double height
	if(selected == indexPath.row    ) {
		return 160.0;
	}
	
	// Cell isn't selected so return single height
	return 80.0;
}

//when click one item in table, push view to detail page
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [tableView beginUpdates];
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (selected == indexPath.row) {
        selected = 99;
    }else{
        selected = indexPath.row;
    }
    
    
    [tableView endUpdates];
}



@end
