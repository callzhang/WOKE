//
//  EWNotificationCell.h
//  Woke
//
//  Created by Lee on 7/3/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWNotification;

@interface EWNotificationCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *time;
@property (weak, nonatomic) IBOutlet UILabel *detail;
@property (weak, nonatomic) EWNotification *notification;
@property (nonatomic) NSInteger cellHeight;
@end
