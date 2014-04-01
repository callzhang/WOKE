//
//  ImageViewController.h
//  Homepwner
//
//  Created by Lei Zhang on 12/14/12.
//  Copyright (c) 2012 Lei Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageViewController : EWViewController 
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImage *image;

@end
