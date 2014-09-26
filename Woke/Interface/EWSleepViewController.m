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
#import "EWTaskStore.h"
#import "EWPersonStore.h"
#import "EWTaskItem.h"

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
	nextTask = [[EWTaskStore sharedInstance] nextValidTaskForPerson:me];
	
	NSDate *cachedNextTime = me.cachedInfo[kNextTaskTime];
	if (![cachedNextTime isEqualToDate:nextTask.time]) {
		[[EWTaskStore sharedInstance] updateNextTaskTime];
	}
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //sound
    [[AVManager sharedManager] playSoundFromFileName:@"sleep mode.caf"];
    //time
    [self updateTimer:nil];
    //timer
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
    //[EWTaskStore scheduleNotificationOnServerWithTimer:[[EWTaskStore sharedInstance] nextValidTaskForPerson:me]];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [timer invalidate];
}

- (IBAction)cancel:(id)sender {
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    [[EWBackgroundingManager sharedInstance] endBackgrounding];
}

- (void)updateTimer:(NSTimer *)timer{
    NSDate *t = [NSDate date];
    self.timeLabel.text = t.date2String;
	
	self.timeLeftLabel.text = [NSString stringWithFormat:@"%@ left", nextTask.time.timeLeft];
    self.alarmTime.text = [NSString stringWithFormat:@"Alarm %@", nextTask.time.date2String];
}
@end
