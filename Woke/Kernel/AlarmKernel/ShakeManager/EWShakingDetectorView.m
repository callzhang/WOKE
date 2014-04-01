//
//  EWShakingDetectorView.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-2.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWShakingDetectorView.h"

@implementation EWShakingDetectorView
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.subtype == UIEventSubtypeMotionShake) {
        // 具体执行代码
        [_delegate shakingDetectorShaked:self];
        
        SAFE_DELEGATE_VOID(_delegate, @selector(shakingDetectorShaked:), shakingDetectorShaked:self);
    }
    
    if ([super respondsToSelector:@selector(motionEnded:withEvent:)]) {
        [super motionEnded:motion withEvent:event];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

@end
