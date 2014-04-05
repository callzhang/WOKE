//
//  EWWeiboManager.m
//  EarlyWorm
//
//  Created by shenslu on 13-9-24.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWWeiboManager.h"
#import "EWAppDelegate.h"
#import "EWDownloadMgr.h"
#import "WeiboSDk.h"

#import "JSON.h"

#define kRedirectURI @"https://api.weibo.com/oauth2/default.html"

static EWWeiboManager *g_weiboManager = nil;

static NSInteger g_currentFriendPage = 0;
static BOOL g_isFriendListHasGotAll = NO;
static NSMutableArray *g_friendList = nil;

@interface EWWeiboManager ()

@property (nonatomic, weak) id<EWWeiboManagerDelegate> delegate;

@end

@interface EWWeiboManager(DownloadMgr) <EWDownloadMgrDelegate>
@end

@implementation EWWeiboManager
@synthesize delegate = _delegate;
@synthesize accessToken = _accessToken;
@synthesize userID = _userID;
@synthesize userInfo = _userInfo;

#pragma mark - LifeCycle

- (id)init {
    self = [super init];
    if (self) {
        _accessToken = nil;
        _userInfo = nil;
        _userID = nil;
        
        g_friendList = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    [self UnregisterDelegate];
}

+ (EWWeiboManager *)sharedInstance {
    if (!g_weiboManager) {
        g_weiboManager = [[EWWeiboManager alloc] init];
    }
    
    return g_weiboManager;
}

+ (void)destroyInstance {
    if (!g_weiboManager) {
        return;
    }
    g_weiboManager = nil;
}

+ (void)unregisterInstanceDelegate {
    if (!g_weiboManager) {
        return;
    }
    [g_weiboManager UnregisterDelegate];
}

- (void)RegisterDelegate:(id<EWWeiboManagerDelegate>)delegate {
    self.delegate = delegate;
}

- (void)UnregisterDelegate {
    self.delegate = nil;
}

#pragma mark - Call Event

- (void)registerApp {
    [WeiboSDK registerApp:kWeiboSDKAppKey];
    [WeiboSDK enableDebugMode:YES];
}

- (void)doAuth {
    WBAuthorizeRequest *request = [WBAuthorizeRequest request];
    request.redirectURI = kRedirectURI;
    request.scope = @"email,direct_messages_write";
//    request.userInfo = @{@"SSO_From": @"SendMessageToWeiboViewController",
//                         @"Other_Info_1": [NSNumber numberWithInt:123], @"Other_Info_2": @[@"obj1", @"obj2"],
//                         @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
    [WeiboSDK sendRequest:request];
}

- (void)logoutWeibo {
    //EWAppDelegate *myDelegate  = (EWAppDelegate*)[[UIApplication  sharedApplication] delegate];
    //[WeiboSDK logOutWithToken:self.accessToken delegate:myDelegate];
}

- (void)inviteFriend {
    //EWAppDelegate *myDelegate =(EWAppDelegate*)[[UIApplication sharedApplication] delegate];
    //[WeiboSDK inviteFriend:@"testinvite" withUid:@"好友uid" withToken:self.accessToken delegate:myDelegate];
}
/*
 参数说明：
 
                必选          类型及范围	说明
source          false        string     采用OAuth授权方式不需要此参数，其他授权方式为必填参数，数值为应用的AppKey。
access_token	false        string     采用OAuth授权方式为必填参数，其他授权方式不需要此参数，OAuth授权后获得。
uid             true         int64      需要获取双向关注列表的用户UID。
count           false        int        单页返回的记录条数，默认为50。
page            false        int        返回结果的页码，默认为1。
sort            false        int        排序类型，0：按关注时间最近排序，默认为0。
 */

- (void)getFriendListAtPage:(NSInteger)page {
    EWDownloadMgr *downloadMgr = [[EWDownloadMgr alloc] init];
    downloadMgr.delegate = self;
    downloadMgr.urlString = [NSString stringWithFormat:@"https://api.weibo.com/2/friendships/friends/bilateral.json?source=%@&access_token=%@&uid=%@&count=%d&page=%ld", kWeiboSDKAppKey, self.accessToken, self.userID, 50, (long)page];
    
    NSLog(@"Get Friend List URL : %@", downloadMgr.urlString);
    [downloadMgr startDownload];
}

- (void)getFriendList {
    g_currentFriendPage = 1;
    g_isFriendListHasGotAll = NO;
    [g_friendList removeAllObjects];
    
    [self getFriendListAtPage:g_currentFriendPage];
}

- (void)appendFriendList {
    if (!g_isFriendListHasGotAll) {
        g_currentFriendPage++;
        [self getFriendListAtPage:g_currentFriendPage];
    }
}

// Send Message

- (void)sendWebLink {
    WBWebpageObject *pageObject = [WBWebpageObject object];
    pageObject.objectID = @"identifier1";
    pageObject.thumbnailData = [NSData dataWithContentsOfFile:@"1.jpg"];
    pageObject.title = @"Sample Title";
    pageObject.description = @"Sample Description";
    pageObject.webpageUrl = @"http://www.weibo.com";
    
    WBMessageObject *message = [[WBMessageObject alloc] init];
    message.text = @"This is a test";
    message.mediaObject = pageObject;
    WBSendMessageToWeiboRequest *req = [[WBSendMessageToWeiboRequest alloc] init];
    req.message = message;
    [WeiboSDK sendRequest:req];
}

#pragma mark - Weibo SDK Callbacks

- (void)didReceiveWeiboRequest:(WBBaseRequest *)request {
    // request
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
    
    NSString *title = nil;

    if ([response isKindOfClass:WBAuthorizeResponse.class]) {
        WBAuthorizeResponse *authorizeResp = (WBAuthorizeResponse *)response;
        
        
        NSLog(@"%@", [NSString stringWithFormat:@"响应状态: %d\nresponse.userId: %@\nresponse.accessToken: %@\n响应UserInfo数据: %@\n 原请求UserInfo数据: %@", response.statusCode, [(WBAuthorizeResponse *)response userID], [(WBAuthorizeResponse *)response accessToken],response.userInfo, response.requestUserInfo]);
        
        if (authorizeResp.statusCode != WeiboSDKResponseStatusCodeSuccess) {
            title = LOCALSTR(@"Weibo_Auth_Error");
        }
        else {
            title = LOCALSTR(@"Weibo_Auth_Success");
            
            self.userInfo = authorizeResp.userInfo;
            self.userID = authorizeResp.userID;
            self.accessToken = authorizeResp.accessToken;
        }

    }
    else if ([response isKindOfClass:[WBSendMessageToWeiboResponse class]]) {
        
        if (response.statusCode != WeiboSDKResponseStatusCodeSuccess) {
            title = LOCALSTR(@"Weibo_Send_Content_Error");
        }
        else {
            title = LOCALSTR(@"Weibo_Send_Content_Success");
        }

        NSLog(@"打印消息中的设置信息%@",response.userInfo);
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:LOCALSTR(@"Common_OK") otherButtonTitles:nil];
    [alert show];
}

- (void)didReceiveWeiboSDKResponse:(id)JsonObject err:(NSError *)error {
    NSString *title = nil;
    NSString *message = nil;
    
    if  (error) {
        title = LOCALSTR(@"Weibo_Logout_Error");
        message = [NSString stringWithFormat:@"%@",JsonObject];
    } else {
        title = LOCALSTR(@"Weibo_Logout_Success");
        message = nil;
    }
    
    NSLog(@"%@: %@", title, message);
    
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:LOCALSTR(@"Common_OK") otherButtonTitles:nil];

//    [alert show];
}

