//
//  GPUImageAnimator.h
//  NavigationTransitionTest
//
//  Created by Chris Eidhof on 9/28/13.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#define kModelViewPresent       101
#define kModelViewDismiss       102

#import <Foundation/Foundation.h>

@class GPUImageDissolveBlendFilter;
@class GPUImagePicture;
@class GPUImagePixellateFilter;
@class GPUImageView;


@interface GPUImageAnimator : NSObject
<UIViewControllerAnimatedTransitioning,
UIViewControllerInteractiveTransitioning>

@property (nonatomic) BOOL interactive;
@property (nonatomic) CGFloat progress;
@property (nonatomic) NSInteger type;
@property (nonatomic) BOOL isPresented;

- (void)finishTransition;
- (void)cancelInteractiveTransition;

@end
