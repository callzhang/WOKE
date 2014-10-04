//
//  GPUBlurAnimator.h
//  WokeAlarm
//
//  Created by Lei on 9/28/13.
//  Copyright (c) 2013 Woke. All rights reserved.
//

#import "GPUImageAnimator.h"
#import "GPUImage.h"
#import "GPUImagePicture.h"
#import "GPUImagePixellateFilter.h"
#import "GPUImageView.h"
#import "UIViewController+Blur.h"
#import "GPUImageTransformFilter.h"
#import "GPUImageToneCurveFilter.h"
#import "GPUImageNormalBlendFilter.h"
//#import "EWAppDelegate.h"


static const float duration = 0.3;
static const float delay = 0.1;
static const float zoom = 1.5;
static const float initialDownSampling = 2;


@interface GPUImageAnimator (){
	UIViewController* toViewController;
	UIViewController* fromViewController;
	UIView* container;
	UIView *fromView;
	UIView *toView;
}

@property (nonatomic, strong) GPUImagePicture* blurImage;
@property (nonatomic, strong) GPUImageTransformFilter *zoomFilter;
@property (nonatomic, strong) GPUImageiOSBlurFilter* blurFilter;
@property (nonatomic, strong) GPUImageToneCurveFilter* brightnessFilter;
@property (nonatomic, strong) GPUImageView* imageView;
//@property (nonatomic, strong) GPUImageNormalBlendFilter *blendFilter;
//@property (nonatomic, strong) GPUImagePicture *baseImage;
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
	//self.blendFilter = [[GPUImageNormalBlendFilter alloc] init];
	self.zoomFilter = [[GPUImageTransformFilter alloc] init];
    self.blurFilter = [[GPUImageiOSBlurFilter alloc] init];
    self.blurFilter.rangeReductionFactor = 0;
    self.brightnessFilter = [[GPUImageToneCurveFilter alloc] init];
	
	//[self.zoomFilter addTarget:self.blendFilter];
	[self.zoomFilter addTarget:self.blurFilter];
    [self.blurFilter addTarget:self.brightnessFilter];
    
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
    toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController.view.backgroundColor = [UIColor clearColor];
    if ([toViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)toViewController;
        nav.visibleViewController.view.backgroundColor = [UIColor clearColor];
    }
    container = [transitionContext containerView];
    fromView = fromViewController.view;
    toView = toViewController.view;
	
	//try to find GPUImageView in container first
	GPUImageView *view = (GPUImageView*)[container viewWithTag:kGPUImageViewTag];
	if (!view) {
		self.imageView = [[GPUImageView alloc] init];
		self.imageView.tag = kGPUImageViewTag;
		self.imageView.frame = container.bounds;
		self.imageView.backgroundColor = [UIColor clearColor];
		[container addSubview:self.imageView];
	}else{
		self.imageView = view;
		self.imageView.alpha = 1;
	}
	
	[self.brightnessFilter removeAllTargets];
	[self.brightnessFilter addTarget:self.imageView];
	
	//init timer
	self.startTime = 0;
	
    if (self.type == UINavigationControllerOperationPush || self.type == kModelViewPresent) {
		
        //pre animation toView set up
        toView.alpha = 0.01;
        toView.transform = CGAffineTransformMakeScale(zoom, zoom);
        [container addSubview:toView];
        
        //GPU image setup
        UIImage *fromViewImage = fromView.screenshot;
//		_baseImage = [[GPUImagePicture alloc] initWithImage:fromViewImage];
//		[_baseImage processImage];
//		[_baseImage addTarget:self.blendFilter];
		self.blurImage = nil;
        self.blurImage = [[GPUImagePicture alloc] initWithImage:fromViewImage];
        [self.blurImage addTarget:self.zoomFilter];
		//[self.zoomFilter addTarget:self.blendFilter];
		[self updateFrame:nil];
        
        //trigger GPU rendering
        self.displayLink.paused = NO;
        
        //animation
        [UIView animateWithDuration:duration delay:delay + 0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            toView.alpha = 1;
            toView.transform = CGAffineTransformIdentity;
        } completion:NULL];
        
        
    }else if(self.type == UINavigationControllerOperationPop || self.type == kModelViewDismiss){
		//take a new screenshot and render the imageView
		UIImage *toViewImage = toView.screenshot;
//		_baseImage = [[GPUImagePicture alloc] initWithImage:toViewImage];
//		[_baseImage processImage];
//		[_baseImage addTarget:self.blendFilter];
		self.blurImage = [[GPUImagePicture alloc] initWithImage:toViewImage];
		[self.blurImage addTarget:self.zoomFilter];
		//[self.zoomFilter addTarget:self.blendFilter];
		[self updateFrame:nil];
		
		fromView.transform = CGAffineTransformIdentity;
		
        [UIView animateWithDuration:duration-delay animations:^{
            
            fromView.alpha = 0;
            fromView.transform = CGAffineTransformMakeScale(zoom, zoom);
            
        }completion:^(BOOL finished) {
            
            [fromView removeFromSuperview];
            
        }];
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			//start the animation
            self.displayLink.paused = NO;
        });
    }
}

