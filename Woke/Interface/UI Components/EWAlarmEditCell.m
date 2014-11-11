//
//  EWAlarmEditCell.m
//  EarlyWorm
//
//  Created by Lei on 12/31/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWAlarmEditCell.h"
//#import "EWTaskItem.h"
#import "EWAlarmManager.h"
#import "EWAlarm.h"
#import "NSDate+Extend.h"
//#import "EWCostumTextField.h"
@implementation EWAlarmEditCell
@synthesize alarm;
@synthesize myTime, myStatement;


- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
       
//        self.statement.font = [UIFont fontWithName:@"Lato-Regular.ttf" size:14];
//        self.statement.delegate = self;
//        
//        self.statement.clearButtonMode = UITextFieldViewModeAlways;
//        //self.statement.adjustsFontSizeToFitWidth = YES;
//        self.statement.leftViewMode = UITextFieldViewModeAlways;
//        self.scrollView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
//        //self.scrollView.alpha = 0.3;
        
        CGRect frame = self.frame;
        frame.size.height -= 80;
        self.selectedBackgroundView = [[UIView alloc] initWithFrame: frame];
        self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
        
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self hideKeyboard:self.statement];
    // Configure the view for the selected state
}

//- (void)setTask:(EWTaskItem *)t{
//    if (task == t) {
//        return;
//    }
//    //data
//    task = t;
//    alarm = task.alarm;
//    //alarmOn = self.alarm.state;
//    myTime = self.task.time ;
//   
//    myStatement = self.task.statement;
//    
//    self.statement.text = myStatement;
//    
//    
//    //view
//    self.time.text = [myTime date2timeShort];
//    self.AM.text = [myTime date2am];
//    self.weekday.text = [myTime weekdayShort];
//
//    
//    //NSString *alarmState = alarmOn ? @"ON":@"OFF";
//    //[self.alarmToggle setTitle:alarmState forState:UIControlStateNormal];
//    
//    self.alarmToggle.selected = task.state;
//    [self toggleAlarm:nil];
//}

- (void)setAlarm:(EWAlarm *)a{
    //data
    //task = [[EWAlarmManager sharedInstance] firstTaskForAlarm:a];
    alarm = a;
    myTime = alarm.time;
 
    myStatement = alarm.statement;
    
    //view
    self.time.text = [myTime date2timeShort];
    self.AM.text = [myTime date2am];
    self.weekday.text = [myTime weekdayShort];
    self.statement.text = myStatement;
    //NSString *alarmState = alarmOn ? @"ON":@"OFF";
    //[self.alarmToggle setTitle:alarmState forState:UIControlStateNormal];
    
    self.alarmToggle.selected = alarm.state;
    if (self.alarmToggle.selected) {
        [self.alarmToggle setImage:[UIImage imageNamed:@"On_Btn"] forState:UIControlStateNormal];
    }else{
        [self.alarmToggle setImage:[UIImage imageNamed:@"Off_Btn"] forState:UIControlStateNormal];
    }

}

- (IBAction)toggleAlarm:(UIControl *)sender {
    sender.selected = !sender.selected;
    if (self.alarmToggle.selected) {
        [UIView animateWithDuration:0.5 animations:^(){
        self.time.enabled = YES;
        self.AM.enabled = YES;
       
       
        self.timeStepper.enabled = YES;
        self.timeStepper.tintColor  = [UIColor cyanColor];
            [self.statement setEnabled:YES];
        self.statement.textColor = [UIColor whiteColor];
        [self.alarmToggle setImage:[UIImage imageNamed:@"On_Btn"] forState:UIControlStateNormal];}];
    }else{
        [UIView animateWithDuration:0.5 animations:^(){
        self.time.enabled = NO;
        self.AM.enabled = NO;
        
            [self.statement setEnabled:NO];
        self.timeStepper.enabled = NO;
        self.timeStepper.tintColor  = [UIColor lightGrayColor];
        self.statement.textColor = [UIColor lightGrayColor];
           
        [self.alarmToggle setImage:[UIImage imageNamed:@"Off_Btn"] forState:UIControlStateNormal];
        }];
    }
}



- (IBAction)hideKeyboard:(UITextView *)sender {
    [sender resignFirstResponder];
}

- (IBAction)changeTime:(UIStepper *)sender {
    NSInteger time2add = (NSInteger)sender.value;
    NSDateComponents *comp = [myTime dateComponents];
    if (comp.hour == 0 && comp.minute == 0 && time2add < 0) {
       myTime = [myTime timeByAddingMinutes:60 * 24];
    }else if (comp.hour == 23 && comp.minute == 50 && time2add > 0 ){
       myTime = [myTime timeByAddingMinutes:-60 * 24];
    }
    
    myTime = [myTime timeByAddingMinutes:time2add];
    
    self.time.text = [myTime date2timeShort];
    self.AM.text = [myTime date2am];
    sender.value = 0;//reset to 0
    //DDLogVerbose(@"New value is: %ld, and new time is: %@", (long)time2add, myTime.date2detailDateString);
    [self setNeedsDisplay];
}

- (void)ViewController:(EWRingtoneSelectionViewController *)controller didFinishSelectRingtone:(NSString *)tone{
   
 
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    UIFont *font = [UIFont systemFontOfSize:16];
    CGSize size = [textField.text sizeWithFont:font constrainedToSize:kConstrainedSize lineBreakMode:NSLineBreakByWordWrapping];
    CGRect frame = CGRectMake(0, 0, size.width, textField.frame.size.height);
    textField.frame = frame;
}

@end
