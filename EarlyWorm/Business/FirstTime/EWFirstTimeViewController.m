//
//  EWFirstTimeViewController.m
//  EarlyWorm
//
//  Created by Lei on 11/12/13.
//  Copyright (c) 2013 Lei Zhang. All rights reserved.
//
// This class handles user login and data initilization

#import "EWFirstTimeViewController.h"
#import "EWDatabaseDefault.h"
#import "StackMob.h"

@interface EWFirstTimeViewController ()

@end

@implementation EWFirstTimeViewController

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
    refreshHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:refreshHUD];
    refreshHUD.delegate = self;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    
}

#pragma mark - UI action
- (IBAction)start:(id)sender {
    [refreshHUD show:YES];
    [self.view setNeedsDisplay];
    //=======init view=========
    NSLog(@"User logged in, start init");
    //User defaults
    //[EWDatabaseDefault.sharedInstance registerDefaultOptions];
    
    [EWDatabaseDefault.sharedInstance initData];
    
    //[EWDatabaseDefault.sharedInstance check];
    
    [refreshHUD hide:YES];
    [self dismissViewControllerAnimated:YES completion:^{
        //[self finishLogin];
    }];
}

#pragma mart - login & logout
- (void)finishLogin{
    NSDictionary *option = @{@"firstTime": @"NO"};
   [[NSUserDefaults standardUserDefaults] registerDefaults:option];
}

-(void)finishLogout{
    NSDictionary *option = @{@"firstTime": @"YES"};
    [[NSUserDefaults standardUserDefaults] registerDefaults:option];
}


@end