@end

@implementation EWWeiboManager(DownloadMgr)

// TODO: 此处可能出现一个问题是当前list被重复拉取，暂时简单做
- (BOOL)isDepulicated:(NSArray *)array {
    
    if (array == nil && g_friendList == nil) {
        return YES;
    }
    
    if (array.count ==0 && g_friendList.count == 0) {
        return YES;
    }
    
    if (array.count ==0 || g_friendList.count == 0) {
        return NO;
    }

    NSInteger index1 = array.count-1;
    NSInteger index2 = g_friendList.count-1;
    if (index1 >= 0 && index2 >= 0) {
        NSDictionary *dict1 = [array objectAtIndex:index1];
        NSNumber *userID1 = [dict1 objectForKey:@"id"];
        
        NSDictionary *dict2 = [g_friendList objectAtIndex:index2];
        NSNumber *userID2 = [dict2 objectForKey:@"id"];
        return [userID1 isEqualToNumber:userID2];
    }
    return NO;
}

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFinishedDownload:(NSData *)result {
    NSString *string = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@", string);

    // JSON
    NSDictionary *resp = [string JSONValue];
    if (!resp) {
        return;
    }
    
    NSInteger total = [[resp objectForKey:@"total_number"] integerValue];
    NSArray *array = [resp objectForKey:@"users"];
    
    if (array && array.count > 0) {
        if ([self isDepulicated:array]) {
            return;
        }
        
        [g_friendList addObjectsFromArray:array];
    }
    
    
    if (g_friendList.count > total) {
        // error
        NSLog(@"ERROR: 列表数超过总数");
    }

    g_isFriendListHasGotAll = (g_friendList.count >= total);

    //done
    SAFE_DELEGATE_VOID(_delegate, @selector(EWWeiboManagerDidGotFriendList:isAll:), EWWeiboManagerDidGotFriendList:g_friendList isAll:g_isFriendListHasGotAll);
    
}

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFailedDownload:(NSError *)error {
    NSLog(@"%@", error);
}

@end

