//
//  EWLogInViewController.m
//  EarlyWorm
//
//  Created by Lei on 12/7/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWLogInViewController.h"
#import "EWAppDelegate.h"
#import "StackMob.h"
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

+(EWLogInViewController *)sharedInstance{
    static EWLogInViewController *loginVC = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loginVC = [[EWLogInViewController alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:loginVC selector:@selector(updateView) name:kPersonLoggedIn object:nil];
    });
    
    return loginVC;
}




- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.indicator stopAnimating];
    [self updateView];
    
    //If fb has already a token, log in SM.
    
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        [[[UIAlertView alloc] initWithTitle:@"Login" message:@"Do you want to log in with current Facebook information?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateView {

    if (FBSession.activeSession.state == (FBSessionStateCreatedTokenLoaded | FBSessionStateOpenTokenExtended)) {
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
    if (FBSession.activeSession.state == FBSessionStateOpen) {
        [self logoutUser];
    } else {
        [self openSession];
    }
}

- (IBAction)check:(id)sender {
    NSLog(@"%@",[client isLoggedIn] ? @"Logged In" : @"Logged Out");
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



//start register
- (void)openSession
{
    
    [EWUserManagement openFacebookSessionWithCompletion:^{
         [self sessionStateChanged:FBSession.activeSession state:FBSession.activeSession.state error:NULL];
     }];
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            [self loginUser];
            break;
            
        case FBSessionStateOpenTokenExtended:
            [self loginUser];
            break;
            
        case FBSessionStateClosed:
            [FBSession.activeSession closeAndClearTokenInformation];
            //[self updateView];
            break;
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            NSLog(@"*** FB login failed. Session closed");
            break;
        default:
            break;
    }
    
    if (error) {
        
        [EWUserManagement handleFacebookException:error];
    }
}

#pragma mark - Login & Logout
- (void)loginUser {
    
    [EWUserManagement loginUsingFacebookWithCompletion:^{
        //update UI
        //[self updateView];//notification used
        
        //stop indicator
        //[self.indicator stopAnimating];//notifiaction used
        
        //leaving
        [self dismissViewControllerAnimated:YES completion:NULL];
    }];
    
}

- (void)logoutUser {
    [EWUserManagement logout];
    [self.indicator stopAnimating];
    self.profileView.image = [UIImage imageNamed:@"profile"];
}


#pragma mark - Background login
- (void)loginInBackground{
    NSLog(@"Log in fb in background");
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        NSLog(@"Starting to log in fb with cached info");
        
        [self sessionStateChanged:FBSession.activeSession state:FBSession.activeSession.state error:nil];
        
    }else{
        [self openSession];
    }

}


#pragma mark - Alert Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    [self loginInBackground];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPersonLoggedIn object:nil];
}

@end
