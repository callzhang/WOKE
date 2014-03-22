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

@interface EWAlarmPageView ()

@end

@implementation EWAlarmPageView
@synthesize task, alarm;
@synthesize delegate;

- (id)init {
    self = [super init];
    if (self) {
        NSArray *nibViews =  [[NSBundle mainBundle] loadNibNamed:@"EWAlarmPage" owner:self options:nil];
        
        for (UIView *view in nibViews) {
            [self addSubview:view];
        }
        //Notifications
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedPage:) name:kAlarmChangedNotification object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedPage:) name:kTaskTimeChangedNotification object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedPage:) name:kTaskStateChangedNotification object:nil];
        
    }
    return self;
}

#pragma mark - UI actions
- (IBAction)editAlarm:(id)sender {
    NSLog(@"Edit task: %@", task.time);
    //[self.delegate editTask:task forPage:self];
}

- (IBAction)OnAlarmSwitchChanged:(UISwitch *)sender {
    // 写入数据库
    //[EWAlarmManager.sharedInstance setAlarmState:sender.on atIndex:sender.tag];
    //[EWAlarmManager.sharedInstance saveAlarm];
    //EWTaskItem *t = EWTaskStore.sharedInstance.allTasks[sender.tag];
    
    EWAlarmItem *a = task.alarm;
    a.state = [NSNumber numberWithBool:sender.on];
    //t.state = a.state;
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlarmStateChangedNotification object:self userInfo:@{@"alarm": a}];
    NSLog(@"Alarm on %@ changed to %hhd", a.time.weekday, sender.on);
}

- (IBAction)playMessage:(id)sender {
    if (task.medias.count) {
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] init];
        controller.task = self.task;
        [rootViewController presentViewController:controller animated:YES completion:^{}];
    }
}

- (void)setTask:(EWTaskItem *)t{
    //unsubscribe previous task if possible
    @try {
        [task removeObserver:self forKeyPath:@"state"];
        [task removeObserver:self forKeyPath:@"medias"];
        [task removeObserver:self forKeyPath:@"time"];
    }
    @catch (NSException * __unused exception) {NSLog(@"%@",exception);}
    
    //actions after setting the task
    task = t;
    self.alarm = task.alarm;
    self.alarmState.on = t.state.boolValue;
    self.timeText.text = [t.time date2String];
    NSInteger h = ([t.time timeIntervalSinceReferenceDate] - [NSDate timeIntervalSinceReferenceDate])/3600;
    if (h > 0) {
        self.timeLeftText.text = [NSString stringWithFormat:@"%ld hours left", (long)h];
    }
    else {
        self.timeLeftText.text = @"Just alarmed";
    }
    //media
    NSInteger mCount = task.medias.count;
    if (mCount > 0) {
        [self.messages setTitle:[NSString stringWithFormat:@"%lu voice tones", (unsigned long)task.medias.count] forState:UIControlStateNormal];
    }else{
        [self.messages setTitle:@"" forState:UIControlStateNormal];
    }
    self.editBtn.backgroundColor = [UIColor clearColor];
    self.dateText.text = [t.time date2dayString];
    self.descriptionText.text = t.statement;
    [self.descriptionText sizeToFit];
    
    //kvo <= KVO not working because it constantly updates the value
//    [task addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:NULL];
//    [task addObserver:self forKeyPath:@"medias" options:NSKeyValueObservingOptionNew context:NULL];
//    [task addObserver:self forKeyPath:@"time" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)setAlarm:(EWAlarmItem *)a{
    self.alarmState.on = a.state.boolValue;
}

#pragma mark - NOTIFICATION
- (void)updatedPage:(NSNotification *)notif{
    id sender = [notif object];
    if ([sender isMemberOfClass:[EWAlarmItem class]]) {
        if ([[(EWAlarmItem *)sender ewalarmitem_id] isEqual:alarm.ewalarmitem_id]) {
            self.alarm = sender;
            [self setNeedsDisplay];
        }
    } else if([sender isMemberOfClass:[EWTaskItem class]]) {
        if ([[(EWTaskItem *)sender ewtaskitem_id] isEqual:task.ewtaskitem_id]) {
            //NSLog(@"Is equal object: %d", [sender isEqual:task]);
            self.task = sender;
            [self setNeedsDisplay];
        }
    }
    
}

#pragma mark - KVO
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
//    if ([object isKindOfClass:[EWTaskItem class]]) {
//        //TODO: dispatch different tasks for each updates
//        NSLog(@"Observed change for task %@", [[(EWTaskItem *)object time] date2dayString]);
//        self.task = object;
//        [self setNeedsDisplay];
//    }
//}

@end
