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
        // background image
        [self setMaximumTrackImage:[UIImage imageNamed:@"MediaCellRightCap"] forState:UIControlStateNormal];
        [self setMaximumTrackImage:[UIImage imageNamed:@"MediaCellLeftCap"] forState:UIControlStateNormal];
        [self setThumbImage:[UIImage imageNamed:@"MediaCellThumb"] forState:UIControlStateNormal];

        
        //text
        timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 25, (frame.size.height - indicator.frame.size.height)/2, indicator.frame.size.width, indicator.frame.size.height)];
        self.tintColor = [UIColor whiteColor];
        
        //state
        //state = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 50, 20)];
        //state.text = @"Play";
        
        //activity indicator
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [indicator stopAnimating];
        indicator.frame = CGRectMake(frame.size.width - indicator.frame.size.width - 5, (frame.size.height - indicator.frame.size.height)/2, indicator.frame.size.width, indicator.frame.size.height);
        [self addSubview:indicator];
        indicator.alpha = 0;

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
