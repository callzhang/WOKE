//
//  EWFacebookManager.m
//  EarlyWorm
//
//  Created by shenslu on 13-10-4.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWFacebookManager.h"
#import "EWAppDelegate.h"

#import "EWDownloadMgr.h"
#import "JSON.h"
#import <FacebookSDK/FacebookSDK.h>



static EWFacebookManager *g_facebookMgr = nil;
static BOOL g_isFriendListHasGotAll = NO;
static NSMutableArray *g_friendList = nil;

@interface EWFacebookManager ()

@property (nonatomic, strong) NSString *nextPageURL;
@property (nonatomic, weak) id<EWFacebookManagerDelegate> delegate;

@end

@interface EWFacebookManager(DownloadMgr) <EWDownloadMgrDelegate>
@end

//@interface HFViewController (FaceB) <FBLoginViewDelegate>
//@end

@implementation EWFacebookManager
@synthesize session = _session;
//@synthesize accessToken = _accessToken;
@synthesize nextPageURL = _nextPageURL;

#pragma mark - Life Cycle

- (id)init {
    self = [super init];
    if (self) {
//        _accessToken = nil;
        _session = [[FBSession alloc] init];//WithAppID:kFacebookAppID permissions:nil defaultAudience:FBSessionDefaultAudienceNone urlSchemeSuffix:nil tokenCacheStrategy:nil];

        g_friendList = [NSMutableArray array];
    }
    return self;
}

+ (EWFacebookManager *)sharedInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_facebookMgr = [[EWFacebookManager alloc] init];
    });
    return g_facebookMgr;
}

+ (void)destroyInstance {
    if (!g_facebookMgr) {
        return;
    }
    g_facebookMgr = nil;
}

+ (void)unregisterInstanceDelegate {
    if (!g_facebookMgr) {
        return;
    }
    [g_facebookMgr UnregisterDelegate];
}

- (void)RegisterDelegate:(id<EWFacebookManagerDelegate>)delegate {
    self.delegate = delegate;
}

- (void)UnregisterDelegate {
    self.delegate = nil;
}

#pragma mark - Call Event

- (void)activeFacebookApp {
    [FBAppEvents activateApp];
    [FBAppCall handleDidBecomeActiveWithSession:self.session];
}

- (void)doAuth {
    if (self.session.state != FBSessionStateCreated) {
        // Create a new, logged out session.
        self.session = [[FBSession alloc] init];
    }
    
    // if the session isn't open, let's open it now and present the login UX to the user
    [self.session openWithCompletionHandler:^(FBSession *session,
                                                     FBSessionState status,
                                                     NSError *error) {
        // and here we make sure to update our UX according to the new session state
        [self authFinished];
    }];
}

- (void)logoutFacebook {
    if (self.session.isOpen) {
        [self.session closeAndClearTokenInformation];
    }
}

- (void)getFriendListByURL:(NSString *)urlString  {
    EWDownloadMgr *downloadMgr = [[EWDownloadMgr alloc] init];
    downloadMgr.delegate = self;
    downloadMgr.urlString = urlString;
    
    NSLog(@"Get Friend List URL : %@", downloadMgr.urlString);
    [downloadMgr startDownload];
}

- (void)getFriendList {
    [self getFriendListByURL:[NSString stringWithFormat:@"https://graph.facebook.com/me/friends?access_token=%@",
                              self.session.accessTokenData.accessToken]];
}

- (void)appendFriendList {
    if (self.nextPageURL) {
        [self getFriendListByURL:self.nextPageURL];
    }
}

