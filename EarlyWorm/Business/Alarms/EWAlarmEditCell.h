//
//  EWAlarmEditCell.h
//  EarlyWorm
//
//  Created by Lei on 12/31/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWRingtoneSelectionViewController.h"
@class EWAlarmItem, EWTaskItem;

@interface EWAlarmEditCell : UITableViewCell<EWRingtoneSelectionDelegate>
//container
@property (nonatomic, weak) EWTaskItem *task;
@property (nonatomic, weak) EWAlarmItem *alarm;
@property (nonatomic, weak) UIViewController *presentingViewController;
//data
@property (nonatomic) NSDate *myTime;
@property (nonatomic) NSString *myStatement;
@property (nonatomic) BOOL alarmOn;
@property (nonatomic) NSString *myMusic;
//outlet
@property (weak, nonatomic) IBOutlet UIButton *alarmToggle;
@property (weak, nonatomic) IBOutlet UILabel *weekday;
@property (weak, nonatomic) IBOutlet UILabel *time;
@property (weak, nonatomic) IBOutlet UITextField *statement;
@property (weak, nonatomic) IBOutlet UIStepper *timeStepper;
@property (weak, nonatomic) IBOutlet UIButton *music;
//action
- (IBAction)toggleAlarm:(UIButton *)sender;
- (IBAction)changeMusic:(id)sender;
- (IBAction)hideKeyboard:(UITextField *)sender;
- (IBAction)changeTime:(UIStepper *)sender;

@end
