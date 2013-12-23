//
//  EWDetailTaskViewController.h
//  EarlyWorm
//
//  Created by Lei on 9/6/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWViewController.h"
#import "EWAlarmItem.h"
#import "EWTaskItem.h"
#import "EWPerson.h"


@interface EWDetailTaskViewController : EWViewController
@property (nonatomic, retain) EWAlarmItem *alarm;
@property (nonatomic, retain) EWTaskItem *task;
@property (nonatomic, retain) EWPerson *person;
@end
