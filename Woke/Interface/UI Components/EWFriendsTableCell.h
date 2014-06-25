//
//  EWFriendsTableCell.h
//  Woke
//
//  Created by mq on 14-6-25.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EWFriendsTableCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *proImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;

-(void)setupCellWithPerson:(EWPerson *)person;
@end
