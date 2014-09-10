//
//  EWFirstTimeViewController.m
//  Woke
//
//  Created by mq on 14-8-11.
//  Copyright (c) 2014年 WokeAlarm.com. All rights reserved.
//

#import "EWAppDelegate.h"
#import "MYBlurIntroductionView.h"
#import "MYIntroductionPanel.h"
//#import "EWLogInViewController.h"
#import "EWUserManagement.h"
#import "EWFirstTimeViewController.h"

@interface EWFirstTimeViewController ()<MYIntroductionDelegate>
{
    MYBlurIntroductionView *introductionView;
    NSInteger  _lastIndex ;
    //EWLogInViewController *loginController;
    UIActivityIndicatorView *loading;
}
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
    
    
    
        //Create the introduction view and set its delegate
        introductionView = [[MYBlurIntroductionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        introductionView.delegate = self;
        introductionView.BackgroundImageView.image = [UIImage imageNamed:@"Background.png"];
        //introductionView.LanguageDirection = MYLanguageDirectionRightToLeft;
        //Create stock panel with header
        //    UIView *headerView = [[NSBundle mainBundle] loadNibNamed:@"TestHeader" owner:nil options:nil][0];
     
        
        
        MYIntroductionPanel *panel1 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Welcome to MYBlurIntroductionView" description:@"MYBlurIntroductionView is a powerful platform for building app introductions and tutorials. Built on the MYIntroductionView core, this revamped version has been reengineered for beauty and greater developer control." image:[UIImage imageNamed:@"Picture1.png"]];
        
        //Create stock panel with image
        MYIntroductionPanel *panel2 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Automated Stock Panels" description:@"Need a quick-and-dirty solution for your app introduction? MYBlurIntroductionView comes with customizable stock panels that make writing an introduction a walk in the park. Stock panels come with optional overlay on background images. A full panel is just one method away!" image:[UIImage imageNamed:@"Picture2.png"]];
        
        MYIntroductionPanel *panel3 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Automated Stock Panels" description:@"Need a quick-and-dirty solution for your app introduction? MYBlurIntroductionView comes with customizable stock panels that make writing an introduction a walk in the park. Stock panels come with optional overlay on background images. A full panel is just one method away!" image:[UIImage imageNamed:@"Picture3.png"]];
        MYIntroductionPanel *panel4 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Automated Stock Panels" description:@"Need a quick-and-dirty solution for your app introduction? MYBlurIntroductionView comes with customizable stock panels that make writing an introduction a walk in the park. Stock panels come with optional overlay on background images. A full panel is just one method away!" image:[UIImage imageNamed:@"Picture4.png"]];
        MYIntroductionPanel *panel5 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"EWLogInView"];

    
    panel5.backgroundColor = [UIColor clearColor];
    UIButton *loginButton = (UIButton *)[panel5 viewWithTag:99];
    UIButton *alertButton = (UIButton *)[panel5 viewWithTag:98];
    UIButton *skipButton = (UIButton *)[panel5 viewWithTag:97];
    loading = (UIActivityIndicatorView *)[panel5 viewWithTag:96];
    
    //loginController = [[EWLogInViewController alloc] init];
    [loginButton addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
    [alertButton addTarget:self action:@selector(whyFacebookAlert:) forControlEvents:UIControlEventTouchUpInside];
    [skipButton addTarget:self action:@selector(skip:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray *panels = @[panel1, panel2, panel3, panel4, panel5];
    _lastIndex = [panels count] - 1;
        //
        //    //Build the introduction with desired panels
        [introductionView buildIntroductionWithPanels:panels];
    
//        [introductionView ]
    [self.view addSubview:introductionView];
    [self.view bringSubviewToFront:introductionView];
    
    [EWUtil setFirstTimeLoginOver];
    
}


- (void)introduction:(MYBlurIntroductionView *)introductionView didFinishWithType:(MYFinishType)finishType{
    [self didPressSkipButton];
}

- (void)didPressSkipButton{
    [introductionView changeToPanelAtIndex:_lastIndex];
    [introductionView.MasterScrollView setScrollEnabled:NO ];
    [introductionView.RightSkipButton setHidden:YES];
    [introductionView.PageControl setHidden:YES];
}


- (void)introduction:(MYBlurIntroductionView *)introductionView didChangeToPanel:(MYIntroductionPanel *)panel withIndex:(NSInteger)panelIndex
{
    if (panelIndex == _lastIndex) {
        [self didPressSkipButton];
    }
}


#pragma mark - ButtonPressed
- (IBAction)login:(id)sender
{
    [loading startAnimating];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    
    [EWUserManagement loginParseWithFacebookWithCompletion:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [loading stopAnimating];
        //leaving
        [rootViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    }];
    
}

- (IBAction)skip:(id)sender {//this function will not be called
    [loading startAnimating];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [EWUserManagement loginWithDeviceIDWithCompletionBlock:^{
        [loading stopAnimating];
        [rootViewController dismissViewControllerAnimated:YES completion:NULL];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
}

-(void)whyFacebookAlert:(id)sender
{
    UIAlertView *alertV = [[UIAlertView alloc] initWithTitle:@"Why Facebook?"
                                                     message:@"Lorem ipsum dolor sit amet,\nconsectertur adipisicing elit,sed do\neiusmod tempor incididunt ut\n labore et dolore magna aliqua Ut enim ad minim veniam."
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles: nil];
    [alertV show];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
