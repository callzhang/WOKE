//
//  EWAlarmPageView.m
//  EarlyWorm
//
//  Created by Lei on 9/25/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWAlarmPageView.h"
#import "EWAlarmManager.h"
#import "EWAlarmItem.h"
#import "NSDate+Extend.h"
#import "EWPerson.h"
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWWakeUpViewController.h"
#import "EWAppDelegate.h"
#import "EWMediaItem.h"
#import "EWWakeUpManager.h"
#import "EWSleepViewController.h"

@interface EWAlarmPageView (){
    NSTimer *changeTimeTimer;
}

@end

@implementation EWAlarmPageView
@synthesize task, alarm;
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
    
    //timer
    changeTimeTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(changeTimeLeftLabel) userInfo:nil repeats:YES];
    
}


- (void)dealloc{
    @try {
        [self stopObserveTask];
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:kTaskDeleteNotification object:nil];
        NSLog(@"Alarm page deallocated, KVO & Observer removed");
    }
    @catch (NSException *exception) {
        NSLog(@"*** Alarm page unable to remove task observer: %@",exception);
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
    alarm.state = sender.selected;
    
    //broadcast
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskStateChangedNotification object:alarm userInfo:nil];
    NSLog(@"Task on %@ changed to %@", task.time.weekday, (sender.selected?@"ON":@"OFF"));
    
    [EWDataStore save];
}

- (IBAction)playMessage:(id)sender {
    //test function
#ifdef DEBUG
    if (task.medias.count) {
        ///EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] initWithTask:self.task];
        //[rootViewController presentViewControllerWithBlurBackground:controller];
        [EWWakeUpManager presentWakeUpViewWithTask:self.task];
    }
#endif
}


- (void)setTask:(EWTaskItem *)t{
    //unsubscribe previous task if possible
    
//    self.timeText.font = [UIFont fontWithName:@"Lane - Narrow" size:64];
    if (task) {
        if (![task.objectId isEqualToString:t.objectId]) {
            [self stopObserveTask];
        }else{
            return;
        }
    }
    //Observer dealloc is handled by SFObservers
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTaskDeletion:) name:kTaskDeleteNotification object:nil];
    
    //setting the hours left
    task = t;
    alarm = task.alarm;
    self.alarmState.selected = t.state;
    if (self.alarmState.selected) {
        [self.alarmState setImage:[UIImage imageNamed:@"On_Btn"] forState:UIControlStateNormal];
    }else{
        [self.alarmState setImage:[UIImage imageNamed:@"Off_Btn"] forState:UIControlStateNormal];
    }
    self.timeText.text = [t.time date2timeShort];
    self.AM.text = [t.time date2am];
    self.descriptionText.text = t.statement ?: alarm.statement;
    
 
    [self changeTimeLeftLabel];//mq  changed 2014-06-12
    
    NSInteger mCount = task.medias.count;
    
    if (mCount > 0) {
        [self.messages setTitle:[NSString stringWithFormat:@"%lu voice tones", (unsigned long)task.medias.count] forState:UIControlStateNormal];
    }else{
        [self.messages setTitle:@"" forState:UIControlStateNormal];
    }
    
    
    
    
    //test
    //self.dateText.hidden = YES;
    //self.typeText.hidden = YES;
    
    //kvo <= KVO not working because it constantly updates the value
    [task addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:NULL];
    [task addObserver:self forKeyPath:@"medias" options:NSKeyValueObservingOptionNew context:NULL];
    [task addObserver:self forKeyPath:@"time" options:NSKeyValueObservingOptionNew context:NULL];
    [task addObserver:self forKeyPath:@"statement" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)setAlarm:(EWAlarmItem *)a{
    self.alarmState.selected = a.state;
}

#pragma mark - NOTIFICATION

- (void)handleTaskDeletion:(NSNotification *)notification{
    id sender = [notification object];
    if (!sender) {
        NSLog(@"*** task should be contained in notification");
        return;
    }
    NSAssert([sender isKindOfClass:[EWTaskItem class]], @"Target is not task item, check code!");
    EWTaskItem *t = (EWTaskItem *)sender;
    if ([t.objectId isEqualToString:task.objectId]) {
        [self stopObserveTask];
    }
    
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (![object isEqual:task]) {
        NSLog(@"*** Received task change that not belongs to this alarm page, check observer set up!");
        return;
    }
    
    
    if ([object isKindOfClass:[EWTaskItem class]]) {
        //TODO: dispatch different tasks for each updates
        if ([keyPath isEqualToString:@"state"]) {

            self.alarmState.selected = task.state;
            if (self.alarmState.selected) {
                [self.alarmState setImage:[UIImage imageNamed:@"On_Btn"] forState:UIControlStateNormal];
            }else{
                [self.alarmState setImage:[UIImage imageNamed:@"Off_Btn"] forState:UIControlStateNormal];
            }
            [self.alarmState setNeedsDisplay];
            //NSLog(@"%s Task on %@ chenged to %@", __func__ , task.time.weekday, task.state?@"YES":@"NO");
            
            
        }else if ([keyPath isEqualToString:@"medias"]){
            
            NSInteger nMedia = task.medias.count;
            
            if (nMedia == 0) {
                [self.messages setTitle:@"" forState:UIControlStateNormal];
            }else{
#ifdef DEBUG
                [self.messages setTitle:[NSString stringWithFormat:@"%ld voice tones", (long)nMedia] forState:UIControlStateNormal];
#endif
            }
            
        }else if ([keyPath isEqualToString:@"time"]){
            
            self.timeText.text = [task.time date2timeShort];
            self.AM.text = [task.time date2am];
            [self changeTimeLeftLabel];
        }else if ([keyPath isEqualToString:@"statement"]){
        
            self.descriptionText.text = task.statement;
            
        }else{
            NSLog(@"@@@ Unhandled task %@ change: %@", keyPath, change);
        }
        [self setNeedsDisplay];
    }
}

- (void)stopObserveTask{
    
    NSLog(@"About to remove KVO to task (%@)", task.time.weekday);
    
    @try {
        [task removeObserver:self forKeyPath:@"state"];
        [task removeObserver:self forKeyPath:@"medias"];
        [task removeObserver:self forKeyPath:@"time"];
        [task removeObserver:self forKeyPath:@"statement"];
        NSLog(@"Removed KVO to task (%@)", task.time.weekday);
    }
    @catch (NSException *exception) {
        id observants = [task observationInfo];
        NSLog(@"Failed to remove observer %@ with observation info: %@",self , observants);
    }
    
}
#pragma mark - ChangeTimeLeftLabel

- (void)changeTimeLeftLabel
{
    if (!task) {
        return;
    }
    //self.timeLeftText.text = task.time.timeLeft;

    float h = -task.time.timeElapsed/3600;
    if (h < 0) {
        self.timeLeftText.text = @"Just alarmed";
    }else if(h<24){
        self.timeLeftText.text = [NSString stringWithFormat:@"%@ left", [task.time timeLeft]];
    }else{
        self.timeLeftText.text = task.time.weekday;
    }
    
}
@end
