//
//  EWAlarmEditCell.m
//  EarlyWorm
//
//  Created by Lei on 12/31/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWAlarmEditCell.h"
#import "EWTaskItem.h"
#import "EWAlarmItem.h"
#import "NSDate+Extend.h"

@implementation EWAlarmEditCell
@synthesize task, alarm;
@synthesize myTime, myStatement, alarmOn, myMusic;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTask:(EWTaskItem *)t{
    //data
    task = t;
    self.alarm = task.alarm;
    alarmOn = [self.alarm.state boolValue];
    myTime = self.task.time;
    myMusic = self.alarm.tone;
    myStatement = self.task.statement;
    
    //view
    self.time.text = [myTime date2String];
    self.weekday.text = [myTime weekday];
    NSArray *name = [myMusic componentsSeparatedByString:@"."];
    [self.music setTitle:name[0] forState:UIControlStateNormal];
    self.statement.text = myStatement;
    NSString *alarmState = alarmOn ? @"ON":@"OFF";
    [self.alarmToggle setTitle:alarmState forState:UIControlStateNormal];
    
}


- (IBAction)toggleAlarm:(id)sender {
    if (alarmOn) {
        alarmOn = NO;
    } else {
        alarmOn = YES;
    }
    NSString *alarmState = alarmOn ? @"ON":@"OFF";
    [self.alarmToggle setTitle:alarmState forState:UIControlStateNormal];
}

- (IBAction)changeMusic:(id)sender {
    EWRingtoneSelectionViewController *controller = [[EWRingtoneSelectionViewController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:controller];
    controller.delegate = self;
    NSArray *ringtones = ringtoneNameList;
    controller.selected = [ringtones indexOfObject:myMusic];
    [self.presentingViewController presentViewController:nc animated:YES completion:NULL];
}

- (IBAction)hideKeyboard:(UITextField *)sender {
    [sender resignFirstResponder];
}

- (IBAction)changeTime:(UIStepper *)sender {
    NSInteger time2add = (NSInteger)sender.value;
    myTime = [myTime timeByAddingMinutes:time2add];
    self.time.text = [myTime date2String];
    sender.value = 0;//reset to 0
    NSLog(@"New value is: %ld, and new time is: %@", (long)time2add, myTime.date2String);
    [self setNeedsDisplay];
}

- (void)ViewController:(EWRingtoneSelectionViewController *)controller didFinishSelectRingtone:(NSString *)tone{
    myMusic = tone;
    NSArray *name = [myMusic componentsSeparatedByString:@"."];
    [self.music setTitle:name[0] forState:UIControlStateNormal];
}


@end
