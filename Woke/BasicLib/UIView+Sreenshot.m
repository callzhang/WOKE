//
//  UIView+Sreenshot.m
//  Woke
//
//  Created by apple on 14-4-27.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "UIView+Sreenshot.h"

@implementation UIView (Sreenshot)

- (UIImage *)screenshot{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, self.window.screen.scale);
    
//    /* iOS 7 */
//    if ([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
//        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
//    else /* iOS 6 */
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

@end
