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
#import "NSDate+Extend.h"
#import "MBProgressHUD.h"

//backend
#import "EWDataStore.h"
#import "StackMob.h"


static NSString *cellIdentifier = @"scheduleAlarmCell";

@implementation EWAlarmScheduleViewController{
    NSInteger selected;
    NSMutableArray *cellArray;
}

- (void)viewDidLoad{
    //tableview
    CGRect tableFrame = self.view.frame;
    tableFrame.origin.y += MADEL_HEADER_HEIGHT;
    tableFrame.size.height -= MADEL_HEADER_HEIGHT;
    _tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 280, 0);
    [self.view addSubview:_tableView];
    
    //header view
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 30, 18, 30)];
    [backBtn setImage:[UIImage imageNamed:@"back_btn"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(OnDone) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
//    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(230, 30, 80, 30)];
//    [cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
//    [cancelBtn addTarget:self action:@selector(OnCancel) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:cancelBtn];
    
    UINib *cellNib = [UINib nibWithNibName:@"EWAlarmEditCell" bundle:nil];
    [_tableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
    
    //data
    [self initData];
}

- (void)initData{
    //data source
    alarms = EWAlarmManager.sharedInstance.allAlarms;
    tasks = EWTaskStore.sharedInstance.allTasks;
    /*
    if (alarms.count == 0 && tasks.count == 0) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[EWAlarmManager sharedInstance] scheduleAlarm];
        [[EWTaskStore sharedInstance] scheduleTasks];
        [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey: currentUser}];
        alarms = EWAlarmManager.sharedInstance.allAlarms;
        tasks = EWTaskStore.sharedInstance.allTasks;
        [_tableView reloadData];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }*/
    cellArray = [[NSMutableArray alloc] initWithCapacity:7];
    selected = 99;
}

#pragma mark - View life cycle
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

- (void)viewWillDisappear:(BOOL)animated{

    for (EWAlarmEditCell *cell in cellArray) {
        //state
        if (cell.alarmOn != [cell.alarm.state boolValue]) {
            NSLog(@"Change alarm state for %@ to %@", cell.alarm.time.weekday, cell.alarmOn?@"ON":@"OFF");
            cell.alarm.state = [NSNumber numberWithBool:cell.alarmOn];
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
            cell.alarm.time = cell.myTime;//TODO: ask if the time change is once or for all
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmTimeChangedNotification object:self userInfo:@{@"alarm": cell.alarm}];
        }
        //statement
        if (cell.statement.text.length && ![cell.statement.text isEqualToString:cell.task.statement]) {
            cell.task.statement = cell.statement.text;
            
        }
        //save
        [context saveOnSuccess:^{
            //
        } onFailure:^(NSError *error) {
            NSLog(@"Alarms failed to save");
        }];
    }

    [super viewWillDisappear:animated];
}

#pragma mark - UI events
- (void)OnDone{
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    //[self.navigationController popViewControllerAnimated:YES];
    [self.presentingViewController dismissViewControllerWithBlurBackground:self];
}

- (void)OnCancel{
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    //[self.navigationController popViewControllerAnimated:YES];
    [self.presentingViewController dismissViewControllerWithBlurBackground:self];
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
        cell.task = tasks[indexPath.row];
    }
    
    //breaking MVC pattern to get ringtonVC work
    cell.presentingViewController = self;
    //save to list
    cellArray[indexPath.row] = cell;
    //return
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat alpha = indexPath.row%2?0.05:0.06;
    cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:alpha];
    
    EWAlarmEditCell *myCell = (EWAlarmEditCell *)cell;
    if (myCell.alarmOn) {
        //myCell.alarmToggle.backgroundColor = [UIColor colorWithRed:120 green:200 blue:255 alpha:1];
    }
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (selected == indexPath.row) {
        selected = 99;
    }else{
        selected = indexPath.row;
    }
    
    [tableView beginUpdates];
    [tableView endUpdates];
}



@end
