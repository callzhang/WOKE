//
//  EWNotificationCell.h
//  Woke
//
//  Created by Lee on 7/3/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//void

#import <UIKit/UIKit.h>
@class EWNotification;

@interface EWNotificationCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *profilePic;
@property (strong, nonatomic) IBOutlet UILabel *time;
@property (strong, nonatomic) IBOutlet UILabel *detail;
@property (strong, nonatomic) EWNotification *notification;
@property (nonatomic) NSInteger cellHeight;

- (void)setSize;

@end
