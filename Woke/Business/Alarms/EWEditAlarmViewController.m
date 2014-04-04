//
//  EWEditAlarmViewController.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-8.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWEditAlarmViewController.h"

// Util
#import "EWUIUtil.h"
#import "EWIO.h"
#import "NSDate+Extend.h"
#import "EWDefines.h"

//data manager
#import "EWAlarmManager.h"
#import "EWTaskStore.h"

// Model
//#import "EWPersonStore.h"
#import "EWPerson.h"
#import "NSString+Extend.h"
#import "EWAlarmItem.h"
#import "EWTaskItem.h"

// Business
#import "EWRingtoneSelectionViewController.h"

// View
#import "EWTextFieldCell.h"

//backend
#import "StackMob.h"
#import "EWDataStore.h"

static NSString *g_textFieldCellIdentifier = @"textFieldCell";

@interface EWEditAlarmViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) NSArray *dataSource;

@end

@interface EWEditAlarmViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>
@end

@interface EWEditAlarmViewController (UIActionSheet) <UIActionSheetDelegate>
@end


@implementation EWEditAlarmViewController
@synthesize tableView = _tableView;
@synthesize datePicker = _datePicker;
@synthesize dataSource = _dataSource;
@synthesize alarm = _alarm;
@synthesize task = _task;

- (void)initData {
    _dataSource = @[LOCALSTR(@"Alarm_Name"), @"Ambient sound"];

}

- (void)initView {
    self.view.backgroundColor = kCustomLightGray;
    
    //bar button item
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(OnCancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(OnDone)];
    
    // 时间选择器
    _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, EWScreenWidth*0.5, 100)];
    _datePicker.datePickerMode = UIDatePickerModeTime;
    [_datePicker addTarget:self action:@selector(OnDatePickerChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_datePicker];
    
    NSDate *time = newTime;
    if (!time) {
        //get current time if new
        time = [NSDate date];
        [_datePicker setDate:time];
        [self OnDatePickerChanged];
    }
    //set init time for datePicker
    _datePicker.Date = time;
    
    // TableView
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _datePicker.bottom-100, EWScreenWidth, EWContentHeight - _datePicker.height+100) style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundView = nil;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.showsHorizontalScrollIndicator = NO;
    _tableView.showsVerticalScrollIndicator = NO;
    
    UINib *nib = [UINib nibWithNibName:@"EWTextFieldCell" bundle:nil];
    [_tableView registerNib:nib forCellReuseIdentifier:g_textFieldCellIdentifier];
    [self.view addSubview:_tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initData];
    [self initView];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//setter
- (void)setTask:(EWTaskItem *)task{
    //newTime = task.time;
    // _datePicker.Date = newTime;
    newDescrition = task.statement;
    _task = task;
    self.alarm = task.alarm;
}

- (void)setAlarm:(EWAlarmItem *)alarm{
    NSArray *weekdayArray = weekdays;
    self.title = weekdayArray[[alarm.time weekdayNumber]];//LOCALSTR(@"EditAlarm");
    //original value
    newTime = alarm.time;
    _datePicker.date = alarm.time;
    newTone = alarm.tone;
    newState = [alarm.state boolValue];
    _alarm = alarm;
}

#pragma mark - RingtongSelectionDelegate
- (void)ViewController:(EWRingtoneSelectionViewController *)controller didFinishSelectRingtone:(NSString *)tone{
    //set ringtone
    newTone = tone;
}

#pragma mark - UI Events

- (void)OnCancel {
    
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)OnDone {
    //save alarm
    if (![newTime isEqual:self.alarm.time]) {
        self.alarm.time = newTime;//TODO
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmTimeChangedNotification object:self userInfo:@{@"alarm": self.alarm}];
    }
    if (newState != [self.alarm.state boolValue]) {
        self.alarm.state = [NSNumber numberWithBool:newState];//TODO
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmStateChangedNotification object:self userInfo:@{@"alarm": self.alarm}];
    }
    //text
    //newDescrition = alarmDesText.text;
    self.task.statement = newDescrition;
    
    //tone
    if (![newTone isEqualToString:_alarm.tone]) {
        _alarm.tone = newTone;
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmToneChangedNotification object:self userInfo:@{@"alarm": self.alarm}];
        self.alarm.tone = newTone;
    }
    
    
    // Finished
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    //save
    [[EWDataStore currentContext] saveOnSuccess:^{
        NSLog(@"Alarm updated");
    } onFailure:^(NSError *error) {
        [NSException raise:@"Alarm save failed" format:@"Reason: %@", error.description];
    }];
    
    //Notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmChangedNotification object:_alarm userInfo:nil];
}

- (void)OnDelete {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:LOCALSTR(@"Alarm_Is_To_Delete")
        delegate:self cancelButtonTitle:LOCALSTR(@"Common_Cancel")
             destructiveButtonTitle:LOCALSTR(@"Common_OK")
              otherButtonTitles:nil];
    [actionSheet showInView:self.view];
}

- (void)OnDatePickerChanged {
    newTime = _datePicker.date;
}

