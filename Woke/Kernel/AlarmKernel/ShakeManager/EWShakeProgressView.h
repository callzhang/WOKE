//
//  EWShakeProgressView.h
//  Woke
//
//  Created by mq on 14-8-22.
//  Copyright (c) 2014年 WokeAlarm.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kMotionStrengthModifier     0.1
#define kMotionThreshold            0.1


typedef void (^SuccessProgressHandler)(void);

typedef void (^ProgressingHandler)(void);

@interface EWShakeProgressView : UIProgressView


-(BOOL)isShakeSupported;

-(void)startUpdateProgressBarWithProgressingHandler:(ProgressingHandler) progressHandler CompleteHandler:(SuccessProgressHandler) successProgressHandler;

@end
