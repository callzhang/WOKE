//
//  EWAddTaskViewController.h
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWAlarmItem;

@interface EWAddTaskViewController : UITableViewController
@property (nonatomic, retain) NSMutableArray *alarmList;
@property (nonatomic, retain) EWAlarmItem *selectedAlarm;

@end
