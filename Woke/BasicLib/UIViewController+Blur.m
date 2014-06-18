//
//  UIViewController+Blur.m
//  EarlyWorm
//
//  Created by Lei on 3/23/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "UIViewController+Blur.h"

#define kBlurViewTag       345
#define kBlurImageTag      435

@implementation UIViewController (Blur)

- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController{
 
 [self presentViewControllerWithBlurBackground:viewController completion:NULL];
 
}

- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController completion:(void (^)(void))block{
 [self presentViewControllerWithBlurBackground:viewController option:EWBlurViewOptionBlack completion:block];
}


- (void)presentViewControllerWithBlurBackground:(UIViewController *)viewController option:(EWBlurViewOptions)blurOption completion:(void (^)(void))block{
 //clear background
 viewController.view.backgroundColor = [UIColor clearColor];
 
 //blur toolbar
 UIToolbar *bgToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
 bgToolbar.tag = kBlurViewTag;
 if (blurOption == EWBlurViewOptionWhite) {
  bgToolbar.barStyle = UIBarStyleDefault;
 }else{
  bgToolbar.barStyle = UIBarStyleBlack;
 }
 
 UIViewController *navC ;
 if ([viewController isKindOfClass:[UINavigationController class]]) {
   UINavigationController * nav = (UINavigationController *)viewController;
    navC = nav;
    viewController =nav.visibleViewController;
 }
 else
 {
  navC = viewController;
 }
//  [viewController.view addSubview:bgToolbar];
//  [viewController.view sendSubviewToBack:bgToolbar];
//  
//  [self presentViewController:navC animated:YES completion:^{
//   //before get image, get rid of blur layer
//   [self.view viewWithTag:kBlurViewTag].hidden = YES;
//   
//   //get CALayer image
//   
//   UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
//   
//   [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
//   CGContextRef contextRef = UIGraphicsGetCurrentContext();
//   [self.view.layer renderInContext:contextRef];
//   UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
//   UIGraphicsEndImageContext();
//   
//   //get image
//   UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.view.frame];
//   imgView.image = img;
//   imgView.tag = kBlurImageTag;
//   [viewController.view addSubview:imgView];
//   [viewController.view sendSubviewToBack:imgView];
//   
//   //callback
//   if (block) {
//    block();
//   }
//   
//   
//  }];
//  
//  return;
// }
 [viewController.view addSubview:bgToolbar];
 [viewController.view sendSubviewToBack:bgToolbar];
 
 [self presentViewController:navC animated:YES completion:^{
  //before get image, get rid of blur layer
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
  [viewController.view addSubview:imgView];
  [viewController.view sendSubviewToBack:imgView];
  
  //callback
  if (block) {
   block();
  }
 }];
}


- (void)dismissBlurViewControllerWithCompletionHandler:(void(^)(void))completion{
 UIView *view = [self.view viewWithTag:kBlurViewTag];
 view.hidden = NO;
 [self.view setNeedsDisplay];
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
  UIView *view = [self.presentedViewController.view viewWithTag:kBlurImageTag];
  [view removeFromSuperview];
 });
 [self dismissViewControllerAnimated:YES completion:completion];
}



@end
