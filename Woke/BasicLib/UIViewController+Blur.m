//
//  UIViewController+Blur.m
//  EarlyWorm
//
//  Created by Lei on 3/23/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "UIViewController+Blur.h"

@implementation UIViewController (Blur)

- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController{
    
    //clear background
    viewController.view.backgroundColor = [UIColor clearColor];
    
    //blur toolbar
    UIToolbar *bgToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
    bgToolbar.barStyle = UIBarStyleDefault;
    bgToolbar.barStyle = UIBarStyleBlack;
    [viewController.view addSubview:bgToolbar];
    [viewController.view sendSubviewToBack:bgToolbar];
    
    [self presentViewController:viewController animated:YES completion:^{
        //get CALayer image
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        //CGContextRef contextRef = UIGraphicsGetCurrentContext();
        //[self.view.layer performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)(contextRef) waitUntilDone:YES];
        UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        //get image
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.view.frame];
        imgView.image = img;
        imgView.tag = 99;
        [viewController.view addSubview:imgView];
        [viewController.view sendSubviewToBack:imgView];
    }];
    
}

- (void)dismissViewControllerWithBlurBackground:(UIViewController *)viewController{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIView *view = [viewController.view viewWithTag:99];
        [view removeFromSuperview];
    });
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
