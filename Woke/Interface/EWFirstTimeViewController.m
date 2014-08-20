//
//  EWFirstTimeViewController.m
//  Woke
//
//  Created by mq on 14-8-11.
//  Copyright (c) 2014年 WokeAlarm.com. All rights reserved.
//

#import "EWUIUtil.h"
#import "EWUserManagement.h"
#import "../../Components/MYBlurIntroductionView/MYBlurIntroductionView.h"
#import "../../Components/MYBlurIntroductionView/MYIntroductionPanel.h"

#import "EWFirstTimeViewController.h"

@interface EWFirstTimeViewController ()<MYIntroductionDelegate>
{
    MYBlurIntroductionView *introductionView;
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
     
        
        
        MYIntroductionPanel *panel1 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Welcome to MYBlurIntroductionView" description:@"MYBlurIntroductionView is a powerful platform for building app introductions and tutorials. Built on the MYIntroductionView core, this revamped version has been reengineered for beauty and greater developer control." image:[UIImage imageNamed:@"New-Version_03.png"]];
        
        //Create stock panel with image
        MYIntroductionPanel *panel2 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Automated Stock Panels" description:@"Need a quick-and-dirty solution for your app introduction? MYBlurIntroductionView comes with customizable stock panels that make writing an introduction a walk in the park. Stock panels come with optional overlay on background images. A full panel is just one method away!" image:[UIImage imageNamed:@"New-Version_03-02.png"]];
        
        MYIntroductionPanel *panel3 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Automated Stock Panels" description:@"Need a quick-and-dirty solution for your app introduction? MYBlurIntroductionView comes with customizable stock panels that make writing an introduction a walk in the park. Stock panels come with optional overlay on background images. A full panel is just one method away!" image:[UIImage imageNamed:@"New-Version_03-04.png"]];
        MYIntroductionPanel *panel4 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) title:@"Automated Stock Panels" description:@"Need a quick-and-dirty solution for your app introduction? MYBlurIntroductionView comes with customizable stock panels that make writing an introduction a walk in the park. Stock panels come with optional overlay on background images. A full panel is just one method away!" image:[UIImage imageNamed:@"New-Version_03-05.png"]];
        MYIntroductionPanel *panel5 = [[MYIntroductionPanel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) nibNamed:@"EWLogInViewController"];
    
        //Add custom attributes
        //        panel3.PanelTitle = @"Test Title";
        //        panel3.PanelDescription = @"This is a test panel description to test out the new animations on a custom nib";
        
        //Rebuild panel with new attributes
        //        [panel3 buildPanelWithFrame:CGRectMake(0, 0, vc.view.frame.size.width, vc.view.frame.size.height)];
        //    //Feel free to customize your introduction view here
        //
        //    //Add panels to an array
        NSArray *panels = @[panel1, panel2,panel3,panel4,panel5];
        //
        //    //Build the introduction with desired panels
        [introductionView buildIntroductionWithPanels:panels];
    
//        [introductionView ]
        [self.view addSubview:introductionView];
        [self.view bringSubviewToFront:introductionView];
        
        [EWUtil setFirstTimeLoginOver];
    
//     [EWUtil setFirstTimeLoginOver];
    // Do any additional setup after loading the view from its nib.
    
}
-(void)introduction:(MYBlurIntroductionView *)introductionView didFinishWithType:(MYFinishType)finishType
{
//    [self dismissViewControllerAnimated:NO completion:^(){
//        [EWUserManagement login];
//    }];
}
-(void)didPressSkipButton
{
    [introductionView changeToPanelAtIndex:4];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
