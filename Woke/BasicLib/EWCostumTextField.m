//
//  EWCostumTextField.m
//  Woke
//
//  Created by mq on 14-7-2.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWCostumTextField.h"

@implementation EWCostumTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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
//控制placeHolder的颜色、字体
- (void)drawPlaceholderInRect:(CGRect)rect
{
//    self.placeholder.length
    //CGContextRef context = UIGraphicsGetCurrentContext();
    //CGContextSetFillColorWithColor(context, [UIColor yellowColor].CGColor);
    [[UIColor lightGrayColor] setFill];
//    rect.origin.x = rect.origin.x+rect.size.width/2 - self.placeholder.length*4;
    [[self placeholder] drawInRect:rect withFont:[UIFont systemFontOfSize:17]];
}

@end
