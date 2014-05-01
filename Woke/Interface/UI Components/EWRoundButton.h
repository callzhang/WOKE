//
//  EWRoundButton.h
//  EarlyWorm
//
//  Created by Lei on 3/17/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EWRoundButton : UIButton

/**
 Initialize with a around button that has a time in the button at the right side. And a play symbol when not playing, and a activity indicator when playing.
 */
- (EWRoundButton *)initMediaUnitPlayButtonWithFrame:(CGRect)frame;


- (void)play;
- (void)stop;
@end