- (void)OnAlarmImportanceSwitchChanged:(UISwitch *)sender {
    //newImportant = sender.on;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    //NSLog(@"touchesBegan:withEvent:");
    newDescrition = alarmDesText.text;
    [_tableView reloadData];
    //[self.view endEditing:YES];
    //[super touchesBegan:touches withEvent:event];
    [alarmDesText resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:( UITextField *) textField {
    
    newDescrition = textField.text;
    [_tableView reloadData];
    [textField resignFirstResponder];
    
    return YES;
}

@end

@implementation EWEditAlarmViewController (UITableView)

#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1; //no delete section
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return _dataSource.count;
            break;
        default:
            break;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row==0) {
        return 80;
    }
    return 50;
}

- (UITableViewCell *)makeDeleteAlarmCellForTableView:(UITableView *)tableView {
    static NSString *deleteAlarmCellIdentifier = @"DeleteAlarm";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:deleteAlarmCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DeleteAlarm"];
        cell.backgroundColor = kCustomWhite;
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.textLabel.text = LOCALSTR(@"Alarm_Delete");
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont systemFontOfSize:18];
    }    
    return cell;
}

- (UITableViewCell *)makeAlarmCellForTableView:(UITableView *)tableView{
    static NSString *alarmCellIdentifier = @"alarmCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:alarmCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:alarmCellIdentifier];
        cell.backgroundColor = kCustomWhite;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = kCustomGray;
    }
    
    return cell;
}

- (EWTextFieldCell *)makeTextFieldCellForTableView:(UITableView *)tableView {
    
    EWTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:g_textFieldCellIdentifier];
    if (!cell) {
        cell = [[EWTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:g_textFieldCellIdentifier];
        alarmDesText = cell.textField;
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //make cell
    if (indexPath.section == 1) {
        return [self makeDeleteAlarmCellForTableView:tableView];
    }
    
    //detail
    switch (indexPath.row) {
        case 0:{ //details
            EWTextFieldCell *cell = [self makeTextFieldCellForTableView:tableView];
            cell.title.text = [_dataSource objectAtIndex:indexPath.row];
            cell.textField.text = newDescrition;
            cell.textField.delegate = self;
            return cell;
            break;
        }
        /*
        case 1:{ //repeat
            UITableViewCell *cell = [self makeAlarmCellForTableView:tableView];
            cell.textLabel.text = [_dataSource objectAtIndex:indexPath.row];
            cell.detailTextLabel.text = _alarm.alarmRepeat;
            return cell;
            break;
        }
            
        case 2:{ //important
            UITableViewCell *cell = [self makeAlarmCellForTableView:tableView];
            cell.textLabel.text = [_dataSource objectAtIndex:indexPath.row];
            UISwitch *alarmSwitch = [[UISwitch alloc] init];
            alarmSwitch.on = _alarm.important;
            alarmSwitch.onTintColor = kCustomGray;
            [alarmSwitch addTarget:self action:@selector(OnAlarmImportanceSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = alarmSwitch;
            return cell;
            break;
        } */
        case 1:{ //sound
            UITableViewCell *cell = [self makeAlarmCellForTableView:tableView];
            cell.textLabel.text = [_dataSource objectAtIndex:indexPath.row];
            if (newTone == nil) {
                //cell.detailTextLabel.text = @"Drive";
            }else{
                NSArray *array = [newTone componentsSeparatedByString:@"."];
                
                cell.detailTextLabel.text = array[0];
            }
        
            return cell;
            break;
        }
        default:
            break;
    }
    
    return nil;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case 0:{
            switch (indexPath.row) {
                case 0: {
                    
                }
                    break;
                    /*
                case 1: {
                    EWWeekDayPickerTableViewController *dayPickerVC = [[EWWeekDayPickerTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    dayPickerVC.repeatString = _alarm.alarmRepeat;
                    dayPickerVC.delegate = self;
                    [self.navigationController pushViewController:dayPickerVC animated:YES];
                }
                    break;
                case 2: {
                    
                    rep = NSWeekdayCalendarUnit;
                    [_alarmInfo setValue:rep forKey:KEY_REPEAT];
                     
                }
                    break;
                     */
                case 1: {
                    EWRingtoneSelectionViewController *ringtoneVC = [[EWRingtoneSelectionViewController alloc] init];
                    NSArray *ringtones = ringtoneNameList;
                    NSInteger selected = [ringtones indexOfObject:newTone];
                    if (selected<0) {
                        selected = 0;
                    }
                    ringtoneVC.selected = selected;
                    
                    ringtoneVC.delegate = self;
                    [self.navigationController pushViewController:ringtoneVC animated:YES];
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 1: {
            [self OnDelete];
        }
            break;
        default:
            break;
    }
    [tableView reloadData];
}

@end


@implementation EWEditAlarmViewController (UIActionSheet)
//old
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        // Delete alarm item
        
        [[EWDataStore currentContext] deleteObject:_alarm];
        [[EWDataStore currentContext] saveOnSuccess:^{
            NSLog(@"Alarm deleted");
        } onFailure:^(NSError *error) {
            [NSException raise:@"Error in deleting alarm" format:@"Reason: %@",error.description];
        }];
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

@end

