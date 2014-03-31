//
//  EWUserManagement.m
//  EarlyWorm
//
//  Created by Lei on 1/3/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWUserManagement.h"
#import "EWDataStore.h"
#import "SMPushClient.h"
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
#import "EWIO.h"
#import "AFImageRequestOperation.h"

//social network
#import "EWWeiboManager.h"
#import "EWFacebookManager.h"

@implementation EWUserManagement


+ (EWUserManagement *)sharedInstance{
    static EWUserManagement *userManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userManager = [[EWUserManagement alloc] init];
    });
    return userManager;
}


- (void)login{
    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    //get logged in user
    if ([client isLoggedIn]) {
        //user already logged in
        //fetch user in coredata cache(offline) with related objects
        [client getLoggedInUserOnSuccess:^(NSDictionary *result) {
            
            NSLog(@"[a]Get SM logged in user: %@", result[@"username"]);
            [self loginWithCachedDataStore:result[@"username"] withCompletionBlock:^{}];
            
            
        } onFailure:^(NSError *error) { //failed to get logged in user
            NSLog(@"%s: ======= Failed to get logged in user from SM Cache ======= %@", __func__, error);
            [self loginWithFacebook];
        }];
        
        
    }else{
        //log in using local machine info
        [self loginWithFacebook];
    }
    
    
    //watch for login event
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoginEventHandler) name:kPersonLoggedIn object:Nil];
}

- (void)loginWithFacebook{
    NSLog(@"Login with facebook info");
    EWLogInViewController *loginVC = [[EWLogInViewController alloc] init];
    [rootViewController presentViewController:loginVC animated:YES completion:NULL];
}




//login with local user default info
- (void)loginWithCachedDataStore:(NSString *)username withCompletionBlock:(void (^)(void))completionBlock{
    [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    hud.labelText = @"Loading";
    //fetch
    NSFetchRequest *userFetch = [[NSFetchRequest alloc] initWithEntityName:@"EWPerson"];
    userFetch.predicate = [NSPredicate predicateWithFormat:@"username == %@", username];
    userFetch.relationshipKeyPathsForPrefetching = @[@"alarms", @"tasks", @"friends"];//no use for SM
    userFetch.returnsObjectsAsFaults = NO;
    
    //cache only
    __block SMRequestOptions *options = [EWDataStore optionFetchCacheElseNetwork];
    
    //fetch
    [[EWDataStore currentContext] executeFetchRequest:userFetch returnManagedObjectIDs:NO successCallbackQueue:nil failureCallbackQueue:nil options:[EWDataStore optionFetchCacheElseNetwork] onSuccess:^(NSArray *results) {
        
        if (results.count == 0) {
            
            NSLog(@"No local user for %@, fetch from server", username);
            options = [EWDataStore optionFetchNetworkElseCache];
            NSArray *newResult = [[EWDataStore currentContext] executeFetchRequestAndWait:userFetch error:NULL];
            currentUser = newResult[0];
            
            //completion block
            completionBlock();
        }else{
            //contineue user log in tasks
            NSLog(@"[b] User %@ data has fetched from cache as {CurrentUser}", username);
            
            //set current user
            currentUser = results[0];
            
            //background refresh
            if (completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[context refreshObject:currentUser mergeChanges:YES];
                    //[EWDataStore refreshObjectWithServer:currentUser];
                    //completion block
                    NSLog(@"[c] Run completion block.");
                    completionBlock();
                });
            }
            
            
        }
        
        //Broadcast user login event
        NSLog(@"[d] Broadcast Person login notification");
        [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey:currentUser}];
        
        //login to fb
        //TODO
        
        //HUD
        //[MBProgressHUD hideAllHUDsForView:rootview animated:YES];
        
    } onFailure:^(NSError *error) { //fail to fetch user
        NSLog(@"Failed to fetch logged in user in cache: %@", error.description);
        // Reset local session info
        [client.session clearSessionInfo];
        // fetch remote
        options = [EWDataStore optionFetchNetworkElseCache];
        [[EWDataStore currentContext] executeFetchRequest:userFetch
                                   returnManagedObjectIDs:NO successCallbackQueue:nil
                                     failureCallbackQueue:nil options:options
                                                onSuccess:^(NSArray *results) {
            
            //assign current user
            if (results.count == 1) {
                currentUser = results[0];
                //completion block
                completionBlock();
                //Broadcast user login event
                [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey:currentUser}];
            }else{
                [self loginWithDeviceIDWithCompletionBlock:completionBlock];
            }
            
        } onFailure:^(NSError *error) {
            
            //login with device id
            [self loginWithDeviceIDWithCompletionBlock:completionBlock];
        }];
        
    }];
}

