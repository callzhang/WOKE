//
//  EWMediaSlider.m
//  EarlyWorm
//
//  Created by Lei on 3/18/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWMediaSlider.h"
#import "EWMedia.h"


@implementation EWMediaSlider
@synthesize  buzzIcon, playIndicator;

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
        [self initMediaSlider:self.frame];
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
    self.frame = frame;
//    UIImage *leftImg = [[UIImage imageNamed:@"MediaCellThumb"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 2, 0, 2)];
//    UIImage *rightImg = [[UIImage imageNamed:@"MediaCellRightCap"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 2, 0, 2)];
//    [self setMaximumTrackImage:rightImg forState:UIControlStateNormal];
//    [self setMinimumTrackImage:leftImg forState:UIControlStateNormal];
    
    
    //text
    //timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 50, (frame.size.height - 20)/2, 50, 20)];
//    timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, (frame.size.height - 24)/2, 80, 20)];
//    timeLabel.text = @"0\"";
//    timeLabel.textColor = [UIColor whiteColor];
//    timeLabel.font = [UIFont systemFontOfSize:14];
//    [self addSubview:timeLabel];
    
    //typeLabel
//    typeLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, (frame.size.height - 24)/2, 80, 20)];
//    typeLabel.text = @"Voice Tone";
//    typeLabel.font = [UIFont systemFontOfSize:15];
//    typeLabel.textColor = [UIColor whiteColor];
//    [self addSubview:typeLabel];
//    typeLabel.hidden = YES;

    [self setThumbImage:[UIImage imageNamed:@"MediaCellThumb"] forState:UIControlStateNormal];
    self.tintColor = [UIColor whiteColor];
    self.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.1];
}

- (void)play{
    NSLog(@"Slider is called for play");
}

- (void)stop{
    NSLog(@"Slider is called to stop");
}

@end
