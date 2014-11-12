//
//  EWAlarmEditCell.h
//  EarlyWorm
//
//  Created by Lei on 12/31/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWRingtoneSelectionViewController.h"
#define kConstrainedSize CGSizeMake(10000,40)//字体最大
@class EWAlarm;
@class EWCostumTextField;
@interface EWAlarmEditCell : UITableViewCell<EWRingtoneSelectionDelegate,UITextFieldDelegate>
//container
//@property (nonatomic) BOOL alarmEnable;
@property (strong, nonatomic) IBOutlet UITextView *statementText;
//@property (nonatomic) EWTaskItem *task;
@property (nonatomic) EWAlarm *alarm;
@property (nonatomic, weak) UIViewController *presentingViewController;
//data
@property (nonatomic) NSDate *myTime;
@property (nonatomic) NSString *myStatement;
//@property (nonatomic) BOOL alarmOn;
@property (strong, nonatomic) IBOutlet UITextField *statement;

//outlet
@property (weak, nonatomic) IBOutlet UIButton *alarmToggle;
@property (weak, nonatomic) IBOutlet UILabel *weekday;
@property (weak, nonatomic) IBOutlet UILabel *time;

@property (weak, nonatomic) IBOutlet UIStepper *timeStepper;

@property (weak, nonatomic) IBOutlet UILabel *AM;
//action
- (IBAction)toggleAlarm:(UIControl *)sender;

- (IBAction)hideKeyboard:(UITextField *)sender;
- (IBAction)changeTime:(UIStepper *)sender;



@end
