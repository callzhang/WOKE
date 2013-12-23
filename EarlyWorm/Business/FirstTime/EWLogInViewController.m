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
#import "SMLocationManager.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "EWDatabaseDefault.h"
#import "UIImageView+AFNetworking.h"
#import "MBProgressHUD.h"

@interface EWLogInViewController ()

@end

@implementation EWLogInViewController
@synthesize context, client;

+(EWLogInViewController *)sharedInstance{
    static EWLogInViewController *loginVC = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loginVC = [[EWLogInViewController alloc] init];
    });
    
    
    return loginVC;
}

- (EWAppDelegate *)appDelegate {
    return (EWAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Error handling
        //__block id blockSelf = self;
        __block SMUserSession *currentSession = self.client.session;
        [self.client setTokenRefreshFailureBlock:^(NSError *error, SMFailureBlock originalFailureBlock) {
            NSLog(@"Automatic refresh token has failed");
            // Reset local session info
            [currentSession clearSessionInfo];
            
            // Show custom login screen
            //[blockSelf showLoginScreen];
            
            // Optionally call original failure block
            originalFailureBlock(error);
        }];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.indicator stopAnimating];
    [self updateView];
    self.proceedBtn.alpha = 0;
    
    self.client = [self.appDelegate client];
    //see if fb has already leave token; log in if so.
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        NSLog(@"Starting to log in fb with cached info");
        [self.indicator startAnimating];
        [self.btnLoginLogout setTitle:@"Logging in..." forState:UIControlStateNormal];
        
        [FBSession openActiveSessionWithReadPermissions:nil allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [self sessionStateChanged:session state:status error:error];
        }];
    }
    self.context = [[self.appDelegate coreDataStore] contextForCurrentThread];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateView {
    
    if ([self.client isLoggedIn]) {
        [self.btnLoginLogout setTitle:@"Log out" forState:UIControlStateNormal];
    } else {
        [self.btnLoginLogout setTitle:@"Login with Facebook" forState:UIControlStateNormal];
    }
}

- (IBAction)connect:(id)sender {
    [self.indicator startAnimating];
    if ([self.client isLoggedIn]) {
        [self logoutUser];
    } else {
        [self openSession];
    }
}

- (IBAction)check:(id)sender {
    NSLog(@"%@",[self.client isLoggedIn] ? @"Logged In" : @"Logged Out");
    NSLog(@"Current user: %@", [EWPersonStore sharedInstance].currentUser);
}

- (IBAction)proceed:(id)sender {
    //save image to user
    [EWPersonStore sharedInstance].currentUser.profilePic = self.profileView.image;
    [[[SMClient defaultClient].coreDataStore contextForCurrentThread] saveOnSuccess:^{
        //check default
        [[EWDatabaseDefault sharedInstance] setDefault];
        //leaving
        [self dismissViewControllerAnimated:YES completion:NULL];
        //broadcasting
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{@"User": [EWPersonStore sharedInstance].currentUser}];
        //hide hud if possible
        EWAppDelegate *delegate = [UIApplication sharedApplication].delegate;
        [MBProgressHUD hideAllHUDsForView:delegate.window.rootViewController.view animated:YES];
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error on saving new user info" format:@"Reason: %@", error.description];
    }];
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
             [self.client loginWithFacebookToken:FBSession.activeSession.accessTokenData.accessToken createUserIfNeeded:YES usernameForCreate:user.username onSuccess:^(NSDictionary *result) {
                 NSLog(@"Logged in facebook for:%@", user.name);
                 [self updateView];
                 [self updateUserData:user];
             } onFailure:^(NSError *error) {
                 NSLog(@"Error: %@", error);
             }];
         } else {
             // Handle error accordingly
             NSLog(@"Error getting current Facebook user data, %@", error);
         }
         
     }];
}

- (void)logoutUser {
    
    [self.client logoutOnSuccess:^(NSDictionary *result) {
        NSLog(@"Logged out of StackMob");
        [FBSession.activeSession closeAndClearTokenInformation];
    } onFailure:^(NSError *error) {
        NSLog(@"Error: %@", error);
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

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
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
    /*
    [[NSNotificationCenter defaultCenter]
     postNotificationName:SCSessionStateChangedNotification
     object:session];*/
    
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

//after fb login, fetch user managed object
- (void)updateUserData:(NSDictionary<FBGraphUser> *)user{
    [[SMClient defaultClient] getLoggedInUserOnSuccess:^(NSDictionary *result){
        // Result contains a dictionary representation of the user object
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWPerson"];
        request.predicate = [NSPredicate predicateWithFormat:@"username == %@", user.username];
        request.returnsObjectsAsFaults = NO;
        [context executeFetchRequest:request onSuccess:^(NSArray *results) {
            [self.indicator stopAnimating];
            if (results.count == 0) {
                //no user has been found
                [NSException raise:@"User not found" format:@"For username: %@", user.username];
                [[EWPersonStore sharedInstance] createPersonWIthUsername:user.username];
            }else if(results.count > 1){
                [NSException raise:@"Unexpected number of users" format:@"For username: %@", user.username];
            }else{
                
                //update user for fb information
                EWPerson *person = results[0];
                [EWPersonStore sharedInstance].currentUser = person;
                if (person.email) {
                    //return;
                }
                //email
                person.email = user[@"email"];
                //name
                person.name = user.name;
                self.name.text = user.name;
                //birthday = "01/21/1984";
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"mm/dd/yyyy";
                person.birthday = [formatter dateFromString:user[@"birthday"]];
                //facebook link
                person.facebook = user.link;
                //preference
                person.preference = [[EWDatabaseDefault sharedInstance].defaults mutableCopy];
                //profile pic, async download, need to assign img to person before leave
                NSString *imageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture", user.id];
                [self.profileView setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage imageNamed:@"profile.png"]];
                
                /*[self.profileView setImageWithURLRequest:[NSURL URLWithString:imageUrl]
                                        placeholderImage:[UIImage imageNamed:@"profile.jpg"]
                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                     [self.indicator stopAnimating];
                                                     [self proceed:nil];//auto login
                                                 }
                                                 failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                     //
                                                 }];*/
                //gender
                person.gender = user[@"gender"];
                //city
                person.city = user.location[@"name"];
                
                //show proceed btn
                self.proceedBtn.alpha = 1;
            }

        } onFailure:^(NSError *error) {
            [NSException raise:@"User fetch error" format:@"For username: %@", user.username];
        }];
        
    } onFailure:^(NSError *err){
        // Error
        [NSException raise:@"Unable to find current user" format:@"Check your code"];
    }];
}



@end
