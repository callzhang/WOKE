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

#import "NSDate+Extend.h"

@implementation EWAlarmScheduleViewController
- (id)init{
    self = [super init];
    if(self){
        //data source
        alarms = EWAlarmManager.sharedInstance.allAlarms;
        //view
        self.title = LOCALSTR(@"Schedule Alarm");
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(OnDone)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(OnCancel)];
    }
    return self;
}

- (void)viewDidLoad{
    //tableview
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI events
- (void)OnDone{
    EWAlarmManager.sharedInstance.allAlarms = [alarms mutableCopy];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)OnCancel{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - tableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 7;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"scheduleAlarmCell";
    //reusable cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    //data
    EWAlarmItem *alarm = alarms[indexPath.row];
    cell.textLabel.text = [alarm.time date2String];
    cell.detailTextLabel.text = [alarm.time weekday];
    UISwitch *alarmSwitch = [[UISwitch alloc] init];
    alarmSwitch.on = (BOOL)alarm.state;
    alarmSwitch.onTintColor = kCustomGray;
    [alarmSwitch addTarget:self action:@selector(OnAlarmStateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = alarmSwitch;
    //return
    return cell;
}

//when click one item in table, push view to detail page
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //TODO: expand cell to change details
}

//refrash data after edited
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_tableView reloadData];
}



@end
