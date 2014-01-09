//
//  ImageViewController.m
//  Homepwner
//
//  Created by Lei Zhang on 12/14/12.
//  Copyright (c) 2012 Lei Zhang. All rights reserved.
//

#import "ImageViewController.h"


@interface ImageViewController ()

@end

@implementation ImageViewController
@synthesize image, scrollView, imageView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

//display image
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    CGSize sz = self.image.size;
    scrollView.contentSize = sz;
    imageView.frame = CGRectMake(0, 0, sz.width, sz.height); //The frame rectangle, which describes the view’s location and size in its superview’s coordinate system.
    imageView.image = self.image;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    //[self setImageView:nil];
    //[self setScrollView:nil];
    [super viewDidUnload];
}

- (UIImage *)resizeImage:(UIImage *)img{
    // Resize image
    UIGraphicsBeginImageContext(CGSizeMake(640, 960));
    [img drawInRect: CGRectMake(0, 0, 640, 960)];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return smallImage;
}
@end
