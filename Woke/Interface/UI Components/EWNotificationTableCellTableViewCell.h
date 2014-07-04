//
//  EWNotificationTableCellTableViewCell.h
//  Woke
//
//  Created by mq on 14-7-5.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EWNotificationTableCellTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *detailLabel;

@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@end
