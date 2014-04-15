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
    [[EWUserManagement sharedInstance] loginWithDeviceIDWithCompletionBlock:^{
        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
    }];
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
            NSLog(@"*** FB login failed. Session closed");
            break;
        default:
            break;
    }
    
    if (error) {
        NSLog(@"Failed to login fb: %@", error.description);
        NSString *alertText;
        NSString *alertTitle;
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
            alertTitle = @"Something went wrong";
            alertText = [FBErrorUtility userMessageForError:error];
            //[self showMessage:alertText withTitle:alertTitle];
        } else {
            
            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                NSLog(@"User cancelled login");
                
                // Handle session closures that happen outside of the app
            } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
                alertTitle = @"Session Error";
                alertText = @"Your current session is no longer valid. Please log in again.";
                //[self showMessage:alertText withTitle:alertTitle];
                
                // Here we will handle all other errors with a generic error message.
                // We recommend you check our Handling Errors guide for more information
                // https://developers.facebook.com/docs/ios/errors/
            } else {
                //Get more error information from the error
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                // Show the user an error message
                alertTitle = @"Something went wrong";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
                //[self showMessage:alertText withTitle:alertTitle];
            }
        }
        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:alertTitle
                                  message:alertText
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
     ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *fb_user, NSError *error) {
         if (!error) {
             __block EWPerson *oldUser = currentUser;
             __block BOOL newUser;
             
             //test if facebook user exists
             [client loginWithFacebookToken:FBSession.activeSession.accessTokenData.accessToken onSuccess:^(NSDictionary *result) {
                 newUser = NO;
             } onFailure:^(NSError *error) {
                 newUser = YES;
             }];
             
             //login
             [client loginWithFacebookToken:FBSession.activeSession.accessTokenData.accessToken createUserIfNeeded:YES usernameForCreate:fb_user.username onSuccess:^(NSDictionary *result) {
                 NSLog(@"Logged in facebook for:%@", fb_user.name);
                 
                 //fetch coredata person for fb_user
                 [[EWUserManagement sharedInstance] loginWithCachedDataStore:fb_user.username withCompletionBlock:^{
                     //update fb info
                     [[EWUserManagement sharedInstance] updateUserWithFBData:fb_user];
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                         //update UI
                         [self updateView];
                         
                         //stop indicator
                         [self.indicator stopAnimating];
                         
                         //leaving
                         [self dismissViewControllerAnimated:YES completion:^{
                             [[EWDataStore currentContext] saveOnSuccess:^{
                                 if (newUser) {
                                     NSDictionary *msg = @{@"alert": [NSString stringWithFormat:@"Welcome %@ joining Woke!", fb_user.name]};
                                     [pushClient broadcastMessage:msg onSuccess:NULL onFailure:NULL];
                                 }else{
                                     NSLog(@"User %@ logged in from facebook", fb_user.name);
                                 }
                                 
                             } onFailure:^(NSError *error) {
                                 NSLog(@"Unable to save user info");
                             }];
                         }];

                     });
                     
                     
                 }];
                 
                 //void old user AWS token
                 oldUser.aws_id = @"";
                 
                 
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
        [FBSession.activeSession closeAndClearTokenInformation];
        NSLog(@"Error: %@", error);
    }];
}


#pragma mark - Background login
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


#pragma mark - Alert Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        NSLog(@"Starting to log in fb with cached info");
        [self.indicator startAnimating];
        [self.btnLoginLogout setTitle:@"Loading..." forState:UIControlStateNormal];
        
        [FBSession openActiveSessionWithReadPermissions:nil allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [self sessionStateChanged:session state:status error:error];
        }];
    }
}


@end
