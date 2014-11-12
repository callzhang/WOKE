	//
//  EWUserManagement.m
//  EarlyWorm
//
//  Created by Lei on 1/3/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWUserManagement.h"
#import "EWDataStore.h"
#import "EWAppDelegate.h"
#import "EWDownloadManager.h"
#import "EWUtil.h"
#import "EWFirstTimeViewController.h"
@import CoreLocation;

//model
#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWServer.h"
#import "EWAlarmManager.h"
//#import "EWTaskManager.h"

//View
#import "EWLogInViewController.h"


//Util
#import "EWUtil.h"
#import "UIImageView+AFNetworking.h"
#import "ATConnect.h"

//social network
#import "EWSocialGraph.h"
#import "EWSocialGraphManager.h"
#import "EWAlarm.h"





@implementation EWUserManagement

+ (EWUserManagement *)sharedInstance{
    static EWUserManagement *userManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userManager = [[EWUserManagement alloc] init];
    });
    return userManager;
}

+ (void)login{
    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];

    
    if ([PFUser currentUser]) {
        //user already logged in
        NSLog(@"[a]Get Parse logged in user: %@", [PFUser currentUser].username);
        [EWUserManagement loginWithServerUser:[PFUser currentUser] withCompletionBlock:NULL];
        
        //see if user is linked with fb
        if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    //fetch user in coredata cache(offline) with related objects
                    DDLogInfo(@"[b] Logged in to facebook");
                    
                }else if([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) {
                    // Since the request failed, we can check if it was due to an invalid session
                    DDLogInfo(@"The facebook session was expired");
                    [EWUserManagement showLoginPanel];
                    
                }else{
                    DDLogInfo(@"Failed to login facebook, error: %@", error.description);
                    //[EWUserManagement showLoginPanel];
                    [self handleFacebookException:error];
                    
                }
            }];
        }
        
    }else{
        //log in using local machine info
        [EWUserManagement showLoginPanel];
    }
    
    
    //watch for login event
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoginEventHandler) name:kPersonLoggedIn object:Nil];

}


+ (void)showLoginPanel{

//    EWLogInViewController *loginVC = [[EWLogInViewController alloc] initWithNibName:nil bundle:nil];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [rootViewController presentViewController:loginVC animated:YES completion:NULL];
//    });
    if ([PFUser currentUser]) {
        
        [rootViewController presentViewController:[EWFirstTimeViewController new] animated:YES completion:NULL];
    }else{
        
        [rootViewController presentViewController:[EWFirstTimeViewController new] animated:NO completion:NULL];
    }
    
}


//login with local user default info
+ (void)loginWithServerUser:(PFUser *)user withCompletionBlock:(void (^)(void))completionBlock{

    //fetch or create
    EWPerson *person = [[EWPersonManager sharedInstance] findOrCreatePersonWithParseObject:user];
    
    //save me
    [EWSession sharedSession].currentUser = person;
    
    if ([EWSync sharedInstance].workingQueue.count == 0) {
        //if no pending uploads, refresh self
        [person refreshInBackgroundWithCompletion:NULL];
    }
    
    if (completionBlock) {
        DDLogInfo(@"[d] Run completion block.");
        completionBlock();
        
        [[ATConnect sharedConnection] engage:@"login_success" fromViewController:rootViewController];
    }
    
    DDLogInfo(@"[c] Broadcast Person login notification");
    [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:[EWSession sharedSession].currentUser userInfo:@{kUserLoggedInUserKey:[EWSession sharedSession].currentUser}];
    
    //if new user, link with facebook
    if([PFUser currentUser].isNew){
        [EWUserManagement handleNewUser];
        [[ATConnect sharedConnection] engage:@"new_user" fromViewController:rootViewController];
    }
}



