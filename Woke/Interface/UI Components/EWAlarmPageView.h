//
//  EWAlarmPageView.h
//  EarlyWorm
//
//  Created by Lei on 9/25/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWAlarmPageView;
@class EWAlarm;

@protocol EWAlarmItemEditProtocal <NSObject>
@required
- (void)scheduleAlarm;
@end


@interface EWAlarmPageView : UIView <UITextFieldDelegate>

@property (nonatomic, weak) id <EWAlarmItemEditProtocal> delegate;

@property (nonatomic, retain) EWAlarm *alarm;
@property (strong, nonatomic) IBOutlet UILabel *timeText;
@property (strong, nonatomic) IBOutlet UILabel *timeLeftText;
@property (weak, nonatomic) IBOutlet UILabel *AM;
@property (weak, nonatomic) IBOutlet UIButton *editBtn;
@property (weak, nonatomic) IBOutlet UILabel *descriptionText;//detailed text not used anymoreW
@property (weak, nonatomic) IBOutlet UIButton *messages;
@property (weak, nonatomic) IBOutlet UIButton *alarmState;

- (IBAction)editAlarm:(id)sender;
- (IBAction)OnAlarmSwitchChanged:(UIButton *)sender;
- (IBAction)playMessage:(id)sender;

@end
