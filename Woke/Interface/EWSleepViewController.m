//
//  EWSleepViewController.m
//  Woke
//
//  Created by Lee on 8/6/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWSleepViewController.h"
#import "EWBackgroundingManager.h"
#import "AVManager.h"
#import "EWTaskManager.h"
#import "EWPersonManager.h"
#import "EWTaskItem.h"
#import "EWAlarmManager.h"

@interface EWSleepViewController (){
    NSTimer *timer;
	EWTaskItem *nextTask;
}

@end

@implementation EWSleepViewController

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
    // Do any additional setup after loading the view from its nib.
    [[EWBackgroundingManager sharedInstance] startBackgrounding];
	nextTask = [[EWTaskManager sharedInstance] nextValidTaskForPerson:[EWSession sharedSession].currentUser];
	
	NSDate *cachedNextTime = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:[EWSession sharedSession].currentUser];
	if (![cachedNextTime isEqualToDate:nextTask.time]) {
		[[EWAlarmManager sharedInstance] updateCachedAlarmTime];
	}
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //sound
    [[AVManager sharedManager] playSoundFromFileName:@"sleep mode.caf"];
    //time
    [self updateTimer:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [timer invalidate];
}

- (IBAction)cancel:(id)sender {
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    [[EWBackgroundingManager sharedInstance] endBackgrounding];
}

- (void)updateTimer:(NSTimer *)time{
	if (![UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
		return;
	}
    NSDate *t = [NSDate date];
    self.timeLabel.text = t.date2String;
	
	self.timeLeftLabel.text = [NSString stringWithFormat:@"%@ left", nextTask.time.timeLeft];
    self.alarmTime.text = [NSString stringWithFormat:@"Alarm %@", nextTask.time.date2String];
    
    if (nextTask.time.timeIntervalSinceNow <0) {
        //task has past
		[timer invalidate];
        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    }
    
    //timer
    timer = [NSTimer scheduledTimerWithTimeInterval:nextTask.time.timeIntervalSinceNow/30 target:self selector:@selector(updateTimer:) userInfo:nil repeats:NO];
}
@end
