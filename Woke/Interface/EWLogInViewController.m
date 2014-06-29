//
//  EWLogInViewController.m
//  EarlyWorm
//
//  Created by Lei on 12/7/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWLogInViewController.h"
#import "EWAppDelegate.h"
#import "EWPersonStore.h"
#import "EWPerson.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "MBProgressHUD.h"
#import "EWUserManagement.h"
#define WhyFaceBook @"Lorem ipsum dolor sit amet,\nconsectertur adipisicing elit,sed do\neiusmod tempor incididunt ut\n labore et dolore magna aliqua Ut enim ad minim veniam."
@interface EWLogInViewController ()

@end

@implementation EWLogInViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    //observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView) name:kPersonLoggedIn object:nil];
    
    [self.indicator stopAnimating];
    [self updateView];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)updateView {

    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
//        [self.btnLoginLogout setTitle:@"Log out" forState:UIControlStateNormal];
    } else {
//        [self.btnLoginLogout setTitle:@"Login with Facebook" forState:UIControlStateNormal];
    }
    
    [self.indicator stopAnimating];
    
    if (me) {
        self.name.text = me.name;
        self.profileView.image = me.profilePic;
    }

}

//===============> Point of access <=================
- (IBAction)connect:(id)sender {
    [self.indicator startAnimating];
    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        NSLog(@"*** Log out. This should never happen");
        [self logoutUser];
    } else {
        [self loginUser];
    }
}

- (IBAction)check:(id)sender {
    NSLog(@"Current user: %@", me);
}


- (IBAction)skip:(id)sender {//this function will not be called
    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    [rootViewController dismissViewControllerAnimated:YES completion:NULL];
    [EWUserManagement loginWithDeviceIDWithCompletionBlock:^{
        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
    }];
}

- (IBAction)logout:(id)sender {
    [self.indicator startAnimating];
    if (FBSession.activeSession.state == FBSessionStateOpen) {
        [self logoutUser];
    }
}

- (IBAction)whyFacebookPopup:(id)sender {
    
    UIAlertView *alertV = [[UIAlertView alloc] initWithTitle:@"Why Facebook?" message:WhyFaceBook delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertV show];
    
}

#pragma mark - Login & Logout
- (void)loginUser {
    //[self.indicator startAnimating];
    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    
    //leaving
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    [EWUserManagement loginParseWithFacebookWithCompletion:^{
        //update UI
        [self updateView];//notification also used
        
        
    }];
    
}

- (void)logoutUser {
    [EWUserManagement logout];
    [self.indicator stopAnimating];
    self.profileView.image = [UIImage imageNamed:@"profile"];
}


@end
