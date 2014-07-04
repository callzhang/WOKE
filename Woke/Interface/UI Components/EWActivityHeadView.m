//
//  EWActivityHeadView.m
//  Woke
//
//  Created by mq on 14-7-4.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWActivityHeadView.h"

@implementation EWActivityHeadView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x+20,-20, frame.size.width/4, frame.size.height)];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:20];
        _titleLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_titleLabel];
    }
//    self.backgroundColor = [UIColor redColor];
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
