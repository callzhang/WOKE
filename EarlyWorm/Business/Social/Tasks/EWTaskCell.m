//
//  EWTaskCell.m
//  EarlyWorm
//
//  Created by Lei on 8/26/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWTaskCell.h"

@implementation EWTaskCell
@synthesize task, alarm, media, owner;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.backgroundColor = kCustomWhite;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


#pragma mark - DataSource

- (void)setTask:(EWTaskCell *)t{
    task = t;
    alarm = task.alarm;
    media = task.media;
    owner = task.media.author;
}

@end
