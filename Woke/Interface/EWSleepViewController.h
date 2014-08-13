//
//  EWSleepViewController.h
//  Woke
//
//  Created by Lee on 8/6/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EWSleepViewController : UIViewController
- (IBAction)cancel:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLeftLabel;
@property (weak, nonatomic) IBOutlet UILabel *alarmTime;

@end
