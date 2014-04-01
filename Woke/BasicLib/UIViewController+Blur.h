//
//  UIViewController+Blur.h
//  EarlyWorm
//
//  Created by Lei on 3/23/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Blur)
- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController;
- (void)dismissViewControllerWithBlurBackground:(UIViewController *)viewController;
@end
