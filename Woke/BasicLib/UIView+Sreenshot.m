//
//  UIView+Sreenshot.m
//  Woke
//
//  Created by apple on 14-4-27.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "UIView+Sreenshot.h"

@implementation UIView (Sreenshot)

-(UIImage *)convertViewToImage
{
    UIGraphicsBeginImageContext(self.bounds.size);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
