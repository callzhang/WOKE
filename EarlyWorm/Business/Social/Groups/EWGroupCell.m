//
//  EWGroupCell.m
//  EarlyWorm
//
//  Created by Lei on 10/19/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWGroupCell.h"
#import "EWGroupStore.h"
#import "EWGroup.h"
#import "NSDate+Extend.h"

@implementation EWGroupCell
@synthesize group = _group;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setGroup:(EWGroup *)group{
    _group = group;
    self.name.text = group.name;
    self.wakeupTime.text = [group.wakeupTime date2String];
    self.groupPic.image = group.image;
    self.description.text = group.statement;
}

@end