//log in using local machine info
- (void)loginWithDeviceIDWithCompletionBlock:(void (^)(void))block{
    //log out fb first
    [FBSession.activeSession closeAndClearTokenInformation];
    //get user default
    NSString *ADID = [[NSUserDefaults standardUserDefaults] objectForKey:kADIDKey];
    if (!ADID) {
        ADID = [EWIO ADID];
        [[NSUserDefaults standardUserDefaults] setObject:ADID forKey:kADIDKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"Stored new ADID: %@", ADID);
    }
    //get ADID
    NSArray *adidArray = [ADID componentsSeparatedByString:@"-"];
    //username
    NSString *username = adidArray.firstObject;
    //password
    NSString *password = adidArray.lastObject;
    
    //try to log in
    [client loginWithUsername:username password:password onSuccess:^(NSDictionary *result) {
        currentUser = [[EWPersonStore sharedInstance] getPersonByID:username];
        
        //callback
        block();
        
        //broadcast
        [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey:currentUser}];
        
    } onFailure:^(NSError *error) {
        NSLog(@"Unable to login with username: %@. Error: %@", username, error.description);
        //if not logged in, register one
        EWPerson *newMe = [[EWPerson alloc] initNewUserInContext:context];
        [newMe setUsername:username];
        [newMe setPassword:password];
        newMe.name = [NSString stringWithFormat:@"User_%@", username];
        newMe.profilePic = [UIImage imageNamed:@"profile"];
        currentUser = newMe;
        
        //persist password to user defaults locally
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:password forKey:@"password"];
        
        //save new user
        [[EWDataStore currentContext] saveOnSuccess:^{
            NSLog(@"New user %@ created", newMe.username);
            
            //login
            [client loginWithUsername:currentUser.username password:password onSuccess:^(NSDictionary *result){
                //callback
                block();
                
                //broadcast
                [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey:currentUser}];
                
                //HUD
                //[MBProgressHUD hideAllHUDsForView:rootview animated:YES];
            } onFailure:^(NSError *error) {
                //[NSException raise:@"Unable to create temporary user" format:@"error: %@", error.description];
                if (error.code == -105) {
                    //network error
                    EWAlert(@"No network connection. Unable to register new user to server");
                }else{
                    NSLog(@"Server error, please try again later. %@", error.description);
                }
            }];
        } onFailure:^(NSError *error) {
            //[NSException raise:@"Unable to create new user" format:@"Reason %@", error.description];
            EWAlert(@"Server error, please restart app");
        }];
    }];

}

- (void)logout{
    //log out SM
    if ([client isLoggedIn]) {
        [client logoutOnSuccess:^(NSDictionary *result) {
            NSLog(@"Successfully logged out");
            //log out fb
            [FBSession.activeSession closeAndClearTokenInformation];
            //log in with device id
            //[self loginWithDeviceIDWithCompletionBlock:NULL];
            
            //login view
            EWLogInViewController *loginVC = [[EWLogInViewController alloc] init];
            [rootViewController presentViewController:loginVC animated:YES completion:NULL];
        }
         onFailure:^(NSError *error) {
             EWAlert(@"Unable to logout, please try again.");
         }];
    }else{
        //log out fb
        [FBSession.activeSession closeAndClearTokenInformation];
        //login view
        EWLogInViewController *loginVC = [[EWLogInViewController alloc] init];
        [rootViewController presentViewController:loginVC animated:YES completion:NULL];
    };
}


