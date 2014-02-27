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
#import <CoreLocation/CoreLocation.h>

//model
#import "EWPerson.h"
#import "EWPersonStore.h"

//stackholder
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
    //init coredata and backend server
    [EWDataStore sharedInstance];
    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    //get logged in user
    if ([client isLoggedIn]) {
        //user already logged in
        //fetch user in coredata cache(offline) with related objects
        [client getLoggedInUserOnSuccess:^(NSDictionary *result) {
            NSFetchRequest *userFetch = [[NSFetchRequest alloc] initWithEntityName:@"EWPerson"];
            userFetch.predicate = [NSPredicate predicateWithFormat:@"username == %@", result[@"username"]];
            userFetch.relationshipKeyPathsForPrefetching = @[@"alarms", @"tasks", @"friends"];//no use for SM
            userFetch.returnsObjectsAsFaults = NO;
            //cache only
            SMRequestOptions *options = [SMRequestOptions options];
            options.fetchPolicy = SMFetchPolicyTryCacheElseNetwork;
            //fetch
            [context executeFetchRequest:userFetch returnManagedObjectIDs:NO successCallbackQueue:nil failureCallbackQueue:nil options:options onSuccess:^(NSArray *results) {
                if (results.count != 1) {
                    // There should only be one result
                    [NSException raise:@"More than one user fetched" format:@"Check username:%@",result[@"username"]];
                }
                //contineue user log in tasks
                NSLog(@"UserManagement: User %@ data has fetched from cache", result[@"username"]);
                //merge changes
                currentUser = results[0];
                [context refreshObject:currentUser mergeChanges:YES];
                
                //check alarms and tasks
                //[[EWDataStore sharedInstance] checkAlarmData];
                
                //Broadcast user login event
                [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey:currentUser}];
                
                //login to fb
                //TODO
                
                //HUD
                //[MBProgressHUD hideAllHUDsForView:rootview animated:YES];
                
            } onFailure:^(NSError *error) { //fail to fetch user
                NSLog(@"Failed to fetch logged in user: %@", error.description);
                // Reset local session info
                [client.session clearSessionInfo];
                // present login view
                EWLogInViewController *controller = [[EWLogInViewController alloc] init];
                [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:controller animated:YES completion:NULL];
            }];
            
            
        } onFailure:^(NSError *error) { //failed to get logged in user
            NSLog(@"UserManagement: Failed to get logged in user from SM Cache");
        }];
        
        
    }else{
        [self loginWithDeviceID];
    }
    
    
    //watch for login event
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoginEventHandler) name:kPersonLoggedIn object:Nil];
}

- (void)loginWithDeviceID{
    //log in using local machine info
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
        
        [[EWDataStore sharedInstance] checkAlarmData]; //delete residual info (local notif)
        
        //broadcast
        [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey:currentUser}];
        
    } onFailure:^(NSError *error) {
        //if not logged in, register one
        EWPerson *newMe = [[EWPerson alloc] initNewUserInContext:context];
        [newMe setUsername:username];
        [newMe setPassword:password];
        newMe.name = @"No Name";
        newMe.profilePic = [UIImage imageNamed:@"profile"];
        currentUser = newMe;
        
        //persist password to user defaults locally
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:password forKey:@"password"];
        
        //save new user
        [context saveOnSuccess:^{
            NSLog(@"New user %@ created", newMe.username);
            
            //login
            [client loginWithUsername:currentUser.username password:password onSuccess:^(NSDictionary *result){
                //[[EWDataStore sharedInstance] checkAlarmData]; //delete residual info (local notif)
                //broadcast
                [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey:currentUser}];
                //HUD
                //[MBProgressHUD hideAllHUDsForView:rootview animated:YES];
            } onFailure:^(NSError *error) {
                [NSException raise:@"Unable to create temporary user" format:@"error: %@", error.description];
            }];
        } onFailure:^(NSError *error) {
            [NSException raise:@"Unable to create new user" format:@"Reason %@", error.description];
            
        }];
    }];

}

- (void)logout{
    //log out SM
    [client logoutOnSuccess:^(NSDictionary *result) {
        NSLog(@"Successfully logged out");
        //log out fb
        [FBSession.activeSession closeAndClearTokenInformation];
        //log in with device id
        [self loginWithDeviceID];
        
    } onFailure:^(NSError *error) {
        EWAlert(@"Unable to logout, please check!");
        
    }];
}


