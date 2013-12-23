//
//  EWDownloadMgr.m
//  EarlyWorm
//
//  Created by shenslu on 13-10-3.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWDownloadMgr.h"
#import "NSDate+Extend.h"
#import "ASIHTTPRequest.h"

@interface EWDownloadMgr ()

@property (nonatomic, retain) NSString *sessionID;

@end

@implementation EWDownloadMgr
@synthesize urlString = _urlString;
@synthesize description = _description;
@synthesize sessionID = _sessionID;
@synthesize resultData = _resultData;
@synthesize resultString = _resultString;
@synthesize delegate = _delegate;

#pragma Life Cycle

- (id)init {
    self = [super init];
    if (self) {
        _urlString = nil;
        
        _resultData = nil;
        _resultString = nil;
            
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
        _sessionID = [NSString stringWithFormat:@"%f", timeInterval];
    }
    return self;
}

#pragma mark - Call Event

- (void)startDownload {
    NSLog(@"startDownload %@ ", _urlString);
    
    NSURL *url = [NSURL URLWithString:_urlString];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    [request setDelegate:self];
    [request startAsynchronous];
}

- (NSData *)syncDownloadByGet {
    
    NSURL *url = [NSURL URLWithString:_urlString];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    [request startSynchronous];
    
    NSError *error = [request error];
    
    if (!error) {
        NSData *data = [request responseData];
        return data;
    }
    
    return nil;
}

#pragma mark - ASIHTTPRequest Delegate

- (void)requestFinished:(ASIHTTPRequest *)request {
    
    // 当以文本形式读取返回内容时用这个方法
    
    NSString *responseString = [request responseString];
    
    if (responseString && responseString.length > 0) {
        _resultString = [responseString copy];
        
        SAFE_DELEGATE_VOID(_delegate, @selector(EWDownloadMgr:didFinishedDownloadString:), EWDownloadMgr:self didFinishedDownloadString:self.resultString);
        return;
    }
    
    // 当以二进制形式读取返回内容时用这个方法
    NSData *responseData = [request responseData];
    if (responseData && responseData.length > 0) {
        _resultData = [responseData copy];
        SAFE_DELEGATE_VOID(_delegate, @selector(EWDownloadMgr:didFinishedDownloadData:), EWDownloadMgr:self didFinishedDownloadData:self.resultData);
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    
    NSError *error = [request error];
    SAFE_DELEGATE_VOID(_delegate, @selector(EWDownloadMgr:didFailedDownload:), EWDownloadMgr:self didFailedDownload:error);
}

#pragma mark - Setter & Getter

- (NSString *)sessionID {
    return _sessionID;
}

@end
