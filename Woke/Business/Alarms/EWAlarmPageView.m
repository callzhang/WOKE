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
#import "EWEditAlarmViewController.h"
#import "EWPerson.h"
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWWakeUpViewController.h"
#import "EWAppDelegate.h"
#import "EWDataStore.h"
#import "EWMediaItem.h"

@interface EWAlarmPageView ()

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
    self = [super initWithCoder:aDecoder];ç
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
    }ç
}


- (void)dealloc{
    @try {
        [self stopObserveTask];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kTaskDeleteNotification object:nil];
        NSLog(@"Alarm page deallocated, KVO & Observer removed");
    }
    @catch (NSException *exception) {
        NSLog(@"*** Alarm page unable to remove task observer: %@",exception);
    }
}


#pragma mark - UI actions
- (IBAction)editAlarm:(id)sender {ç
    NSLog(@"Edit task: %@", task.time);
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
    task.state = sender.selected;
    [[EWDataStore currentContext] saveOnSuccess:nil onFailure:^(NSError *error) {
        NSLog(@"Task state failed to save");
        sender.selected = !sender.selected;
        [self setNeedsDisplay];
    }];
    
    //broadcast
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskStateChangedNotification object:self userInfo:@{@"task": task}];
    NSLog(@"Task on %@ changed to %@", task.time.weekday, (sender.selected?@"ON":@"OFF"));
}

- (IBAction)playMessage:(id)sender {
    if (task.medias.count) {
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] initWithTask:self.task];
        [rootViewController presentViewControllerWithBlurBackground:controller];
    }
}

- (void)setTask:(EWTaskItem *)t{
    //unsubscribe previous task if possible
    if (task) {
        if ([task.ewtaskitem_id isEqualToString:t.ewtaskitem_id]) {
            //same task
            return;
        }else{
            //different task
            @try {
                [self stopObserveTask];
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception.description);
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTaskDeletion:) name:kTaskDeleteNotification object:nil];
    
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
    self.descriptionText.text = t.statement ? t.statement : alarm.alarmDescription;
    
    float h = ([t.time timeIntervalSinceReferenceDate] - [NSDate timeIntervalSinceReferenceDate])/3600;

    if (h < 0) {
        self.timeLeftText.text = @"Just alarmed";
    }else if(h < 24){
        self.timeLeftText.text = [NSString stringWithFormat:@"%.1f hours left", h];
    }else{
        self.timeLeftText.text = [t.time weekday];
    }
    
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
        sender = notification.userInfo[kPushTaskKey];
    }
    if ([sender isKindOfClass:[EWTaskItem class]]) {
        EWTaskItem *t = (EWTaskItem *)sender;
        if ([t.ewtaskitem_id isEqualToString:task.ewtaskitem_id]) {
            [self stopObserveTask];
        }
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
            
            self.alarmState.selected = [(NSNumber *)change[NSKeyValueChangeNewKey] boolValue];
            if (self.alarmState.selected) {
                [self.alarmState setImage:[UIImage imageNamed:@"On_Btn"] forState:UIControlStateNormal];
            }else{
                [self.alarmState setImage:[UIImage imageNamed:@"Off_Btn"] forState:UIControlStateNormal];
            }
            [self.alarmState setNeedsDisplay];
            NSLog(@"%s Task on %@ chenged to %@", __func__ , task.time.weekday, self.alarmState.selected?@"YES":@"NO");
            
            
        }else if ([keyPath isEqualToString:@"medias"]){
            
            NSInteger nMedia = task.medias.count;
            
            if (nMedia == 0) {
                [self.messages setTitle:@"" forState:UIControlStateNormal];
            }else{
                [self.messages setTitle:[NSString stringWithFormat:@"%ld voice tones", (long)nMedia] forState:UIControlStateNormal];
            }
            
        }else if ([keyPath isEqualToString:@"time"]){
            
            self.timeText.text = [task.time date2timeShort];
            self.AM.text = [task.time date2am];
            
        }else{
            
            NSLog(@"@@@ Unhandled task %@ change: %@", keyPath, change);
            
        }
        [self setNeedsDisplay];
    }
    
}

- (void)stopObserveTask{
    [task removeObserver:self forKeyPath:@"state"];
    [task removeObserver:self forKeyPath:@"medias"];
    [task removeObserver:self forKeyPath:@"time"];
    [task removeObserver:self forKeyPath:@"statement"];
    NSLog(@"Removed KVO to task (%@)", task.time.weekday);
}

@end
