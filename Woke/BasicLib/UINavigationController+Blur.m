//
//  UINavigationController+Blur.m
//  Woke
//
//  Created by mq on 14-6-22.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "UINavigationController+Blur.h"
#import "UIViewController+Blur.h"

@implementation UINavigationController(Blur)


-(void)pushViewControllerWithBlur:(UIViewController *)viewController
{
    viewController.view.backgroundColor = [UIColor clearColor];
    
  
    
    [self addBlurInViewContrller:viewController];

    
    [self pushViewController:viewController animated:NO];

    //callback

}
-(void)popViewControllerWithBlur
{
    [self popViewControllerAnimated:NO];
    UIViewController *viewController = self.visibleViewController;
    [self addBlurInViewContrller:viewController];
    
}
-(void)addBlurInViewContrller:(UIViewController *)viewController
{
    UIToolbar *bgToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
    bgToolbar.tag = kBlurViewTag;
    
    bgToolbar.barStyle = UIBarStyleBlack;
    [viewController.view addSubview:bgToolbar];
    [viewController.view sendSubviewToBack:bgToolbar];
    
    
    [self.view viewWithTag:kBlurViewTag].hidden = YES;
    
    //get CALayer image
    
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
    
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:contextRef];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //get image
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.view.frame];
    imgView.image = img;
    imgView.tag = kBlurImageTag;
    
    //   [[UINavigationBar appearance] setBackgroundColor:[UIColor clearColor]];
    //   [[UINavigationBar appearance] setBackgroundImage:img forBarPosition:UIBarPositionTop barMetrics:UIBarMetricsDefault];
    [self.view addSubview:imgView];
    [self.view sendSubviewToBack:imgView];

}
@end
