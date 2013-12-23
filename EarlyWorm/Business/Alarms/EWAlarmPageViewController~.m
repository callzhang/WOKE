//
//  EWDetaledAlarmViewController.m
//  EarlyWorm
//
//  Created by Lei on 9/25/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWAlarmPageViewController.h"
#import "EWAlarmManager.h"
#import "EWAlarmItem.h"
#import "NSDate+Extend.h"

@interface EWAlarmPageViewController ()

@end

@implementation EWAlarmPageViewController
@synthesize alarm;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)editAlarm:(id)sender {
    
}

- (IBAction)OnAlarmSwitchChanged:(UISwitch *)sender {
    // 写入数据库
    [EWAlarmManager.sharedStore setAlarmState:sender.on atIndex:sender.tag];
    [EWAlarmManager.sharedStore saveAlarm];
    NSLog(@"Alarm #%d changed to %hhd", sender.tag, sender.on);
}

- (void)setAlarm:(EWAlarmItem *)a{
    //actions after setting the alarm
    self.alarm = a;
    self.timeText.text = [a.alarmTime date2String];
    self.typeText.text = @"Next";
    int h = ([alarm.alarmTime timeIntervalSinceReferenceDate] - [NSDate timeIntervalSinceReferenceDate])/3600;
    self.timeLeftText.text = [NSString stringWithFormat:@"%d hours left", h];
    self.dateText.text = [alarm.alarmTime date2dayString];
    self.view.backgroundColor = [UIColor clearColor];
}


@end
