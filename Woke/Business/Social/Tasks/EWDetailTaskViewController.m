//
//  EWDetailTaskViewController.m
//  EarlyWorm
//
//  Created by Lei on 9/6/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWDetailTaskViewController.h"

@interface EWDetailTaskViewController ()

@end

@implementation EWDetailTaskViewController
@synthesize alarm, task, person;

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