#pragma mark - userLoginEventHandler
- (void)userLoginEventHandler{
    NSLog(@"[%s]", __func__);
    [self registerAPNS];
    [self registerLocation];
    [self updateLastSeen];

}

#pragma mark - PUSH

- (void)registerAPNS{
    //push
#if TARGET_IPHONE_SIMULATOR
    //Code specific to simulator
#else
    //pushClient = [[SMPushClient alloc] initWithAPIVersion:@"0" publicKey:kStackMobKeyDevelopment privateKey:kStackMobKeyDevelopmentPrivate];
    //register everytime in case for events like phone replacement
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert];
#endif
}


#pragma mark - location
- (void)registerLocation{
    [SMGeoPoint getGeoPointForCurrentLocationOnSuccess:^(SMGeoPoint *geoPoint) {
        currentUser.lastLocation = [NSKeyedArchiver archivedDataWithRootObject:geoPoint];
        NSLog(@"Get user location with lat: %@, lon: %@", geoPoint.latitude, geoPoint.longitude);
        
        //reverse search address
        CLGeocoder *geoloc = [[CLGeocoder alloc] init];
        CLLocation *clloc = [[CLLocation alloc] initWithLatitude:[geoPoint.latitude doubleValue] longitude:[geoPoint.longitude doubleValue]];
        [geoloc reverseGeocodeLocation:clloc completionHandler:^(NSArray *placemarks, NSError *error) {
            NSLog(@"Found placemarks: %@, error", placemarks);
            if (error == nil && [placemarks count] > 0) {
                CLPlacemark *placemark = [placemarks lastObject];
                //get info
                currentUser.city = placemark.locality;
                currentUser.region = placemark.country;
            } else {
                NSLog(@"%@", error.debugDescription);
            }
            //[context refreshObject:currentUser mergeChanges:YES];
            [[EWDataStore sharedInstance].coreDataStore syncWithServer];

        }];
        
        
    } onFailure:^(NSError *error) {
        NSLog(@"===== Unable to location curent user =====");
        //TODO
    }];
}

#pragma mark - Last seen
- (void)updateLastSeen{
    
    if (currentUser) {
        currentUser.lastSeenDate = [NSDate date];
        [context saveOnSuccess:^{
            NSLog(@"Updated last seen date");
        } onFailure:^(NSError *error) {
            NSLog(@"Failed to update last seen date");
        }];
    }
}


