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
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
	
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
		
		//if active, show the animation
		[self presentViewController:viewController animated:YES completion:block];
	} else {
		//if inactive, wait until app become active
		__block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			NSLog(@"Application did become active, start blur animation");
			[self presentViewController:viewController animated:YES completion:block];
			[[NSNotificationCenter defaultCenter] removeObserver:observer];
		}];
		
		//use simple transition instead: this doesn't work as the background needs blur
//		viewController.transitioningDelegate = nil;
//		[self presentViewController:viewController animated:YES completion:^{
//			viewController.transitioningDelegate = delegate;
//		}];
	}
	
	
	
	return;
}


- (void)dismissBlurViewControllerWithCompletionHandler:(void(^)(void))completion{
	[self dismissViewControllerAnimated:YES completion:^{
		if (completion) {
			completion();
		}
		
		//status bar
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
	}];
	
	
}

- (void)presentWithBlur:(UIViewController *)controller withCompletion:(void (^)(void))completion{
	if (self.presentedViewController) {
		//need to dismiss first
		[self dismissBlurViewControllerWithCompletionHandler:^{
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[self presentViewControllerWithBlurBackground:controller completion:^{
					if (completion) {
						completion();
					}
				}];
			});
		}];
	}else{
		[self presentViewControllerWithBlurBackground:controller completion:^{
			if (completion) {
				completion();
			}
		}];
	}
}


@end
