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

- (id)init {
    self = [super init];
    if (self) {
        NSArray *nibViews =  [[NSBundle mainBundle] loadNibNamed:@"EWAlarmPage" owner:self options:nil];
        
        for (UIView *view in nibViews) {
            [self addSubview:view];
        }
        //Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedPage:) name:kAlarmChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedPage:) name:kTaskTimeChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedPage:) name:kTaskStateChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedPage:) name:kTaskChangedNotification object:nil];
    }
    return self;
}

#pragma mark - UI actions
- (IBAction)editAlarm:(id)sender {
    NSLog(@"Edit task: %@", task.time);
    [self.delegate scheduleAlarm];
}

- (IBAction)OnAlarmSwitchChanged:(UISwitch *)sender {
    //change task not alarm
//    EWAlarmItem *a = task.alarm;
//    a.state = [NSNumber numberWithBool:sender.on];
    
    task.state = [NSNumber numberWithBool:sender.on];
    [context saveOnSuccess:^{
        //
    } onFailure:^(NSError *error) {
        NSLog(@"Task state failed to save");
        sender.on = !(sender.on);
        [self setNeedsDisplay];
    }];
    
    //broadcast
    [[NSNotificationCenter defaultCenter] postNotificationName:kTaskStateChangedNotification object:self userInfo:@{@"task": task}];
    NSLog(@"Task on %@ changed to %@", task.time.weekday, (sender.on?@"ON":@"OFF"));
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
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    
    //setting the hours left
    task = t;
    alarm = task.alarm;
    self.alarmState.on = t.state.boolValue;
    self.timeText.text = [t.time date2timeShort];
    
    float h = ([t.time timeIntervalSinceReferenceDate] - [NSDate timeIntervalSinceReferenceDate])/3600;

    if (h > 0) {
        self.timeLeftText.text = [NSString stringWithFormat:@"%.1f hours left", h];
    }
    else {
        self.timeLeftText.text = @"Just alarmed";
    }
    

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWMediaItem"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"task == %@", task];
    request.predicate = predicate;
    SMRequestOptions *options = [SMRequestOptions options];
    options.fetchPolicy = SMFetchPolicyTryNetworkElseCache;
    [[[EWDataStore sharedInstance] currentContext] executeFetchRequestAndWait:request returnManagedObjectIDs:NO options:options error:NULL];
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
    
    self.dateText.hidden = YES;
    self.typeText.hidden = YES;
    
//    //kvo <= KVO not working because it constantly updates the value
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
            NSLog(@"Alarm page (%@) received task change notification", task.time.weekday);
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
