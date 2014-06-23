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
@import CoreLocation;

//model
#import "EWPerson.h"
#import "EWPersonStore.h"
#import "EWServer.h"

//View
#import "EWLogInViewController.h"


//Util
#import "EWUtil.h"
#import "UIImageView+AFNetworking.h"

//social network
#import "EWSocialGraph.h"
#import "EWSocialGraphManager.h"





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
        [EWUserManagement loginWithServerUser:[PFUser currentUser] withCompletionBlock:^{}];
        
        //see if user is linked with fb
        if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    //fetch user in coredata cache(offline) with related objects
                    NSLog(@"[b] Logged in to facebook");
                    
                }else if([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) {
                    // Since the request failed, we can check if it was due to an invalid session
                    EWAlert(@"The facebook session was expired");
                    //[EWUserManagement showLoginPanel];
                    
                }else{
                    EWAlert(@"Failed to login Facebook");
                    NSLog(@"Failed to login facebook, error: %@", error.description);
                    //[EWUserManagement showLoginPanel];
                    
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
    NSLog(@"Display login panel");
    EWLogInViewController *loginVC = [[EWLogInViewController alloc] initWithNibName:nil bundle:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [rootViewController presentViewController:loginVC animated:YES completion:NULL];
    });
    
}

//Current User
+ (EWPerson *)me{
    if ([NSThread isMainThread]) {
        return me;
    }else{
        return [EWDataStore objectForCurrentContext:me];
    }
}


//login with local user default info
+ (void)loginWithServerUser:(PFUser *)user withCompletionBlock:(void (^)(void))completionBlock{
    [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    hud.labelText = @"Loading";
    
    
    //background refresh
    if (completionBlock) {
        NSLog(@"[d] Run completion block.");
        completionBlock();
    }

    //fetch or create
    EWPerson *person = [[EWPersonStore sharedInstance] getPersonByID:user.username];
    
    //update person
    //change to update in sync mode to avoid data overriding while update value from server
    [person refreshInBackgroundWithCompletion:^{
        //[person refreshRelatedInBackground];
    }];
    
    
    //save me
    me = person;
    
    //Broadcast user login event
    NSLog(@"[c] Broadcast Person login notification");
    [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:me userInfo:@{kUserLoggedInUserKey:me}];

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
//            EWPerson *person = [[EWPersonStore sharedInstance] getPersonByID:user.username];
//            [person updateValueAndRelationFromParseObject:user];
//            me = person;
            [EWUserManagement loginWithServerUser:user withCompletionBlock:NULL];
            
        }else{
            NSLog(@"Creating new user: %@", error.description);
            //create new user
            PFUser *user = [PFUser user];
            user.username = username;
            user.password = password;
            error = nil;
            [user signUp:&error];
            if (!error) {
                //create person
                EWPerson *person = [[EWPersonStore sharedInstance] createPersonWithParseObject:user];
                me = person;
                [EWDataStore save];
                
                //broadcast
                [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:me userInfo:@{kUserLoggedInUserKey:me}];
                //callback
                if (block) {
                    block();
                }
            }else{
                NSLog(@"Failed to sign up new user: %@", error.description);
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
        NSLog(@"Successfully logged out");
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
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedOut object:self userInfo:nil];
    
}


+ (void)handleNewUser{
    
    NSString *msg = [NSString stringWithFormat:@"Welcome %@ joining Woke!", me.name];
    EWAlert(msg);
    [EWServer broadcastMessage:msg onSuccess:^{
        NSLog(@"Welcome new user %@. Push sent!", me.name);
    }onFailure:NULL];
    
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



#pragma mark - location
+ (void)registerLocation{

    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        
        EWPerson *user = [EWUserManagement me];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:geoPoint.latitude longitude:geoPoint.longitude];
        user.lastLocation = location;
        NSLog(@"Get user location with lat: %f, lon: %f", geoPoint.latitude, geoPoint.longitude);
        
        //reverse search address
        CLGeocoder *geoloc = [[CLGeocoder alloc] init];
        [geoloc reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            //NSLog(@"Found placemarks: %@, error", placemarks);
            if (error == nil && [placemarks count] > 0) {
                CLPlacemark *placemark = [placemarks lastObject];
                //get info
                user.city = placemark.locality;
                user.region = placemark.country;
            } else {
                NSLog(@"%@", error.debugDescription);
            }
            [EWDataStore save];

        }];
        
        
    }];
}

