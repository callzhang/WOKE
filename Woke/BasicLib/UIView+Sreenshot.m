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


- (UIImage *)screenshot{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0);
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    [self.layer renderInContext:contextRef];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

@end
