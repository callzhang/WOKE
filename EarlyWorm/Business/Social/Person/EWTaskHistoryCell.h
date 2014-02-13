//
//  EWTaskHistoryCell.h
//  EarlyWorm
//
//  Created by Lei on 2/9/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EWTaskHistoryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *wakeTime;
@property (weak, nonatomic) IBOutlet UILabel *dayOfMonth;
@property (weak, nonatomic) IBOutlet UILabel *taskInfo;
@property (weak, nonatomic) IBOutlet UILabel *month;

@end
