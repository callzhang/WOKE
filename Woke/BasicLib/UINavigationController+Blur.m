//
//  UINavigationController+Blur.m
//  Woke
//
//  Created by mq on 14-6-22.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "UINavigationController+Blur.h"
#import "UIViewController+Blur.h"
#import "AFBlurSegue.h"
#import "UIImage+ImageEffects.h"
@implementation UINavigationController(Blur)
-(void)pushViewControllerWithBlur:(UIViewController *)viewController tableViewInHead:(BOOL)hasHeadTableView
{
    NSInteger _blurRadius = 50;
    UIColor  *_tintColor = [UIColor clearColor];
    CGFloat _saturationDeltaFactor = 0.5;
    viewController.view.backgroundColor = [UIColor clearColor];
    
    
    UIViewController *sourceController = self;
    UIViewController *destinationController = viewController;
    
    UIImageView *bgImageView =( UIImageView *) [self.view viewWithTag:kBlurImageTag];
    
    UIImage *background = bgImageView.image;
    
        if (hasHeadTableView) {
            UIView *viewToRender;
            for (UIView *view in sourceController.view.subviews) {
                if ([view isKindOfClass:[UITableView class]]) {
                    viewToRender = view;
                }
            }   ;
            
//        UIView *viewToRender = [(UITableViewController *)sourceController tableView];
            CGPoint contentOffset = [[(UITableViewController *)sourceController tableView]contentOffset];
            
            UIGraphicsBeginImageContext(viewToRender.bounds.size);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(context, 0, -contentOffset.y);
            [viewToRender.layer renderInContext:context];
            background = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        } else {
    
            UIGraphicsBeginImageContextWithOptions(sourceController.view.bounds.size, YES, 0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            [sourceController.view.layer renderInContext:context];
            background = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
    }
    
    switch ([[UIApplication sharedApplication]statusBarOrientation]) {
        case UIInterfaceOrientationPortrait:
            background = [UIImage imageWithCGImage:background.CGImage scale:1 orientation:UIImageOrientationUp];
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            background = [UIImage imageWithCGImage:background.CGImage scale:1 orientation:UIImageOrientationDown];
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            background = [UIImage imageWithCGImage:background.CGImage scale:1 orientation:UIImageOrientationLeft];
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            background = [UIImage imageWithCGImage:background.CGImage scale:1 orientation:UIImageOrientationRight];
            break;
            
        default:
            break;
    }
    
    UIImageView *blurredBackground = [[UIImageView alloc]initWithImage:[background applyBlurWithRadius:_blurRadius tintColor:_tintColor saturationDeltaFactor:_saturationDeltaFactor maskImage:nil]];
    
    CGRect backgroundRect = [sourceController.view convertRect:sourceController.view.window.bounds fromView:Nil];
    
    if (destinationController.modalTransitionStyle == UIModalTransitionStyleCoverVertical) {
        blurredBackground.frame = CGRectMake(0, -backgroundRect.size.width, backgroundRect.size.width, backgroundRect.size.height);
    } else {
        blurredBackground.frame = CGRectMake(0, 0, backgroundRect.size.width, backgroundRect.size.height);
    }
    
    
    destinationController.view.backgroundColor = [UIColor clearColor];
    
    if ([destinationController isKindOfClass:[UITableViewController class]]) {
        [[(UITableViewController *)destinationController tableView]setBackgroundView:blurredBackground];
    } else {
        [destinationController.view addSubview:blurredBackground];
        [destinationController.view sendSubviewToBack:blurredBackground];
    }
    
    [self pushViewController:destinationController animated:YES];
    
    [destinationController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        [UIView animateWithDuration:[context transitionDuration] animations:^{
            blurredBackground.frame = CGRectMake(0, 0, backgroundRect.size.width, backgroundRect.size.height);
        }];
    } completion:nil];

}

