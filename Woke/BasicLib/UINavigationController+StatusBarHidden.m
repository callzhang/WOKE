//
//  UINavigationController+StatusBarHidden.m
//  Woke
//
//  Created by Lee on 7/21/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "UINavigationController+StatusBarHidden.h"


@implementation UINavigationController(StatusBarHidden)

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
