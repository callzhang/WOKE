//
//  EWShakeManager.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-2.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWShakingDetectorView.h"

@protocol EWShakeManagerDelegate <NSObject>

- (UIView *)currentView;

@optional
- (void)EWShakeManagerDidShaked;

@end

@interface EWShakeManager : NSObject<EWShakingDetectorViewDelegate> {
    EWShakingDetectorView *_shakingDetectorView;
}

@property (nonatomic, assign) id<EWShakeManagerDelegate> delegate;

// 目前只支持单次注册到某一个界面中，以后有需要再兼容多个
- (void)register;
- (void)unregister;

@end
