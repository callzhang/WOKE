//
//  EWFriendsCollectionCell.m
//  Woke
//
//  Created by mq on 14-6-24.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWFriendsCollectionCell.h"
#import "EWPerson.h"
#import "EWUIUtil.h"
@implementation EWFriendsCollectionCell
//-(id)init
//{
//    if (self = [super init]) {
//        self = [self initWithFrame:CGRectMake(0, 0, 70, 100)];
//        _headImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 80)];
//        _headImageView.backgroundColor = [UIColor clearColor];
//        
//        [self addSubview:_headImageView];
//        
//        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, 70, 20)];
//        _nameLabel.textColor = [UIColor whiteColor];
//        _nameLabel.backgroundColor = [UIColor clearColor];
//        _nameLabel.textAlignment = NSTextAlignmentCenter;
//        _nameLabel.contentMode = UIViewContentModeScaleAspectFill;
//        [self addSubview:_nameLabel];
//    }
//    return self;
//}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _headImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 80)];
        _headImageView.backgroundColor = [UIColor clearColor];
        [EWUIUtil applyHexagonMaskForView:_headImageView];
        [self addSubview:_headImageView];
        
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, 70, 20)];
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.font = [UIFont systemFontOfSize:12];
        _nameLabel.backgroundColor = [UIColor clearColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_nameLabel];
    }
    return self;
}
-(void)setupCellWithInfo:(EWPerson *)person
{
    _nameLabel.text = person.name;
    _headImageView.image = person.profilePic;
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