- (void)sendWebLink {
    NSURL *urlToShare = [NSURL URLWithString:@"http://developers.facebook.com/ios"];

    FBAppCall *appCall = [FBDialogs presentShareDialogWithLink:urlToShare name:@"Hello Facebook" caption:nil  description:@"The 'Hello Facebook' sample application showcases simple Facebook integration."  picture:nil clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error.description);
            } else {
                NSLog(@"Success!");
            }
    }];
    
    if (!appCall) {
        // Next try to post using Facebook's iOS6 integration
        
        EWAppDelegate *appDelegate = (EWAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        UIWindow *window = appDelegate.window;
        UIViewController *viewController = window.rootViewController;
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            viewController = [((UINavigationController *)viewController) topViewController];
        }
        
        BOOL displayedNativeDialog = [FBDialogs presentOSIntegratedShareDialogModallyFrom:viewController initialText:nil image:nil url:urlToShare handler:nil];
        
        if (!displayedNativeDialog) {
            // Lastly, fall back on a request for permissions and a direct post using the Graph API
            [self performPublishAction:^{
                NSString *message = [NSString stringWithFormat:@"Updating status at %@", [NSDate date]];
                
                FBRequestConnection *connection = [[FBRequestConnection alloc] init];
                
                connection.errorBehavior = FBRequestConnectionErrorBehaviorReconnectSession
                | FBRequestConnectionErrorBehaviorAlertUser
                | FBRequestConnectionErrorBehaviorRetry;
                
                [connection addRequest:[FBRequest requestForPostStatusUpdate:message]
                     completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                         
                         [self showSendMessage:message result:result error:error];
                     }];
                [connection start];
                
            }];
        }
    }

}

- (void)showSendMessage:(NSString *)message result:(id)result error:(NSError *)error {
    NSString *alertMsg;
    NSString *alertTitle;
    if (error) {
        alertTitle = @"Error";
        // Since we use FBRequestConnectionErrorBehaviorAlertUser,
        // we do not need to surface our own alert view if there is an
        // an fberrorUserMessage unless the session is closed.
        if (error.fberrorUserMessage && FBSession.activeSession.isOpen) {
            alertTitle = nil;
            
        } else {
            // Otherwise, use a general "connection problem" message.
            alertMsg = @"Operation failed due to a connection problem, retry later.";
        }
    } else {
        NSDictionary *resultDict = (NSDictionary *)result;
        alertMsg = [NSString stringWithFormat:@"Successfully posted '%@'.", message];
        NSString *postId = [resultDict valueForKey:@"id"];
        if (!postId) {
            postId = [resultDict valueForKey:@"postId"];
        }
        if (postId) {
            alertMsg = [NSString stringWithFormat:@"%@\nPost ID: %@", alertMsg, postId];
        }
        alertTitle = @"Success";
    }
    
    if (alertTitle) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
           message:alertMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}

// Convenience method to perform some action that requires the "publish_actions" permissions.
- (void) performPublishAction:(void (^)(void)) action {
    // we defer request for permission to post to the moment of post, then we check for the permission
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
        // if we don't already have the permission, then we request it now
        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"]
            defaultAudience:FBSessionDefaultAudienceFriends
            completionHandler:^(FBSession *session, NSError *error) {
                if (!error) {
                    action();
                }
                else if (error.fberrorCategory != FBErrorCategoryUserCancelled){
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission denied" message:@"Unable to get permission to post" delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];
                    [alertView show];
                }

            }];
    } else {
        action();
    }
}

#pragma mark - Callbacks

- (void)authFinished {

//    self.accessToken = [self.session.accessTokenData.accessToken copy];
    
    // Do Update
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LOCALSTR(@"Facebook_Auth_Success") message:nil delegate:nil cancelButtonTitle:LOCALSTR(@"Common_OK") otherButtonTitles:nil];
    [alert show];
}

@end

@implementation EWFacebookManager(DownloadMgr)

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFinishedDownload:(NSData *)result {
    NSString *string = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@", string);
    
    // JSON
    NSDictionary *resp = [string JSONValue];
    if (!resp) {
        return;
    }
    
    NSArray *array = [resp objectForKey:@"data"];
    NSDictionary *paging = [resp objectForKey:@"paging"];
    NSString *nextPageURL = [paging objectForKey:@"next"];
    
    self.nextPageURL = nextPageURL;

    if (array && array.count > 0) {
        [g_friendList addObjectsFromArray:array];
    }
    
    g_isFriendListHasGotAll = (self.nextPageURL == nil);
    
    //done
    SAFE_DELEGATE_VOID(_delegate, @selector(EWFacebookManagerDidGotFriendList:isAll:), EWFacebookManagerDidGotFriendList:g_friendList isAll:g_isFriendListHasGotAll);
    
}

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFailedDownload:(NSError *)error {
    NSLog(@"%@", error);
}

@end


