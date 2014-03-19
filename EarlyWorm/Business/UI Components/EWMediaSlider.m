//
//  EWMediaSlider.m
//  EarlyWorm
//
//  Created by Lei on 3/18/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWMediaSlider.h"

@implementation EWMediaSlider
@synthesize timeLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self initMediaSlider:frame];

    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initMediaSlider:CGRectMake(0, 0, 320, 80)];
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


- (void)initMediaSlider:(CGRect)frame{
    // background image
    UIImage *leftImg = [[UIImage imageNamed:@"MediaCellLeftCap"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 20, 0, 20)];
    UIImage *rightImg = [[UIImage imageNamed:@"MediaCellRightCap"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 20, 0, 20)];
    [self setMaximumTrackImage:rightImg forState:UIControlStateNormal];
    [self setMinimumTrackImage:leftImg forState:UIControlStateNormal];
    [self setThumbImage:[UIImage imageNamed:@"MediaCellThumb"] forState:UIControlStateNormal];
    
    
    //text
    timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 25, (frame.size.height - 20)/2, 50, 20)];
    timeLabel.text = @"0:00";
    [self addSubview:timeLabel];
    
    //color
    self.tintColor = [UIColor whiteColor];
}

- (void)play{
    NSLog(@"Slider is called for play");
}

- (void)stop{
    NSLog(@"Slider is called to stop");
}

@end
