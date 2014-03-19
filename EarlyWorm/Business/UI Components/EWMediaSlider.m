//
//  EWMediaSlider.m
//  EarlyWorm
//
//  Created by Lei on 3/18/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWMediaSlider.h"

@implementation EWMediaSlider
@synthesize timeLabel, buzzIcon, playIndicator;

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
    UIImage *leftImg = [[UIImage imageNamed:@"MediaCellLeftCap"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 20, 0, 20)];
    UIImage *rightImg = [[UIImage imageNamed:@"MediaCellRightCap"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 20, 0, 20)];
    [self setMaximumTrackImage:rightImg forState:UIControlStateNormal];
    [self setMinimumTrackImage:leftImg forState:UIControlStateNormal];
    [self setThumbImage:[UIImage imageNamed:@"MediaCellThumb"] forState:UIControlStateNormal];
    
    
    //text
    timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 50, (frame.size.height - 18)/2, 50, 20)];
    timeLabel.text = @"0:00";
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.font = [UIFont systemFontOfSize:14];
    [self addSubview:timeLabel];
    timeLabel.alpha = 0;
    
    //typeLabel
    typeLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, (frame.size.height - 18)/2, 80, 20)];
    typeLabel.text = @"Voice Tone";
    typeLabel.font = [UIFont systemFontOfSize:15];
    typeLabel.textColor = [UIColor whiteColor];
    [self addSubview:typeLabel];
    
    //buzz
    buzzIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"liked"]];
    buzzIcon.frame = CGRectMake(frame.size.width - 30, (frame.size.height - 10)/2, buzzIcon.frame.size.width, buzzIcon.frame.size.height);
    
    //color
    self.tintColor = [UIColor whiteColor];
    
}

- (void)play{
    NSLog(@"Slider is called for play");
}

- (void)stop{
    NSLog(@"Slider is called to stop");
}

- (void)setType:(NSString *)type{
    if ([type isEqualToString:@"media"]) {
        typeLabel.text = @"Voice Tone";
        timeLabel.alpha = 1;
    }else if ([type isEqualToString:@"buzz"]){
        typeLabel.text = @"Buzz";
        timeLabel.alpha = 0;
    }
}

@end
