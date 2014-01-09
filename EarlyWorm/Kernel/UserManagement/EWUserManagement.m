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
#import "MBProgressHUD.h"

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
    static EWUserManagement *g_UserManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_UserManager = [[EWUserManagement alloc] init];
    });
    return g_UserManager;
}


- (void)login{
    //init coredata and backend server
    [EWDataStore sharedInstance];
    [MBProgressHUD showHUDAddedTo:rootview animated:YES];
    //get logged in user
    if ([client isLoggedIn]) {
        //user already logged in
        //HUD
        
        //fetch user in coredata cache(offline) with related objects
        [client getLoggedInUserOnSuccess:^(NSDictionary *result) {
            NSFetchRequest *userFetch = [[NSFetchRequest alloc] initWithEntityName:@"EWPerson"];
            userFetch.predicate = [NSPredicate predicateWithFormat:@"username == %@", result[@"username"]];
            userFetch.relationshipKeyPathsForPrefetching = @[@"alarms", @"tasks", @"friends"];
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
                NSLog(@"User %@ data has fetched from cache on app startup", result[@"username"]);
                //merge changes
                EWPerson *me = results[0];
                [context refreshObject:me mergeChanges:YES];
                //assign to currentUser
                currentUser = me;
                
                //check alarms and tasks
                [[EWDataStore sharedInstance] checkAlarmData];
                
                //Broadcast user login event
                [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey:currentUser}];
                
                //login to fb?
                //TODO
                
                //HUD
                [MBProgressHUD hideAllHUDsForView:rootview animated:YES];
                
            } onFailure:^(NSError *error) { //fail to fetch user
                NSLog(@"Failed to fetch logged in user: %@", error.description);
                // Reset local session info
                [client.session clearSessionInfo];
                // present login view
                EWLogInViewController *controller = [[EWLogInViewController alloc] init];
                [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:controller animated:YES completion:NULL];
            }];
            
            
        } onFailure:^(NSError *error) { //failed to get logged in user
            //TODO
        }];
        
        
    }else{
        //if not logged in, register one
        EWPerson *newMe = [[EWPerson alloc] initNewUserInContext:context];
        //get ADID
        NSArray *adidArray = [[EWIO ADID] componentsSeparatedByString:@"-"];
        //username
        NSString *username = adidArray.firstObject;
        [newMe setUsername:username];
        //password
        NSString *password = adidArray.lastObject;
        [newMe setPassword:password];
        //persist password to user defaults locally
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:password forKey:@"password"];
        newMe.name = @"No Name";
        newMe.profilePic = [UIImage imageNamed:@"profile"];
        [context saveOnSuccess:^{
            NSLog(@"New user %@ created", newMe.username);
            currentUser = newMe;
            //login
            [client loginWithUsername:currentUser.username password:password onSuccess:^(NSDictionary *result) {
                [[EWDataStore sharedInstance] checkAlarmData]; //delete residual info (local notif)
                //broadcast
                [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey:currentUser}];
                //HUD
                [MBProgressHUD hideAllHUDsForView:rootview animated:YES];
            } onFailure:^(NSError *error) {
                [NSException raise:@"Unable to create temporary user" format:@"error: %@", error.description];
            }];
        } onFailure:^(NSError *error) {
            NSLog(@"Unable to create new user. %@", error.description);
            //try to login
            //get ADID
            NSArray *adidArray = [[EWIO ADID] componentsSeparatedByString:@"-"];
            //username
            NSString *username = adidArray.firstObject;
            //password
            NSString *password = adidArray.lastObject;
            [client loginWithUsername:username password:password onSuccess:^(NSDictionary *result) {
                currentUser = [[EWPersonStore sharedInstance] getPersonByID:username];
                
                [[EWDataStore sharedInstance] checkAlarmData]; //delete residual info (local notif)
                //broadcast
                [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{kUserLoggedInUserKey:currentUser}];
            } onFailure:^(NSError *error) {
                [NSException raise:@"Unable to login with temporary user" format:@"error: %@", error.description];
            }];

        }];
    }
}

//after fb login, fetch user managed object
- (void)updateUserData:(NSDictionary<FBGraphUser> *)user{
    //get currentUser first
    if(!currentUser){
        NSLog(@"======= Something wrong, currentUser is nil ========");
    }
    
    //[client getLoggedInUserOnSuccess:^(NSDictionary *result){
        
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
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
        [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
            currentUser.profilePic = image;
        }];
        
        //broadcasting
        [[NSNotificationCenter defaultCenter] postNotificationName:kPersonLoggedIn object:self userInfo:@{@"User": currentUser}];
        
        //hide hud if possible
        EWAppDelegate *delegate = (EWAppDelegate *)[UIApplication sharedApplication].delegate;
        [MBProgressHUD hideAllHUDsForView:delegate.window.rootViewController.view animated:YES];
            
        
        
    });
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
