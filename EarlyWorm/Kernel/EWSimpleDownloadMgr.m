//
//  EWSimpleDownloadMgr.m
//  EarlyWorm
//
//  Created by shenslu on 13-10-3.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWSimpleDownloadMgr.h"
#import "NSDate+Extend.h"

@interface EWSimpleDownloadMgr ()

@property (nonatomic, retain) NSString *sessionID;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation EWSimpleDownloadMgr
@synthesize urlString = _urlString;
@synthesize description = _description;
@synthesize data = _data;
@synthesize connection = _connection;
@synthesize sessionID = _sessionID;
@synthesize resultData = _resultData;
@synthesize delegate = _delegate;

#pragma Life Cycle

- (id)init {
    self = [super init];
    if (self) {
        _urlString = nil;
        
        _resultData = nil;
            
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
        _sessionID = [NSString stringWithFormat:@"%f", timeInterval];
    }
    return self;
}

#pragma mark - Call Event

- (void)startDownload {
    NSLog(@"startDownload %@ ", _urlString);
    
    self.data = [NSMutableData data];
    
    // alloc+init and start an NSURLConnection; release on completion/failure
    
    NSURL *url = [NSURL URLWithString:_urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
//    if (cookie) {
//        [request setValue:cookie forHTTPHeaderField:@"Cookie"];
//    }
    
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)cancelDownload {
    [self.connection cancel];
    self.connection = nil;
    self.data = nil;
}

- (NSData *)syncDownloadByGet {
    NSURL *url = [NSURL URLWithString:self.urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
//    if (![cookie isEqualToString:@"main"]) {
//        [request setValue:cookie forHTTPHeaderField:@"Cookie"];
//    }
    
    NSError *error;
    NSURLResponse *aResponse;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&aResponse error:&error];
//    _response = aResponse;
    
    if (error) {
//        UIAlertView *alertView = [[UIAlertView alloc]
//                                  initWithTitle:@"错误"
//                                  message:@"加载数据失败，请检查网络状态"
//                                  delegate:self
//                                  cancelButtonTitle:@"确定"
//                                  otherButtonTitles:nil];
//        [alertView show];
        NSLog(@"加载数据失败，请检查网络状态");
    }
    return data;
}

#pragma mark - Setter & Getter 

- (NSString *)sessionID {
    return _sessionID;
}

#pragma mark - Download support (NSURLConnectionDelegate)

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (data) {
        [self.data appendData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
//    self.data = [NSData data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    self.data = nil;
    self.connection = nil;
    NSLog(@"Download data : %@ error: %@", _urlString, error);
    
    SAFE_DELEGATE_VOID(_delegate, @selector(EWSimpleDownloadMgr:didFailedDownload:), EWSimpleDownloadMgr:self didFailedDownload:error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    _resultData = [self.data copy];
    
    self.data = nil;
    self.connection = nil;

    SAFE_DELEGATE_VOID(_delegate, @selector(EWSimpleDownloadMgr:didFinishedDownload:), EWSimpleDownloadMgr:self didFinishedDownload:self.resultData);
}

@end
