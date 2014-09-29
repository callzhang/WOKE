//
//  UIViewController+Blur.m
//  EarlyWorm
//
//  Created by Lei on 3/23/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "UIViewController+Blur.h"
#import "EWUIUtil.h"
#import "NavigationControllerDelegate.h"
#import "EWAppDelegate.h"


static NavigationControllerDelegate *delegate = nil;

@implementation UIViewController (Blur)

- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController{
	
	[self presentViewControllerWithBlurBackground:viewController completion:NULL];
	
}

- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController completion:(void (^)(void))block{
	[self presentViewControllerWithBlurBackground:viewController option:EWBlurViewOptionBlack completion:block];
}


- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController option:(EWBlurViewOptions)blurOption completion:(void (^)(void))block{
	viewController.modalPresentationStyle = UIModalPresentationCustom;
	if (!delegate) {
		delegate = [NavigationControllerDelegate new];
	}
	
	viewController.transitioningDelegate = delegate;
	if ([viewController isKindOfClass:[UINavigationController class]]) {
		[(UINavigationController *)viewController setDelegate:delegate];
	}
	
	//hide status bar
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

	[self presentViewController:viewController animated:YES completion:block];

	
	return;
}


- (void)dismissBlurViewControllerWithCompletionHandler:(void(^)(void))completion{
	
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	

	[self dismissViewControllerAnimated:YES completion:completion];

}

- (void)presentWithBlur:(UIViewController *)controller withCompletion:(void (^)(void))completion{
	if (self.presentedViewController) {
		if ([self.presentedViewController isKindOfClass:[controller class]]) {
			DDLogWarn(@"The view controller %@ is already presenting, skip blur animation", controller.class);
		}
		//need to dismiss first
		[self dismissBlurViewControllerWithCompletionHandler:^{
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[self presentViewControllerWithBlurBackground:controller completion:completion];
			});
		}];
	}else{
		[self presentViewControllerWithBlurBackground:controller completion:completion];
	}
}


@end