//Depreciated: log in using local machine info
+ (void)loginWithDeviceIDWithCompletionBlock:(void (^)(void))block{
    //log out fb first
    [FBSession.activeSession closeAndClearTokenInformation];
    //get user default
    NSString *ADID = [[NSUserDefaults standardUserDefaults] objectForKey:kADIDKey];
    if (!ADID) {
        ADID = [EWUtil ADID];
        [[NSUserDefaults standardUserDefaults] setObject:ADID forKey:kADIDKey];
        NSLog(@"Stored new ADID: %@", ADID);
    }
    //get ADID
    NSArray *adidArray = [ADID componentsSeparatedByString:@"-"];
    //username
    NSString *username = [NSString stringWithFormat:@"EW%@", adidArray.firstObject];
    //password
    NSString *password = adidArray.lastObject;
    
    //try to log in
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
                                       
        if (user) {
            [EWUserManagement loginWithServerUser:user withCompletionBlock:block];
            
        }else{
            NSLog(@"Creating new user: %@", error.description);
            //create new user
            PFUser *user = [PFUser user];
            user.username = username;
            user.password = password;
            error = nil;
            [user signUp:&error];
            if (!error) {
                [EWUserManagement loginWithServerUser:user withCompletionBlock:^{
                    if (block) {
                        block();
                    }
                }];
            }else{
                DDLogError(@"Failed to sign up new user: %@", error.description);
                EWAlert(@"Server not available, please try again.");
                [EWUserManagement showLoginPanel];
            }
            
        }
        
    }];
}

+ (void)logout{
    //log out SM
    if ([PFUser currentUser]) {
        [PFUser logOut];
        DDLogInfo(@"Successfully logged out");
        //log out fb
        [FBSession.activeSession closeAndClearTokenInformation];
        //log in with device id
        //[self loginWithDeviceIDWithCompletionBlock:NULL];
        
        //login view
        [EWUserManagement showLoginPanel];
        
    }else{
        //log out fb
        [FBSession.activeSession closeAndClearTokenInformation];
        //login view
        [EWUserManagement showLoginPanel];
    };
    
    //remove all queue
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueDelete];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueInsert];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueUpdate];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueWorking];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueRefresh];
    DDLogInfo(@"Cleaned local queue");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedOut object:self userInfo:nil];
    
}


+ (void)handleNewUser{
    [EWUserManagement linkWithFacebook];
    NSString *msg = [NSString stringWithFormat:@"Welcome %@ joining Woke!", [EWSession sharedSession].currentUser.name];
    EWAlert(msg);
    [EWServer broadcastMessage:msg onSuccess:NULL onFailure:NULL];
}


//#pragma mark - userLoginEventHandler
////handled by DataStore
//- (void)userLoginEventHandler{
//    NSLog(@"=== [%s] Logged in, performing login tasks.===", __func__);
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    if (![currentInstallation[@"username"] isEqualToString: me.username]){
//        currentInstallation[@"username"] = me.username;
//        [currentInstallation saveInBackground];
//    };
//    
//    [EWUserManagement registerLocation];
//    [EWUserManagement updateLastSeen];
//    [EWUserManagement getFacebookFriends];
//    
//}

//
////Danger Zone
//+ (void)purgeUserData{
//    DDLogDebug(@"Cleaning all cache and server data");
//    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
//    
//    //Alarm
//    [EWAlarmManager deleteAll];
//    //task
//    [[EWTaskManager sharedInstance] deleteAllTasks];
//    //media
//    //[EWMediaStore.sharedInstance deleteAllMedias];
//    //check
//    [[EWTaskManager sharedInstance ] checkScheduledNotifications];
//    
//    [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
//    
//    [EWSync save];
//    //person
//    //me = nil;
//    
//    //alert
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clean Data" message:@"All data has been cleaned." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alert show];
//    //logout
//    //[EWUserManagement logout];
//    
//    
//}


#pragma mark - location
+ (void)registerLocation{

    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        
        if (geoPoint.latitude == 0 && geoPoint.longitude == 0) {
            //NYC coordinate if on simulator
            geoPoint.latitude = 40.732019;
            geoPoint.longitude = -73.992684;
        }
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:geoPoint.latitude longitude:geoPoint.longitude];
        
        DDLogVerbose(@"Get user location with lat: %f, lon: %f", geoPoint.latitude, geoPoint.longitude);
        
        //reverse search address
        CLGeocoder *geoloc = [[CLGeocoder alloc] init];
        [geoloc reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            
            [EWSession sharedSession].currentUser.lastLocation = location;
            
            if (error == nil && [placemarks count] > 0) {
                CLPlacemark *placemark = [placemarks lastObject];
                //get info
                [EWSession sharedSession].currentUser.city = placemark.locality;
                [EWSession sharedSession].currentUser.region = placemark.country;
            } else {
                NSLog(@"%@", error.debugDescription);
            }
            [EWSync save];

        }];
        
        
    }];
}

