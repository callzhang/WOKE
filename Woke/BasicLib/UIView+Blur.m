//
//  UIView+Blur.m
//  Woke
//
//  Created by apple on 14-4-27.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "UIView+Blur.h"

@implementation UIView (Blur)
-(id)initWithBlurBockground
{
    CGRect deviceSize = [UIScreen mainScreen].bounds;
    
    GPUImageView *blurview=[[GPUImageView alloc]initWithFrame:CGRectMake(0, 0, deviceSize.size.width, deviceSize.size.height)];
    
    GPUImageiOSBlurFilter *blurfilter=[[GPUImageiOSBlurFilter alloc] init];
    blurfilter.blurRadiusInPixels=4.0f;
    
    UIImage *image = [self.superview convertViewToImage];
    
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
    [picture addTarget:blurfilter];
    [blurfilter addTarget:blurview];
    [picture processImage];
    
    return blurview;
}

-(UIImage *)convertViewToImage
{
    UIGraphicsBeginImageContext(self.bounds.size);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}




@end