#pragma mark - Last seen
+ (void)updateLastSeen{
    
    if (me) {
        me.updatedAt = [NSDate date];
        [EWDataStore save];
    }
}


#pragma mark - FACEBOOK
+ (void)loginParseWithFacebookWithCompletion:(void (^)(void))block{
    NSParameterAssert(![PFUser currentUser]);
    
    //login with facebook
    [PFFacebookUtils logInWithPermissions:[EWUserManagement facebookPermissions] block:^(PFUser *user, NSError *error) {
        if (error) {
            NSLog(@"Failed to link user: %@", error.description);
            return;
        }
        
        //login core data user with PFUser, do NOT refresh from PO, refresh from fb info
        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
        
        //background refresh
        if (block) {
            NSLog(@"[d] Run completion block.");
            block();
        }
        
        //fetch or create user
        EWPerson *person = [[EWPersonStore sharedInstance] getPersonByID:user.username];
        
        //save me
        me = person;
        
        //Broadcast user login event
        NSLog(@"[c] Broadcast Person login notification");
        [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:me userInfo:@{kUserLoggedInUserKey:me}];

        
        //update current user with fb info
        [EWUserManagement updateFacebookInfo];
        
        if ([PFUser currentUser].isNew) {
            [EWUserManagement handleNewUser];
        }
    }];
}


+ (void)updateFacebookInfo{
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *data, NSError *error) {
        [EWUserManagement handleFacebookException:error];
        //update with facebook info
        [EWUserManagement updateUserWithFBData:data];
    }];
}



+ (void)linkWithFacebook{
    NSParameterAssert([PFUser currentUser]);
    BOOL islinkedWithFb = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
    if (islinkedWithFb) {
        [PFFacebookUtils unlinkUser:[PFUser currentUser]];
    }
    [PFFacebookUtils linkUser:[PFUser currentUser] permissions:[EWUserManagement facebookPermissions] block:^(BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"Failed to get facebook info: %@", error.description);
            return ;
        }
        //get fb info
        [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *data, NSError *error) {
            if (error) {
                NSLog(@"Failed to load facebook data: %@", error.description);
                return;
            }
            //update to current user
            [EWUserManagement updateUserWithFBData:data];
            
            //alert
            EWAlert(@"Facebook account linked!");
        }];
    }];
}

//+ (void)loginUsingFacebookWithCompletion:(void (^)(void))block{
//
//    [EWUserManagement openFacebookSessionWithCompletion:^{
//        [[FBRequest requestForMe] startWithCompletionHandler:
//         ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *fb_user, NSError *error) {
//             if (!error) {
//                 __block EWPerson *oldUser = me;
//                 __block BOOL newUser;
//                 
//                 //test if facebook user exists
//                 [client loginWithFacebookToken:FBSession.activeSession.accessTokenData.accessToken onSuccess:^(NSDictionary *result) {
//                     newUser = NO;
//                 } onFailure:^(NSError *error) {
//                     newUser = YES;
//                 }];
//                 
//                 //login
//                 [client loginWithFacebookToken:FBSession.activeSession.accessTokenData.accessToken createUserIfNeeded:YES usernameForCreate:fb_user.username onSuccess:^(NSDictionary *result) {
//                     NSLog(@"Logged in facebook for:%@", fb_user.name);
//                     
//                     //fetch coredata person for fb_user
//                     [EWUserManagement loginWithCachedDataStore:fb_user.username withCompletionBlock:^{
//                         //update fb info
//                         [EWUserManagement updateUserWithFBData:fb_user];
//                         
//                         //welcome new user
//                         if (newUser) {
//                             [EWUserManagement handleNewUser];
//                             
//                         }else{
//                             NSLog(@"User %@ logged in from facebook", fb_user.name);
//                         }
//                         
//                         //save
//                         [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
//                             NSLog(@"Unable to save user");
//                         }];
//                         
//                         //completion
//                         dispatch_async(dispatch_get_main_queue(), ^{
//                             block();
//                             
//                         });
//                         
//                         
//                     }];
//                     
//                     //void old user AWS token
//                     oldUser.aws_id = @"";
//                     
//                     
//                 }onFailure:^(NSError *error) {
//                     NSLog(@"Error: %@", error);
//                 }];
//             } else {
//                 // Handle error accordingly
//                 [EWUserManagement handleFacebookException:error];
//             }
//             
//             
//             
//         }];
//    }];
//    
//}