#pragma mark - FACEBOOK
+ (void)loginParseWithFacebookWithCompletion:(ErrorBlock)block{
    
    //login with facebook
    [PFFacebookUtils logInWithPermissions:[EWUserManagement facebookPermissions] block:^(PFUser *user, NSError *error) {
        if (error) {
            [EWUserManagement handleFacebookException:error];
            if (block) {
                block(error);
            }
        }
        else {
            [EWUserManagement loginWithServerUser:[PFUser currentUser] withCompletionBlock:^{
                //background refresh
                if (block) {
                    DDLogInfo(@"[d] Run completion block.");
                    block(nil);
                }
            }];
        }
    }];
}


+ (void)updateFacebookInfo{
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *data, NSError *error) {
            [EWUserManagement handleFacebookException:error];
            //update with facebook info
            [EWUserManagement updateUserWithFBData:data];
        }];
    }
}



+ (void)linkWithFacebook{
    NSParameterAssert([PFUser currentUser]);
    BOOL islinkedWithFb = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
    if (!islinkedWithFb) {
        [PFFacebookUtils unlinkUser:[PFUser currentUser]];
    }
    [PFFacebookUtils linkUser:[PFUser currentUser] permissions:[EWUserManagement facebookPermissions] block:^(BOOL succeeded, NSError *error) {
        if (error) {
            DDLogError(@"Failed to get facebook info: %@", error.description);
            [EWUserManagement handleFacebookException:error];
            return ;
        }
        
        //alert
        EWAlert(@"Facebook account linked!");
        
        //update current user with fb info
        [EWUserManagement updateFacebookInfo];
    }];
}




//after fb login, fetch user managed object
+ (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user{
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWPerson *person = [[EWSession sharedSession].currentUser inContext:localContext];
        
        NSParameterAssert(person);
        
        //name
        if ([person.name isEqualToString:kDefaultUsername] || person.name.length == 0) {
            person.name = user.name;
        }
        //email
        if (!person.email) person.email = user[@"email"];
        
        //birthday format: "01/21/1984";
        if (!person.birthday) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"mm/dd/yyyy";
            person.birthday = [formatter dateFromString:user[@"birthday"]];
        }
        //facebook link
        person.facebook = user.id;
        //gender
        person.gender = user[@"gender"];
        //city
        person.city = user.location[@"name"];
        //preference
        if(!person.preference){
            //new user
            person.preference = kUserDefaults;
        }
        
        if (!person.profilePic) {
            //download profile picture if needed
            //profile pic, async download, need to assign img to person before leave
            NSString *imageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", user.id];
            
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
            UIImage *img = [UIImage imageWithData:data];
			if (!img) {
				img = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", arc4random_uniform(15)]];
			}
            person.profilePic = img;
        }
        
    }completion:^(BOOL success, NSError *error) {
        //update friends
        [EWUserManagement getFacebookFriends];
    }];
    
}

+ (void)getFacebookFriends{
    DDLogVerbose(@"Updating facebook friends");
    //check facebook id exist
    if (![EWSession sharedSession].currentUser.facebook) {
        DDLogWarn(@"Current user doesn't have facebook ID, skip checking fb friends");
        return;
    }
    
    FBSessionState state = [FBSession activeSession].state;
    if (state != FBSessionStateOpen && state != FBSessionStateOpenTokenExtended) {
        
        //session not open, need to open
        DDLogVerbose(@"facebook session state: %d", state);
        [EWUserManagement openFacebookSessionWithCompletion:^{
            DDLogVerbose(@"Facebook session opened: %d", [FBSession activeSession].state);
            
            [EWUserManagement getFacebookFriends];
        }];
        
        return;
    }else{
        
        //get social graph of current user
        //if not, create one
        [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
            EWPerson *localMe = [[EWSession sharedSession].currentUser inContext:localContext];
            EWSocialGraph *graph = [[EWSocialGraphManager sharedInstance] socialGraphForPerson:localMe];
            //skip if checked within a week
            if (graph.facebookUpdated && abs([graph.facebookUpdated timeIntervalSinceNow]) < kSocialGraphUpdateInterval) {
                DDLogVerbose(@"Facebook friends check skipped.");
                return;
            }
            
            //get the data
            __block NSMutableDictionary *friends = [NSMutableDictionary new];
            [EWUserManagement getFacebookFriendsWithPath:@"/me/friends" withReturnData:friends];
        } completion:^(BOOL success, NSError *error) {
            //
        }];
        
    }
    
}