#pragma mark - userLoginEventHandler
- (void)userLoginEventHandler{
    [self registerAPNS];
    [self registerLocation];
}

#pragma mark - location
- (void)registerLocation{
    [SMGeoPoint getGeoPointForCurrentLocationOnSuccess:^(SMGeoPoint *geoPoint) {
        currentUser.lastLocation = [NSKeyedArchiver archivedDataWithRootObject:geoPoint];
        NSLog(@"Get user location with lat: %@, lon: %@", geoPoint.latitude, geoPoint.longitude);
        
        //reverse search address
        CLGeocoder *geoloc = [[CLGeocoder alloc] init];
        CLLocation *clloc = [[CLLocation alloc] initWithLatitude:[geoPoint.latitude doubleValue] longitude:[geoPoint.latitude doubleValue]];
        [geoloc reverseGeocodeLocation:clloc completionHandler:^(NSArray *placemarks, NSError *error) {
            NSLog(@"Found placemarks: %@, error", placemarks);
            if (error == nil && [placemarks count] > 0) {
                CLPlacemark *placemark = [placemarks lastObject];
                NSString *address = [NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                                     placemark.subThoroughfare, placemark.thoroughfare,
                                     placemark.postalCode, placemark.locality,
                                     placemark.administrativeArea,
                                     placemark.country];
#ifdef DEV_TEST
                EWAlert(address);
#endif
                //get info
                currentUser.city = placemark.locality;
                currentUser.region = placemark.country;
            } else {
                NSLog(@"%@", error.debugDescription);
            }
            
            //save
            [context saveOnSuccess:^{
                NSLog(@"Location has been updated to server");
            } onFailure:^(NSError *error) {
                [NSException raise:@"unable to save user location" format:@"Location: %@, error:%@", geoPoint, error];
            }];

        }];
        
        
    } onFailure:^(NSError *error) {
        NSLog(@"===== Unable to location curent user =====");
        //TODO
    }];
}

#pragma mark - Keep alive
- (void)updateLastSeen{
    NSLog(@"scheduled update last seen recurring task");
    [NSTimer timerWithTimeInterval:600 target:self selector:@selector(keepAlive) userInfo:nil repeats:YES];
}

- (void)keepAlive{
    if (currentUser) {
        currentUser.lastSeenDate = [NSDate date];
        [context saveOnSuccess:^{
            NSLog(@"Updated last seen date");
        } onFailure:^(NSError *error) {
            NSLog(@"Failed to update last seen date");
        }];
    }
}

#pragma mark - PUSH

- (void)registerAPNS{
    //push
#if TARGET_IPHONE_SIMULATOR
    //Code specific to simulator
#else
    pushClient = [[SMPushClient alloc] initWithAPIVersion:@"0" publicKey:kStackMobKeyDevelopment privateKey:kStackMobKeyDevelopmentPrivate];
    //register everytime in case for events like phone replacement
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert];
#endif
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
        [NSException raise:@"Failed to regiester push token with StackMob" format:@"Reason: %@", error.description];
    }];
    return;
    
}

//after fb login, fetch user managed object
- (void)updateUserWithFBData:(NSDictionary<FBGraphUser> *)user{
    //get currentUser first
    if(!currentUser){
        NSLog(@"======= Something wrong, currentUser is nil ========");
    }
    
    //[client getLoggedInUserOnSuccess:^(NSDictionary *result){
        
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    EWPerson *person = [[EWPersonStore sharedInstance] getPersonByID:user.username];
    currentUser = person;
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
    NSString *imageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture", user.id];
    //[self.profileView setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage imageNamed:@"profile.png"]];
    
    //[self.profileView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:imageUrl]] placeholderImage:[UIImage imageNamed:@"profile.png"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {//
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageUrl]];
    AFImageRequestOperation *operation;
    operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
        currentUser.profilePic = image;
        [[NSNotificationCenter defaultCenter] postNotificationName:kPersonProfilePicDownloaded object:self userInfo:nil];
    }];
    [operation start];
    //broadcasting
    [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey: person}];
    
    //hide hud if possible
    EWAppDelegate *delegate = (EWAppDelegate *)[UIApplication sharedApplication].delegate;
    [MBProgressHUD hideAllHUDsForView:delegate.window.rootViewController.view animated:YES];
            
        
        
    //});
    /*
    } onFailure:^(NSError *err){
        // Error
        [NSException raise:@"Unable to find current user" format:@"Check your code: %@", err.description];
    }];*/
}

#pragma mark - FACEBOOK
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


@end
