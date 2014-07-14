//
//  UIViewController+Blur.m
//  EarlyWorm
//
//  Created by Lei on 3/23/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "UIViewController+Blur.h"
#import "EWUIUtil.h"
#import "UIView+Sreenshot.h"
#import "NavigationControllerDelegate.h"

@implementation UIViewController (Blur)

- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController{
	
	[self presentViewControllerWithBlurBackground:viewController completion:NULL];
	
}

- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController completion:(void (^)(void))block{
	[self presentViewControllerWithBlurBackground:viewController option:EWBlurViewOptionBlack completion:block];
}


- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController option:(EWBlurViewOptions)blurOption completion:(void (^)(void))block{
	viewController.modalPresentationStyle = UIModalPresentationCustom;
	NavigationControllerDelegate *delegate = [NavigationControllerDelegate new];
	viewController.transitioningDelegate = delegate;
	
	
	[self presentViewController:viewController animated:YES completion:^{
		//callback
		if (block) {
			block();
		}
	}];
	
	
	return;
}


- (void)dismissBlurViewControllerWithCompletionHandler:(void(^)(void))completion{
	self.modalPresentationStyle = UIModalPresentationCustom;
	NavigationControllerDelegate *delegate = [NavigationControllerDelegate new];
	self.transitioningDelegate = delegate;
	[self dismissViewControllerAnimated:YES completion:completion];
}



@end
