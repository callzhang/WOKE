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
    
    [self pushViewController:viewController animated:YES];
    
    [self addBlurInViewContrller:viewController];

    
    

    //callback

}
-(void)popViewControllerWithBlur
{
    [self popViewControllerAnimated:YES];
//    UIViewController *viewController = self.visibleViewController;
//    [self addBlurInViewContrller:viewController];
    
}
-(void)addBlurInViewContrller:(UIViewController *)viewController
{
    UIToolbar *bgToolbar = (UIToolbar *)[self.view viewWithTag:kBlurViewTag];
    [self.view sendSubviewToBack:bgToolbar];
//    bgToolbar.tag = kBlurViewTag;
    
//    bgToolbar.barStyle = UIBarStyleBlack;
//    [viewController.view addSubview:bgToolbar];
//    [viewController.view sendSubviewToBack:bgToolbar];
    
    UIImageView *bgImageView =( UIImageView *) [self.view viewWithTag:kBlurImageTag];
    bgImageView.hidden = NO;
    [self.view sendSubviewToBack:bgImageView];
//    [self.view viewWithTag:kBlurImageTag].hidden = YES;
    
    //get CALayer image
    
//    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
    
//    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
//    CGContextRef contextRef = UIGraphicsGetCurrentContext();
//    [self.view.layer renderInContext:contextRef];
//    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    //get image
//    UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.view.frame];
//    imgView.image = img;
//    imgView.tag = kBlurImageTag;
    
    //   [[UINavigationBar appearance] setBackgroundColor:[UIColor clearColor]];
    //   [[UINavigationBar appearance] setBackgroundImage:img forBarPosition:UIBarPositionTop barMetrics:UIBarMetricsDefault];
//    [self.view addSubview:imgView];
//    [self.view sendSubviewToBack:imgView];

}
@end
