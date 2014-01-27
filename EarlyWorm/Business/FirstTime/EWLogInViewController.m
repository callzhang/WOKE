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
    });
    
    return loginVC;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //user login
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView) name:kPersonLoggedIn object:nil];

        
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.indicator stopAnimating];
    [self updateView];
    self.proceedBtn.alpha = 0;
    
    //If fb has already a token, log in SM.
    
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        NSLog(@"Starting to log in fb with cached info");
        [self.indicator startAnimating];
        [self.btnLoginLogout setTitle:@"Loading..." forState:UIControlStateNormal];
        
        [FBSession openActiveSessionWithReadPermissions:nil allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [self sessionStateChanged:session state:status error:error];
        }];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateView {
    
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        [self.btnLoginLogout setTitle:@"Log out" forState:UIControlStateNormal];
    } else {
        [self.btnLoginLogout setTitle:@"Login with Facebook" forState:UIControlStateNormal];
    }
    
    if (currentUser) {
        self.name.text = currentUser.name;
        self.profileView.image = currentUser.profilePic;
    }

}

- (IBAction)connect:(id)sender {
    [self.indicator startAnimating];
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        [self logoutUser];//this should never happen
    } else {
        [self openSession];
    }
}

- (IBAction)check:(id)sender {
    NSLog(@"%@",[client isLoggedIn] ? @"Logged In" : @"Logged Out");
    NSLog(@"Current user: %@", currentUser);
}


- (IBAction)proceed:(id)sender {//this function will not be called
    /*
    //save image to user
    currentUser.profilePic = self.profileView.image;
    [context saveOnSuccess:^{
        //check default
        [[EWDataStore sharedInstance] setDefault];
        
        //leaving
        [self dismissViewControllerAnimated:YES completion:NULL];
        
        //broadcasting
        [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{@"User": currentUser}];
        
        //hide hud if possible
        EWAppDelegate *delegate = (EWAppDelegate *)[UIApplication sharedApplication].delegate;
        [MBProgressHUD hideAllHUDsForView:delegate.window.rootViewController.view animated:YES];
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error on saving new user info" format:@"Reason: %@", error.description];
    }];*/
}



//start register
- (void)openSession
{
    NSArray *permissions = @[@"basic_info",
                             @"user_location",
                             @"user_birthday",
                             @"email",
                             @"user_photos"];
    
    [FBSession openActiveSessionWithReadPermissions:permissions
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            [self loginUser];
            break;
        case FBSessionStateClosed:
            [FBSession.activeSession closeAndClearTokenInformation];
            //[self updateView];
            break;
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - Login & Logout
- (void)loginUser {
    
    
    /*
     Initiate a request for the current Facebook session user info, and apply the username to
     the StackMob user that might be created if one doesn't already exist.  Then login to StackMob with Facebook credentials.
     */
    [[FBRequest requestForMe] startWithCompletionHandler:
     ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
         if (!error) {
             EWPerson *oldUser = currentUser;
             [client loginWithFacebookToken:FBSession.activeSession.accessTokenData.accessToken createUserIfNeeded:YES usernameForCreate:user.username onSuccess:^(NSDictionary *result) {
                 NSLog(@"Logged in facebook for:%@", user.name);
                 
                 if ([oldUser.username isEqualToString:user.username] && oldUser.username) {
                     NSLog(@"Facebook user %@ has already registered on StackMob", user.username);
                     [[EWUserManagement sharedInstance] updateUserWithFBData:user];
                 }else{
                     //new user, direct overwrite local info
                     NSLog(@"Facebook user %@ is new to StackMob server, start overwriting user info", user.username);
                     [[EWUserManagement sharedInstance] updateUserWithFBData:user];
                 }
                 [self updateView];
                 
                 //stop indicator
                 [self.indicator stopAnimating];
                 
                 //leaving
                 [self dismissViewControllerAnimated:YES completion:^{
                     [context saveOnSuccess:^{
                         NSLog(@"User %@ logged in from facebook", user.username);
                     } onFailure:^(NSError *error) {
                         NSLog(@"Unable to save user info");
                     }];
                 }];
                 
             }onFailure:^(NSError *error) {
                 NSLog(@"Error: %@", error);
             }];
         } else {
             // Handle error accordingly
             NSLog(@"Error getting current Facebook user data, %@", error);
         }
         
         
         
     }];
}

- (void)logoutUser {
    [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedOut object:self userInfo:nil];
    [client logoutOnSuccess:^(NSDictionary *result) {
        NSLog(@"Logged out of StackMob");
        [FBSession.activeSession closeAndClearTokenInformation];
        [self.indicator stopAnimating];
        self.profileView.image = [UIImage imageNamed:@"profile"];
        [self updateView];
    } onFailure:^(NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}


- (void)loginInBackground{
    NSLog(@"Log in fb in background");
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        NSLog(@"Starting to log in fb with cached info");
        
        [FBSession openActiveSessionWithReadPermissions:nil allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [self sessionStateChanged:session state:status error:error];
        }];
    }else{
        [self connect:nil];
    }

}



@end
