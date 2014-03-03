//
//  EWCollectionPersonCell.m
//  EarlyWorm
//
//  Created by Lei on 3/2/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWCollectionPersonCell.h"

@implementation EWCollectionPersonCell
@synthesize profilePic;
@synthesize label;
@synthesize maskView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // profilePic
        profilePic = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,kCollectionViewCellPersonRadius * 2, kCollectionViewCellPersonRadius * 2)];
        profilePic.layer.masksToBounds = YES;
        profilePic.layer.cornerRadius = kCollectionViewCellPersonRadius;
        profilePic.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
        profilePic.layer.borderWidth = 1.0f;
        [self.contentView addSubview:profilePic];
        
        //background
        self.contentView.backgroundColor = [UIColor clearColor];
        
        //label
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, kCollectionViewCellWidth, kCollectionViewCellHeight - 2*kCollectionViewCellPersonRadius)];
        
        
        //mask
        maskView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,kCollectionViewCellPersonRadius, kCollectionViewCellPersonRadius)];
        maskView.layer.masksToBounds = YES;
        maskView.layer.cornerRadius = kCollectionViewCellPersonRadius;
        maskView.image = [UIImage imageNamed:@"checkmark"];
        maskView.hidden = YES;
        [self.contentView addSubview:maskView];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/



@end
