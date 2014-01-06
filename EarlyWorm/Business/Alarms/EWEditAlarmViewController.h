//
//  EWEditAlarmViewController.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-8.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWRingtoneSelectionViewController.h"
#import "EWWeekDayPickerTableViewController.h"
@class EWAlarmsViewController;

@class EWAlarmItem, EWTaskItem;
@interface EWEditAlarmViewController : EWViewController <EWRingtoneSelectionDelegate, UITextFieldDelegate>{
    NSDate *newTime;
    NSString *newDescrition;
    NSString *newTone;
    BOOL newState;
    UITextField *alarmDesText;
}
@property (nonatomic, retain) EWAlarmItem *alarm;
@property (nonatomic) EWTaskItem *task;
@property (nonatomic, retain) EWAlarmsViewController *parentController;
@end
