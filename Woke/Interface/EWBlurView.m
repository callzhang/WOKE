//
//  EWBlurView.m
//  Woke
//
//  Created by apple on 14-4-27.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWBlurView.h"

@implementation EWBlurView
{
    GPUImageView *_blurView;
    UIView *_backgroundView;
    GPUImageiOSBlurFilter *_blurFilter;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self updateBlur];
        _blurView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        _blurView.clipsToBounds = YES;
        _blurView.layer.contentsGravity = kCAGravityTop;
        [self addSubview:_blurView];
    }
    return self;
}
-(void)updateBlur{
    if(_blurFilter == nil){
        _blurFilter = [[GPUImageiOSBlurFilter alloc] init];
        _blurFilter.blurRadiusInPixels = 4.0f;
    }
    
    UIImage *image = [self.superview convertViewToImage];
    
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
    [picture addTarget:_blurFilter];
    [_blurFilter addTarget:_blurView];
    
    [picture processImageWithCompletionHandler:^{
        [_blurFilter removeAllTargets];
    }];
    
}

//-(void)updateBlur
//{
//    if(_blurFilter == nil){
//        _blurFilter = [[GPUImageiOSBlurFilter alloc] init];
//        _blurFilter.blurRadiusInPixels = 4.0f;
//        
//    }
//    UIImage *image = [self.superview convertViewToImage];
//    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
//    [picture addTarget:_blurFilter];
//    [_blurFilter addTarget:_blurView];
//    [picture processImageWithCompletionHandler:^{
//    [_blurFilter removeAllTargets];
//    }];}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