- (void)triggerRenderOfNextFrame
{
	BOOL active = [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
	if (active) {
		[self.blurImage processImage];
	}
}

- (void)startInteractiveTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    [self animateTransition:transitionContext];
}

- (void)updateFrame:(CADisplayLink*)link
{
    [self updateProgress:link];
	//[self.zoomFilter setAffineTransform:CGAffineTransformMakeScale(1 - 0.05 * _progress, 1 - 0.05 * _progress)];
	[self.brightnessFilter setRgbCompositeControlPoints:@[[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)],
												[NSValue valueWithCGPoint:CGPointMake(0.3, 0.3 - 0.1 * _progress)],
												[NSValue valueWithCGPoint:CGPointMake(0.7, 0.7 - 0.3 * _progress)],
												[NSValue valueWithCGPoint:CGPointMake(1.0, 1.0 - 0.4 * _progress)]]];
	self.blurFilter.saturation = 1 + 0.2 * _progress;
    self.blurFilter.downsampling = initialDownSampling + _progress * 4;
    self.blurFilter.blurRadiusInPixels = 1 + _progress * 9;
    [self triggerRenderOfNextFrame];
    
	NSAssert(!self.interactive, @"Interactive transition is not supported");
	
    if ((self.type == UINavigationControllerOperationPush || self.type == kModelViewPresent)) {
		if (_progress>0) {
			fromView.alpha = 0;
		}
			
		if (_progress == 1) {
			self.displayLink.paused = YES;
			[self.context completeTransition:YES];
		}
		
    }else if (_progress == 0 && (self.type == UINavigationControllerOperationPop || self.type == kModelViewDismiss)){
        
        //=======> dismiss animation ended
        
        //unhide to view'
        self.displayLink.paused = YES;
        [self.context completeTransition:YES];
		
        if (self.type == UINavigationControllerOperationPop) {
			[[self.context containerView] addSubview:toView];
			self.imageView.alpha = 0;
        }
		
		//make toView visible
		toView.alpha = 1;
		toView.hidden = NO;
        
    }
}

//update progress
- (void)updateProgress:(CADisplayLink*)link
{
    if (self.interactive) return;
	float progress;
	
    if (self.startTime == 0) {
        self.startTime = link.timestamp;
    }
	
	if (link) {
		progress = MAX(0, MIN((link.timestamp - self.startTime) / duration, 1));
	}else{
		//used for precalculation
		progress = 0;
	}
	
    
    if (self.type == UINavigationControllerOperationPush || self.type == kModelViewPresent) {
        _progress = progress;
    }else if (self.type == UINavigationControllerOperationPop || self.type == kModelViewDismiss){
        _progress = 1- progress;
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
	BOOL active = [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
	if (self.type == kModelViewPresent && !active) {
		//rander the last frame when app become active
		__weak GPUImageAnimator *weakSelf = self;
		__block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			NSLog(@"Application did become active, render last frame of presenting blur image");
			weakSelf.blurImage = [[GPUImagePicture alloc] initWithImage:fromView.screenshot];
			[weakSelf.blurImage addTarget:weakSelf.zoomFilter];
			[weakSelf.blurImage processImage];
			[[NSNotificationCenter defaultCenter] removeObserver:observer];
		}];

	}
    self.displayLink.paused = YES;
}

@end