+ (void)getFacebookFriendsWithPath:(NSString *)path withReturnData:(NSMutableDictionary *)friendsHolder{
    [FBRequestConnection startWithGraphPath:path completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        DDLogVerbose(@"Got facebook friends list, start processing");
        if (!error){
            NSArray *friends = (NSArray *)result[@"data"];
            NSString *nextPage = (NSString *)result[@"paging"][@"next"]	;
            //parse
            if (friends) {
                for (NSDictionary *pair in friends) {
                    NSString *fb_id = pair[@"id"];
                    NSString *name = pair[@"name"];
                    [friendsHolder setObject:name forKey:fb_id];
                }
            }
            
            //next page
            if (nextPage) {
                //continue loading facebook friends
                //NSLog(@"Continue facebook friends request: %@", nextPage);
                [self getFacebookFriendsWithPath:nextPage withReturnData:friendsHolder];
            }else{
                DDLogVerbose(@"Finished loading friends from facebook, transfer to social graph.");
                EWSocialGraph *graph = [[EWSocialGraphManager sharedInstance] socialGraphForPerson:[EWSession sharedSession].currentUser];
                graph.facebookFriends = [friendsHolder copy];
                graph.facebookUpdated = [NSDate date];
                
                //save
                [EWSync save];
            }
            
        } else {
            // An error occurred, we need to handle the error
            // See: https://developers.facebook.com/docs/ios/errors
            
            [EWUserManagement handleFacebookException:error];
        }
    }];
    
}



+ (void)openFacebookSessionWithCompletion:(void (^)(void))block{
    
    [FBSession openActiveSessionWithReadPermissions:EWUserManagement.facebookPermissions
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         
         if (error) {
             [EWUserManagement handleFacebookException:error];
         }else if (block){
             block();
         }
     }];
}

+ (NSArray *)facebookPermissions{
    NSArray *permissions = @[@"basic_info",
                             @"user_location",
                             @"user_birthday",
                             @"email",
                             @"user_photos",
                             @"user_friends"];
    return permissions;
}


+ (void)handleFacebookException:(NSError *)error{
    if (!error) {
        return;
    }
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
            [MBProgressHUD hideHUDForView:rootViewController.view animated:YES];
            DDLogInfo(@"User cancelled login");
            alertTitle = @"User Cancelled Login";
            alertText = @"Please Try Again";
            
            // Handle session closures that happen outside of the app
        } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
            alertTitle = @"Session Error";
            alertText = @"Your current session is no longer valid. Please log in again.";
            //[self showMessage:alertText withTitle:alertTitle];
            
            // Here we will handle all other errors with a generic error message.
            // We recommend you check our Handling Errors guide for more information
            // https://developers.facebook.com/docs/ios/errors/
            
            // Clear this token
            [FBSession.activeSession closeAndClearTokenInformation];
        } else if (error.code == 5){
            if (![EWSync isReachable]) {
                DDLogError(@"No connection: %@", error.description);
            }else{
                
                DDLogError(@"Error %@", error.description);
                alertTitle = @"Something went wrong";
                alertText = @"Operation couldn't be finished. We appologize for this. It may caused by weak internet connection.";
            }
        } else {
            //Get more error information from the error
            NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
            
            // Show the user an error message
            alertTitle = @"Something went wrong";
            alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
            //[self showMessage:alertText withTitle:alertTitle];
            DDLogError(@"Failed to login fb: %@", error.description);
            
            // Clear this token
            [FBSession.activeSession closeAndClearTokenInformation];
        }
    }
    
    if (!alertTitle) return;
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:alertTitle
                              message:alertText
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];

}




#pragma mark - Weibo SDK
//
//+ (void)registerWeibo{
//    // Weibo SDK
//    //EWWeiboManager *weiboMgr = [EWWeiboManager sharedInstance];
//    //[weiboMgr registerApp];
//}
//
//+ (void)didReceiveWeiboRequest:(WBBaseRequest *)request {
//    EWWeiboManager *weiboManager = [EWWeiboManager sharedInstance];
//    [weiboManager didReceiveWeiboRequest:request];
//}
//
//+ (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
//    EWWeiboManager *weiboManager = [EWWeiboManager sharedInstance];
//    [weiboManager didReceiveWeiboResponse:response];
//}
//
//+  (void)didReceiveWeiboSDKResponse:(id)JsonObject err:(NSError *)error {
//    EWWeiboManager *weiboManager = [EWWeiboManager sharedInstance];
//    [weiboManager didReceiveWeiboSDKResponse:JsonObject err:error];
//}
//



@end
