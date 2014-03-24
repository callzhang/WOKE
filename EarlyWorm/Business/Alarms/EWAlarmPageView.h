//
//  EWAlarmPageView.h
//  EarlyWorm
//
//  Created by Lei on 9/25/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWTaskItem;
@class EWAlarmPageView;
@class EWAlarmItem;

@protocol EWAlarmItemEditProtocal <NSObject>
@optional
- (void)editTask:(EWTaskItem *)task forPage:(EWAlarmPageView *)page;
@required
- (void)scheduleAlarm;
@end


@interface EWAlarmPageView : UIView <UITextFieldDelegate>

@property (nonatomic, weak) id <EWAlarmItemEditProtocal> delegate;

@property (nonatomic, retain) EWTaskItem *task;
@property (nonatomic, retain) EWAlarmItem *alarm;
@property (strong, nonatomic) IBOutlet UILabel *typeText;
@property (strong, nonatomic) IBOutlet UILabel *dateText;
@property (strong, nonatomic) IBOutlet UILabel *timeText;
@property (strong, nonatomic) IBOutlet UILabel *timeLeftText;
@property (weak, nonatomic) IBOutlet UILabel *AM;
@property (weak, nonatomic) IBOutlet UIButton *editBtn;
@property (weak, nonatomic) IBOutlet UILabel *descriptionText;
@property (weak, nonatomic) IBOutlet UIButton *messages;
@property (weak, nonatomic) IBOutlet UISwitch *alarmState;

- (IBAction)editAlarm:(id)sender;
- (IBAction)OnAlarmSwitchChanged:(id)sender;
- (IBAction)playMessage:(id)sender;
- (void)updatedPage:(NSNotification *)notif;

@end
