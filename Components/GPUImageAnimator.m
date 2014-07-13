	//
//  GPUImageAnimator.m
//  NavigationTransitionTest
//
//  Created by Chris Eidhof on 9/28/13.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import "GPUImageAnimator.h"
#import "GPUImage.h"
#import "GPUImagePicture.h"
#import "GPUImagePixellateFilter.h"
#import "GPUImageView.h"
#import "UIViewController+Blur.h"
#import "GPUImageBrightnessFilter.h"

#import "EWAppDelegate.h"


static const float duration = 0.3;
static const float delay = 0.0;
static const float zoom = 1.5;
static const float initialDownSampling = 2;

@interface GPUImageAnimator ()

@property (nonatomic, strong) GPUImagePicture* blurImage;
@property (nonatomic, strong) GPUImageiOSBlurFilter* blurFilter;
@property (nonatomic, strong) GPUImageBrightnessFilter* brightnessFilter;
@property (nonatomic, strong) GPUImageView* imageView;
@property (nonatomic, strong) id <UIViewControllerContextTransitioning> context;
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic, strong) CADisplayLink* displayLink;
@end

@implementation GPUImageAnimator

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    self.imageView = [[GPUImageView alloc] init];
    //self.imageView.alpha = 0;
    self.imageView.opaque = NO;
    
    self.blurFilter = [[GPUImageiOSBlurFilter alloc] init];
    self.blurFilter.blurRadiusInPixels = 1;
    self.blurFilter.saturation = 1;
    self.blurFilter.rangeReductionFactor = 0;
    self.blurFilter.downsampling = initialDownSampling;
    //[self.blurFilter addTarget:self.imageView];
    
    self.brightnessFilter = [GPUImageBrightnessFilter new];
    self.brightnessFilter.brightness = 0;
    [self.blurFilter addTarget:self.brightnessFilter];
    [self.brightnessFilter addTarget:self.imageView];
    
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.displayLink.paused = YES;
}


- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return duration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    self.context = transitionContext;
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController.view.backgroundColor = [UIColor clearColor];
    if ([toViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)toViewController;
        nav.visibleViewController.view.backgroundColor = [UIColor clearColor];
    }
    UIView* container = [transitionContext containerView];
    UIView *fromView = fromViewController.view;
    UIView *toView = toViewController.view;
    
    self.imageView.frame = container.bounds;
    self.imageView.alpha = 1;
    [container addSubview:self.imageView];
    
    if (self.type == UINavigationControllerOperationPush || self.type == kModelViewPresent) {
      
        UIImage *fromViewImage = fromView.screenshot;
        
        self.blurImage = [[GPUImagePicture alloc] initWithImage:fromViewImage];
        [self.blurImage addTarget:self.blurFilter];
        //[self.blurFilter useNextFrameForImageCapture];
        
        //hide from view
        [fromView removeFromSuperview];
        
        [self triggerRenderOfNextFrame];
        
        self.startTime = 0;
        self.displayLink.paused = NO;
        
        //pre animation
        [[self.context containerView] addSubview:toView];
        toView.alpha = 0;
        toView.transform = CGAffineTransformMakeScale(zoom, zoom);
        
        
    }else if(self.type == UINavigationControllerOperationPop || self.type == kModelViewDismiss){
        
        [[self.context containerView] addSubview:fromView];
        
        //remove blur image
        UIView *blurView = [fromView viewWithTag:kBlurImageViewTag];
        [blurView removeFromSuperview];
        
        [UIView animateWithDuration:duration-delay animations:^{
            
            fromView.alpha = 0;
            fromView.transform = CGAffineTransformMakeScale(zoom, zoom);
            
        }completion:^(BOOL finished) {
            
            [fromView removeFromSuperview];
            [container addSubview:toViewController.view];
            [container sendSubviewToBack:toViewController.view];
            
        }];
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration - 0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIImage *toViewImage = toViewController.view.screenshot;
            self.blurImage = [[GPUImagePicture alloc] initWithImage:toViewImage];
            [self.blurImage addTarget:self.blurFilter];
            [self triggerRenderOfNextFrame];
            self.startTime = 0;
            self.displayLink.paused = NO;
        });
    }
}

- (void)triggerRenderOfNextFrame
{
    [self.blurImage processImage];
}

- (void)startInteractiveTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    [self animateTransition:transitionContext];
}

- (void)updateFrame:(CADisplayLink*)link
{
    [self updateProgress:link];
    self.brightnessFilter.brightness = -0.3 * self.progress;
    self.blurFilter.downsampling = initialDownSampling + self.progress * 6;
    self.blurFilter.blurRadiusInPixels = 1+ self.progress * 8;
    [self triggerRenderOfNextFrame];
    
    if (self.interactive) {
        return;
    }
    if ((self.type == UINavigationControllerOperationPush || self.type == kModelViewPresent) && self.progress == 1) {
        self.displayLink.paused = YES;
        UIViewController *toViewController = [self.context viewControllerForKey:UITransitionContextToViewControllerKey];
        UIView *toView = toViewController.view;
        
        //screenshot of blur image and insert to the destination view
        UIImage *blurImage = self.brightnessFilter.imageFromCurrentFramebuffer;
        UIImageView *blurImageView = [[UIImageView alloc] initWithFrame:toViewController.view.frame];
        blurImageView.image = blurImage;
        blurImageView.tag = kBlurImageViewTag;
        if ([toViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)toViewController;
            UIView *presentedView = nav.visibleViewController.view;
            
            [presentedView addSubview:self.imageView];
            [presentedView sendSubviewToBack:self.imageView];
        }else{
            [toView addSubview:self.imageView];
            [toView sendSubviewToBack:self.imageView];
        }

        //animation
        [UIView animateWithDuration:duration-delay delay:delay options:UIViewAnimationOptionTransitionNone animations:^{
            
            toView.alpha = 1;
            toView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            //=======> Present animation ended
            
            [self.context completeTransition:YES];
        }];
        
        
    }else if ((self.type == UINavigationControllerOperationPop || self.type == kModelViewDismiss) && self.progress == 0){
        
        //=======> Here is the point where the dismiss animation ended
        
        //unhide to view
        self.displayLink.paused = YES;
        [self.context completeTransition:YES];
        self.imageView.alpha = 0;
        
    }
}

//update progress
- (void)updateProgress:(CADisplayLink*)link
{
    if (self.interactive) return;
    
    if (self.startTime == 0) {
        self.startTime = link.timestamp;
    }
    
    
    float progress = MAX(0, MIN((link.timestamp - self.startTime) / duration, 1));
    
    if (self.type == UINavigationControllerOperationPush || self.type == kModelViewPresent) {
        self.progress = progress;
    }else if (self.type == UINavigationControllerOperationPop || self.type == kModelViewDismiss){
        self.progress = 1- progress;
    }
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    if (self.interactive) {
        [self.context updateInteractiveTransition:progress];
    }
}

- (void)finishTransition
{
    self.displayLink.paused = YES;
    if (self.interactive) {
        [self.context finishInteractiveTransition];
    }
    
}

- (void)cancelInteractiveTransition
{
    // TODO
}

- (void)animationEnded:(BOOL)transitionCompleted{
    self.displayLink.paused = YES;
}

@end