-(void)pushViewControllerWithBlur:(UIViewController *)viewController
{
    
    NSInteger _blurRadius = 50;
//    UIColor  *_tintColor = [UIColor colorWithRed:0.8 green:0.6 blue:0.05 alpha:0.3];
    UIColor *_tintColor = [UIColor clearColor];
    CGFloat _saturationDeltaFactor = 0.5;
    viewController.view.backgroundColor = [UIColor clearColor];
    
    
    UIViewController *sourceController = self;
    UIViewController *destinationController = viewController;
    
//     UIImageView *bgImageView =( UIImageView *) [self.view viewWithTag:kBlurImageTag];
    UIImageView *bgImageView = [self navBlurView];
    
    UIImage *background = bgImageView.image;
    
//    if ([sourceController isKindOfClass:[UITableViewController class]]) {
//        
//        UIView *viewToRender = [(UITableViewController *)sourceController tableView];
//        CGPoint contentOffset = [[(UITableViewController *)sourceController tableView]contentOffset];
//    
//        UIGraphicsBeginImageContext(viewToRender.bounds.size);
//        CGContextRef context = UIGraphicsGetCurrentContext();
//        CGContextTranslateCTM(context, 0, -contentOffset.y);
//        [viewToRender.layer renderInContext:context];
//        background = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//    } else {
//        
//        UIGraphicsBeginImageContextWithOptions(sourceController.view.bounds.size, YES, 0);
//        CGContextRef context = UIGraphicsGetCurrentContext();
//        [sourceController.view.layer renderInContext:context];
//        background = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//    }

    switch ([[UIApplication sharedApplication]statusBarOrientation]) {
        case UIInterfaceOrientationPortrait:
            background = [UIImage imageWithCGImage:background.CGImage scale:1 orientation:UIImageOrientationUp];
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            background = [UIImage imageWithCGImage:background.CGImage scale:1 orientation:UIImageOrientationDown];
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            background = [UIImage imageWithCGImage:background.CGImage scale:1 orientation:UIImageOrientationLeft];
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            background = [UIImage imageWithCGImage:background.CGImage scale:1 orientation:UIImageOrientationRight];
            break;
            
        default:
            break;
    }
    
    UIImageView *blurredBackground = [[UIImageView alloc]initWithImage:[background applyBlurWithRadius:_blurRadius tintColor:_tintColor saturationDeltaFactor:_saturationDeltaFactor maskImage:nil]];
    
    CGRect backgroundRect = [sourceController.view convertRect:sourceController.view.window.bounds fromView:Nil];
    
    if (destinationController.modalTransitionStyle == UIModalTransitionStyleCoverVertical) {
        blurredBackground.frame = CGRectMake(0, -backgroundRect.size.width, backgroundRect.size.width, backgroundRect.size.height);
    } else {
        blurredBackground.frame = CGRectMake(0, 0, backgroundRect.size.width, backgroundRect.size.height);
    }
    
    
    destinationController.view.backgroundColor = [UIColor clearColor];
    
    if ([destinationController isKindOfClass:[UITableViewController class]]) {
        [[(UITableViewController *)destinationController tableView]setBackgroundView:blurredBackground];
    } else {
        [destinationController.view addSubview:blurredBackground];
        [destinationController.view sendSubviewToBack:blurredBackground];
    }
    
    [self pushViewController:destinationController animated:YES];
    
    [destinationController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        [UIView animateWithDuration:[context transitionDuration] animations:^{
            blurredBackground.frame = CGRectMake(0, 0, backgroundRect.size.width, backgroundRect.size.height);
        }];
    } completion:nil];

    
//    [self pushViewController:viewController animated:YES];
    
//    [self addBlurInViewContrller:viewController];

    
    

    //callback

}
-(void)popViewControllerWithBlur
{
    [self popViewControllerAnimated:YES];
//    UIViewController *viewController = self.visibleViewController;
//    [self addBlurInViewContrller:viewController];
    
}
-(void)addBlurInViewController:(UIViewController *)viewController
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
    [bgImageView addSubview:bgToolbar];
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
-(UIImageView *)navBlurView
{
    UIToolbar *bgToolbar = (UIToolbar *)[self.view viewWithTag:kBlurViewTag];
//    [self.view sendSubviewToBack:bgToolbar];
    //    bgToolbar.tag = kBlurViewTag;
    
    //    bgToolbar.barStyle = UIBarStyleBlack;
    //    [viewController.view addSubview:bgToolbar];
    //    [viewController.view sendSubviewToBack:bgToolbar];
    
    UIImageView *bgImageView =( UIImageView *) [self.view viewWithTag:kBlurImageTag];
//    bgImageView.hidden = NO;
//    [self.view sendSubviewToBack:bgImageView];
//    [bgImageView addSubview:bgToolbar];
    
    
//    bgImageView = (UIImageView *)[self.view viewWithTag:kBgPicViewTag];
    return bgImageView;
}
@end
