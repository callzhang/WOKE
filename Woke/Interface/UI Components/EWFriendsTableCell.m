//
//  EWFriendsTableCell.m
//  Woke
//
//  Created by mq on 14-6-25.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWFriendsTableCell.h"
#import "EWPerson.h"
#import "EWUIUtil.h"
@implementation EWFriendsTableCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setupCellWithPerson:(EWPerson *)person
{
    self.backgroundColor = [UIColor clearColor];
    self.proImageView.image = person.profilePic;
    self.nameLabel.text = person.name;
    self.nameLabel.textColor = [UIColor whiteColor];
    [EWUIUtil applyHexagonSoftMaskForView:self.proImageView];
}

@end
