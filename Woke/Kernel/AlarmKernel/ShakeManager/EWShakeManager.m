//
//  EWShakeManager.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-2.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWShakeManager.h"

@implementation EWShakeManager
@synthesize delegate = _delegate;

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    _shakingDetectorView.delegate = nil;
}

- (void)register {
    if (!_shakingDetectorView) {
        _shakingDetectorView = [[EWShakingDetectorView alloc] initWithFrame:CGRectZero];
        _shakingDetectorView.delegate = self;
    }
    [_shakingDetectorView becomeFirstResponder];

    //UIView *currentView = SAFE_DELEGATE_RETURN(_delegate, @selector(currentView), currentView);
    [_delegate.currentView addSubview:_shakingDetectorView];
}

- (void)unregister {
    [_shakingDetectorView resignFirstResponder];
    [_shakingDetectorView removeFromSuperview];
}

#pragma mark - EWShakingDetectorViewDelegate

- (void)shakingDetectorShaked:(EWShakingDetectorView *)detectorView {
    [_delegate EWShakeManagerDidShaked];
}

@end