- (void)registerPushNotification{
    //register notification, need both token and user ready
    NSString *username = currentUser.username;
    if (!username) {
        NSLog(@"@@@@@ Tried to register push on StackMob but username is missing. Check you code! @@@@@");
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *tokenByUserArray = [defaults objectForKey:kPushTokenDicKey];
    NSString *token = [tokenByUserArray objectForKey:username];
    if(!tokenByUserArray || !token){
        [NSException raise:@"Unable to find local token" format:@"Please check code"];
    }
    [pushClient registerDeviceToken:token withUser:username onSuccess:^{
        NSLog(@"APP registered push token and assigned to StackMob server");
    } onFailure:^(NSError *error) {
        //[NSException raise:@"Failed to regiester push token with StackMob" format:@"%@", error.description];
        NSLog(@"Failed to register push on StackMob: %@", error.description);
    }];
    return;
    
}


#pragma mark - FACEBOOK
//after fb login, fetch user managed object
- (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user{
    //get currentUser first
    if(!currentUser){
        NSLog(@"======= Something wrong, currentUser is nil ========");
    }
        
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
    //get current user
    EWPerson *person = [[EWPersonStore sharedInstance] getPersonByID:user.username];
    currentUser = person;
    
    //email
    if (!person.email) person.email = user[@"email"];
    //name
    if(!person.name) person.name = user.name;
    //birthday format: "01/21/1984";
    if (!person.birthday) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"mm/dd/yyyy";
        person.birthday = [formatter dateFromString:user[@"birthday"]];
    }
    //facebook link
    person.facebook = user.link;
    //gender
    person.gender = user[@"gender"];
    //city
    if (!person.city) person.city = user.location[@"name"];
    //preference
    if(!person.preference){
        //new user
        NSDictionary *defaults = userDefaults;
        person.preference = [defaults mutableCopy];
    }
    //profile pic, async download, need to assign img to person before leave
    NSString *imageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", user.id];
    //[self.profileView setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage imageNamed:@"profile.png"]];
    
    //[self.profileView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:imageUrl]] placeholderImage:[UIImage imageNamed:@"profile.png"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {//
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageUrl]];
    AFImageRequestOperation *operation;
    operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
        currentUser.profilePic = image;
        [currentUser.managedObjectContext saveOnSuccess:NULL onFailure:^(NSError *error) {
            NSLog(@"%s: failed to save profile pic when requesting from facebook", __func__);
        }];
        [[NSNotificationCenter defaultCenter] postNotificationName:kPersonProfileNewNotification object:self userInfo:nil];
    }];
    [operation start];
    //broadcasting
    //[[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey: person}];
    
    //hide hud if possible
    //[MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES]; //handled in AlarmsVC
            
        
        
    //});

}


- (void)registerFacebook{
    //
}

#pragma mark - Weibo SDK

- (void)registerWeibo{
    // Weibo SDK
    //EWWeiboManager *weiboMgr = [EWWeiboManager sharedInstance];
    //[weiboMgr registerApp];
}

- (void)didReceiveWeiboRequest:(WBBaseRequest *)request {
    EWWeiboManager *weiboManager = [EWWeiboManager sharedInstance];
    [weiboManager didReceiveWeiboRequest:request];
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
    EWWeiboManager *weiboManager = [EWWeiboManager sharedInstance];
    [weiboManager didReceiveWeiboResponse:response];
}

-  (void)didReceiveWeiboSDKResponse:(id)JsonObject err:(NSError *)error {
    EWWeiboManager *weiboManager = [EWWeiboManager sharedInstance];
    [weiboManager didReceiveWeiboSDKResponse:JsonObject err:error];
}

#pragma mark - check
- (void)checkUserCache{
    NSArray *allPerson = [EWPersonStore sharedInstance].everyone;
    for (__block EWPerson *person in allPerson) {
        
        NSDate *modDate = [[EWDataStore sharedInstance] lastModifiedDateForObjectAtKey:person.profilePicKey];
        if([modDate isOutDated] && [modDate isEarlierThan:person.lastmoddate]){
            [[EWDownloadManager sharedInstance] downloadUrl:[NSURL URLWithString:person.profilePicKey] withCompletionBlock:^(NSData *data) {
                UIImage *img = [UIImage imageWithData:data];
                if (![person.profilePic isEqual:img]) {
                    //found change
                    NSLog(@"Found updated profile for user: %@", person.name);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        person.profilePic = img;
                        [[NSNotificationCenter defaultCenter] postNotificationName:kPersonProfileNewNotification object:person userInfo:@{@"person": person}];
                    });
                    
                }
            }];
        }
        
        modDate = [[EWDataStore sharedInstance] lastModifiedDateForObjectAtKey:person.bgImageKey];
        if([modDate isOutDated]){
            [[EWDownloadManager sharedInstance] downloadUrl:[NSURL URLWithString:person.bgImageKey] withCompletionBlock:^(NSData *data) {
                UIImage *img = [UIImage imageWithData:data];
                if (![person.bgImage isEqual:img]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        person.bgImage = img;
                    });
                    
                }
            }];
        }

    }
}


@end
