//
//  EWRoundButton.m
//  EarlyWorm
//
//  Created by Lei on 3/17/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWRoundButton.h"

@implementation EWRoundButton{
    UIImageView *backgroundImage;
    UIActivityIndicatorView *indicator;
    //UILabel *state;
    BOOL playing;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        // background image
        backgroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        backgroundImage.layer.masksToBounds = YES;
        backgroundImage.layer.cornerRadius = 5.0f;
        backgroundImage.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
        backgroundImage.layer.borderWidth = 2.0f;
        [self addSubview:backgroundImage];
        [self sendSubviewToBack:backgroundImage];
        
        //text
        [self setTitle:@"0:00" forState:UIControlStateNormal];
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

- (EWRoundButton *)initMediaUnitPlayButtonWithFrame:(CGRect)frame{
    if (frame.size.height == 0 && frame.size.width == 0) {
        //empty frmae
        frame = CGRectMake(0, 0, 150, 30);
    }
    EWRoundButton *button = [self initWithFrame:frame];
    
    
    return button;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)stop{
    //stop
    [indicator stopAnimating];
    indicator.alpha = 0;
}

- (void)play{
    [indicator startAnimating];
    indicator.alpha = 1;
}
@end
