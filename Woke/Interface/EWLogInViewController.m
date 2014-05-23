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
        [self.btnLoginLogout setTitle:@"Log out" forState:UIControlStateNormal];
    } else {
        [self.btnLoginLogout setTitle:@"Login with Facebook" forState:UIControlStateNormal];
    }
    
    [self.indicator stopAnimating];
    
    if (currentUser) {
        self.name.text = currentUser.name;
        self.profileView.image = currentUser.profilePic;
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
    NSLog(@"Current user: %@", currentUser);
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

#pragma mark - Login & Logout
- (void)loginUser {
    [self.indicator startAnimating];
    [EWUserManagement loginParseWithFacebookWithCompletion:^{
        //update UI
        [self updateView];//notification also used
        
        //leaving
        [self dismissViewControllerAnimated:YES completion:NULL];
    }];
    
}

- (void)logoutUser {
    [EWUserManagement logout];
    [self.indicator stopAnimating];
    self.profileView.image = [UIImage imageNamed:@"profile"];
}


@end