//after fb login, fetch user managed object
+ (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user{
    //get me first
    EWPerson *person = [EWUserManagement me];
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
    //download profile picture if needed
    //profile pic, async download, need to assign img to person before leave
    NSString *imageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", user.id];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        UIImage *img = [UIImage imageWithData:data];
        
        [person.managedObjectContext performBlock:^{
            person.profilePic = img;
            [EWDataStore save];
        }];
    });
    
    //update friends
    [EWUserManagement getFacebookFriends];
    
    //save
    [EWDataStore save];
}

+ (void)getFacebookFriends{
    NSLog(@"Updating facebook friends");
    //check facebook id exist
    if (!me.facebook) {
        NSLog(@"Current user doesn't have facebook ID, skip checking fb friends");
        return;
    }
    
    FBSessionState state = [FBSession activeSession].state;
    if (state != FBSessionStateOpen && state != FBSessionStateOpenTokenExtended) {
        
        //session not open, need to open
        NSLog(@"facebook session state: %d", state);
        [EWUserManagement openFacebookSessionWithCompletion:^{
            NSLog(@"Facebook session opened: %d", [FBSession activeSession].state);
            
            [EWUserManagement getFacebookFriends];
        }];
        
        return;
    }else{
        
        //get social graph of current user
        //if not, create one
        EWSocialGraph *graph = [[EWSocialGraphManager sharedInstance] socialGraphForPerson:[EWUserManagement me]];
        //skip if checked within a week
        if (graph.facebookUpdated && abs([graph.facebookUpdated timeIntervalSinceNow]) < kSocialGraphUpdateInterval) {
            NSLog(@"Facebook friends check skipped.");
            return;
        }
        
        //get the data
        __block NSMutableDictionary *friends = [NSMutableDictionary new];
        [EWUserManagement getFacebookFriendsWithPath:@"/me/friends" withReturnData:friends];
    }

}

+ (void)getFacebookFriendsWithPath:(NSString *)path withReturnData:(NSMutableDictionary *)friendsHolder{
    [FBRequestConnection startWithGraphPath:path completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        NSLog(@"Got facebook friends list, start processing");
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
                NSLog(@"Finished loading friends from facebook, transfer to social graph.");
                EWSocialGraph *graph = [[EWSocialGraphManager sharedInstance] socialGraphForPerson:me];
                graph.facebookFriends = [friendsHolder copy];
                graph.facebookUpdated = [NSDate date];
                
                //save
                [EWDataStore save];
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
            NSLog(@"User cancelled login");
            
            // Handle session closures that happen outside of the app
        } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
            alertTitle = @"Session Error";
            alertText = @"Your current session is no longer valid. Please log in again.";
            //[self showMessage:alertText withTitle:alertTitle];
            
            // Here we will handle all other errors with a generic error message.
            // We recommend you check our Handling Errors guide for more information
            // https://developers.facebook.com/docs/ios/errors/
        } else if (error.code == 5){
            NSLog(@"Error %@", error.description);
            alertTitle = @"Somethong went wrong";
            alertText = @"Operation couldn't be finished. We appologize for this. It may caused by weak internet connection.";
        } else {
            //Get more error information from the error
            NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
            
            // Show the user an error message
            alertTitle = @"Something went wrong";
            alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
            //[self showMessage:alertText withTitle:alertTitle];
            NSLog(@"Failed to login fb: %@", error.description);
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
