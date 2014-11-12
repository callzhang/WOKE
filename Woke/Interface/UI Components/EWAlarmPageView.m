//
//  EWAlarmPageView.m
//  EarlyWorm
//
//  Created by Lei on 9/25/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWAlarmPageView.h"
#import "EWAlarmManager.h"
#import "EWAlarm.h"
#import "NSDate+Extend.h"
#import "EWPerson.h"
//#import "EWTaskItem.h"
//#import "EWTaskManager.h"
#import "EWWakeUpViewController.h"
#import "EWAppDelegate.h"
#import "EWMedia.h"
#import "EWWakeUpManager.h"
#import "EWSleepViewController.h"

@interface EWAlarmPageView (){
    NSTimer *changeTimeTimer;
}

@end

@implementation EWAlarmPageView
@synthesize alarm;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize{
    self.backgroundColor = [UIColor clearColor];
    if (self.alarmState.selected) {
        [self.alarmState setImage:[UIImage imageNamed:@"On_Btn"] forState:UIControlStateNormal];
    }else{
        [self.alarmState setImage:[UIImage imageNamed:@"Off_Btn"] forState:UIControlStateNormal];
    }
	
    
}


- (void)dealloc{
    @try {
        [self stopObserveTask];
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:kTaskDeleteNotification object:nil];
        DDLogVerbose(@"Alarm page deallocated, KVO & Observer removed");
    }
    @catch (NSException *exception) {
        DDLogVerbose(@"*** Alarm page unable to remove task observer: %@",exception);
    }
    [changeTimeTimer invalidate];
}


#pragma mark - UI actions
- (IBAction)editAlarm:(id)sender {
    [self.delegate scheduleAlarm];
}

- (IBAction)OnAlarmSwitchChanged:(UIButton *)sender {
    //change task not alarm
//    EWAlarmItem *a = task.alarm;
//    a.state = [NSNumber numberWithBool:sender.on];
    
    //reverse the state
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.alarmState setImage:[UIImage imageNamed:@"On_Btn"] forState:UIControlStateNormal];
    }else{
        [self.alarmState setImage:[UIImage imageNamed:@"Off_Btn"] forState:UIControlStateNormal];
    }
    [self setNeedsDisplay];
    
    //set task state
    alarm.state = @(sender.selected);
    
    //broadcast
    DDLogInfo(@"Alarm on %@ changed to %@", alarm.time.weekday, (sender.selected?@"ON":@"OFF"));
    
    [EWSync save];
}




- (void)setAlarm:(EWAlarm *)a{
    if (alarm) {
        if (![alarm.objectId isEqualToString:a.objectId]) {
            [self stopObserveTask];
        }else{
            return;
        }
    }
    //Observer dealloc is handled by SFObservers
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTaskDeletion:) name:kTaskDeleteNotification object:nil];
    
    //setting the hours left
    alarm = a;
    self.alarmState.selected = a.state;
    if (self.alarmState.selected) {
        [self.alarmState setImage:[UIImage imageNamed:@"On_Btn"] forState:UIControlStateNormal];
    }else{
        [self.alarmState setImage:[UIImage imageNamed:@"Off_Btn"] forState:UIControlStateNormal];
    }
    self.timeText.text = [alarm.time date2timeShort];
    self.AM.text = [alarm.time date2am];
    self.descriptionText.text = alarm.statement;
    
    [self changeTimeLeftLabel];//mq  changed 2014-06-12
    
    [self.messages setTitle:@"" forState:UIControlStateNormal];
    
    
    //test
    //self.dateText.hidden = YES;
    //self.typeText.hidden = YES;
    
    //kvo <= KVO not working because it constantly updates the value
    [alarm addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:NULL];
    [alarm addObserver:self forKeyPath:@"time" options:NSKeyValueObservingOptionNew context:NULL];
    [alarm addObserver:self forKeyPath:@"statement" options:NSKeyValueObservingOptionNew context:NULL];
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (![object isEqual:alarm]) {
        DDLogVerbose(@"*** Received alarm change that not belongs to this alarm page, check observer set up!");
        return;
    }
    
	
	//TODO: dispatch different tasks for each updates
	if ([keyPath isEqualToString:@"state"]) {

		self.alarmState.selected = alarm.state;
		if (self.alarmState.selected) {
			[self.alarmState setImage:[UIImage imageNamed:@"On_Btn"] forState:UIControlStateNormal];
		}else{
			[self.alarmState setImage:[UIImage imageNamed:@"Off_Btn"] forState:UIControlStateNormal];
		}
		[self.alarmState setNeedsDisplay];
		//DDLogVerbose(@"%s Task on %@ chenged to %@", __func__ , task.time.weekday, task.state?@"YES":@"NO");

		
	}else if ([keyPath isEqualToString:@"time"]){
		
		self.timeText.text = [alarm.time date2timeShort];
		self.AM.text = [alarm.time date2am];
		[self changeTimeLeftLabel];
		
	}else if ([keyPath isEqualToString:@"statement"]){
	
		self.descriptionText.text = alarm.statement;
		
	}else{
		
		DDLogVerbose(@"@@@ Unhandled task %@ change: %@", keyPath, change);
	}
	[self setNeedsDisplay];
}

- (void)stopObserveTask{
    
    DDLogVerbose(@"About to remove KVO to alarm (%@)", alarm.time.weekday);
    
    @try {
        [alarm removeObserver:self forKeyPath:@"state"];
        [alarm removeObserver:self forKeyPath:@"medias"];
        [alarm removeObserver:self forKeyPath:@"time"];
        [alarm removeObserver:self forKeyPath:@"statement"];
        DDLogVerbose(@"Removed KVO to task (%@)", alarm.time.weekday);
    }
    @catch (NSException *exception) {
        id observants = [alarm observationInfo];
        DDLogVerbose(@"Failed to remove observer %@ with observation info: %@",self , observants);
    }
    
}
#pragma mark - ChangeTimeLeftLabel

- (void)changeTimeLeftLabel
{
    if (!alarm) {
        return;
    }
    //self.timeLeftText.text = task.time.timeLeft;

    float h = alarm.time.timeIntervalSinceNow/3600;
    if (h < 0) {
        self.timeLeftText.text = @"Just alarmed";
		return;
    }else if(h<24){
        self.timeLeftText.text = [NSString stringWithFormat:@"%@ left", [alarm.time timeLeft]];
    }else{
        self.timeLeftText.text = alarm.time.weekday;
    }
	
	//timer
    [NSTimer scheduledTimerWithTimeInterval:alarm.time.timeIntervalSinceNow/10 target:self selector:@selector(changeTimeLeftLabel) userInfo:nil repeats:NO];
}
@end
