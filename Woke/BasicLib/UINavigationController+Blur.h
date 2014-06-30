//
//  UINavigationController+Blur.h
//  Woke
//
//  Created by mq on 14-6-22.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController(Blur)

-(void)pushViewControllerWithBlur:(UIViewController *)viewController;
-(void)pushViewControllerWithBlur:(UIViewController *)viewController tableViewInHead:(BOOL)hasHeadTableView;
-(void)popViewControllerWithBlur;
-(UIImageView *)navBlurView;
@end
