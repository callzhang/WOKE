//
//  UIViewController+Blur.h
//  EarlyWorm
//
//  Created by Lei on 3/23/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kBlurViewTag       345
#define kBlurImageTag      435
#define kBgPicViewTag      999
typedef enum{
    EWBlurViewOptionWhite,
    EWBlurViewOptionBlack
} EWBlurViewOptions;

@class NavigationControllerDelegate;

@interface UIViewController (Blur)

- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController;
- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController completion:(void (^)(void))block;
- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController option:(EWBlurViewOptions)blurOption completion:(void (^)(void))block;
- (void)dismissBlurViewControllerWithCompletionHandler:(void(^)(void))completion;


- (void)presentWithBlur:(UIViewController *)controller withCompletion:(void (^)(void))completion;
@end
