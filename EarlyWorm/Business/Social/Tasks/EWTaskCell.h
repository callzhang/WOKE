//
//  EWTaskCell.h
//  EarlyWorm
//
//  Created by Lei on 8/26/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWAlarmItem.h"
#import "EWMediaItem.h"
#import "EWPerson.h"
#import "EWTaskItem.h"

@interface EWTaskCell : UITableViewCell
@property (retain, nonatomic) EWAlarmItem *alarm;
@property (retain, nonatomic) EWMediaItem *media;
@property (retain, nonatomic) EWPerson *owner;
@property (retain, nonatomic) EWTaskCell *task;

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *wakeTime;
@property (weak, nonatomic) IBOutlet UILabel *description;
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UIButton *contactInfo;

@end
