//
//  UINavigationController+Extend.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-15.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (Delegate)<UINavigationControllerDelegate>

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated;


@end
