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
#import "EWCostumTextField.h"

static NSString *cellIdentifier = @"scheduleAlarmCell";

@implementation EWAlarmScheduleViewController{
    NSInteger selected;
    NSMutableArray *alarmCells;
    NSArray *tasks;
}

- (void)viewDidLoad{
    //tableview
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 240, 0);
    UINib *cellNib = [UINib nibWithNibName:@"EWAlarmEditCell" bundle:nil];
    [_tableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
    
    //alpha mask
    [EWUIUtil applyAlphaGradientForView:self.tableView withEndPoints:@[@0.15]];
    
    //header view
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Confirm Button"] style:UIBarButtonItemStylePlain target:self action:@selector(OnDone)];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Close Button"] style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
    [EWUIUtil addTransparantNavigationBarToViewController:self withLeftItem:rightBarButtonItem rightItem:leftBarButtonItem];
    self.title = @"Schedule Alarms";
    
    //data
    [self initData];
    
    //add task observer
    [[EWTaskStore sharedInstance] addObserver:self forKeyPath:@"isSchedulingTask" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[EWTaskStore class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([keyPath isEqualToString:@"isSchedulingTask"]) {
                [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                if (![EWTaskStore sharedInstance].isSchedulingTask) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self initData];
                        [self.tableView reloadData];
                    });
                }else{
                    NSLog(@"Schedule View detecte task schedule");
                    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                }
            }
        });
        
    }
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)initData{
    //data source
    //alarms = [EWAlarmManager myAlarms];
    tasks = [EWTaskStore myTasks];
    alarmCells = [[NSMutableArray alloc] initWithCapacity:7];
    selected = 99;
}

- (void)save{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    BOOL hasChanges = NO;
    
    //for (EWAlarmEditCell *cell in alarmCells) {
    for (NSInteger i=0; i<tasks.count; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
        EWAlarmEditCell *cell = (EWAlarmEditCell *)[self.tableView cellForRowAtIndexPath:path];
        if (!cell ) {
            cell = (EWAlarmEditCell *)[self tableView:_tableView cellForRowAtIndexPath:path];
        }
        
        EWTaskItem *task = tasks[i];
        EWAlarmItem *alarm = task.alarm;
        
        
        //state
        if (cell.alarmToggle.selected != alarm.state) {
            NSLog(@"Change alarm state for %@ to %@", alarm.time.weekday, cell.alarmToggle.selected?@"ON":@"OFF");
            alarm.state = cell.alarmToggle.selected?YES:NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmStateChangedNotification object:alarm userInfo:@{@"alarm": alarm}];
            hasChanges = YES;
        }

        //time
        if (![cell.myTime isEqual:task.time]) {
            NSAssert(cell.myTime.weekdayNumber == alarm.time.weekdayNumber, @"Updating time to wrong alarm. (cell:%@, alarm:%@ and task:%@", cell.myTime, alarm.time, task.time);
            NSLog(@"Time updated to %@", [cell.myTime date2detailDateString]);
            alarm.time = cell.myTime;
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmTimeChangedNotification object:alarm userInfo:@{@"alarm": alarm}];
            hasChanges = YES;
        }
        
        //statement
        if (cell.statement.text.length && ![cell.statement.text isEqualToString:task.statement]) {
            NSString *statement = [NSString stringWithFormat:@"%@", cell.statement.text];
            alarm.statement = statement;
            task.statement = statement;
            //hasChanges = YES;
        }
        
        //save
        [EWDataStore save];
    }
    
    if (hasChanges) {
        //save alarm time to user defaults
        [[EWAlarmManager sharedInstance] setSavedAlarmTimes];
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
    return tasks.count;
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
		return 130.0;
	}
	
	// Cell isn't selected so return single height
	return 80.0;
}

//when click one item in table, push view to detail page
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
//    EWAlarmEditCell * cell =(EWAlarmEditCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
//    if (!cell.alarmToggle.selected) {
//        return;
//    }
    [UIView animateWithDuration:0.01 animations:^{
           [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }];
    
    [tableView beginUpdates];
    
    //highlight the seleted cell
 
    
    
    
    if (selected == indexPath.row) {
        selected = 99;
    }else{
        selected = indexPath.row;
    }
    
    
    [tableView endUpdates];
}


- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:selected inSection:0];
    EWAlarmEditCell *cell = (EWAlarmEditCell *)[self.tableView cellForRowAtIndexPath:path];
    [cell hideKeyboard:cell.statement];
}



@end
