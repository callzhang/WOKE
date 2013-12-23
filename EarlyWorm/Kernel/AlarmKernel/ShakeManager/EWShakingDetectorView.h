//
//  EWShakingDetectorView.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-2.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EWShakingDetectorView;
@protocol EWShakingDetectorViewDelegate <NSObject>

@optional
- (void)shakingDetectorShaked:(EWShakingDetectorView *)detectorView;

@end

@interface EWShakingDetectorView : UIView

@property (nonatomic, assign) id<EWShakingDetectorViewDelegate> delegate;

@end
