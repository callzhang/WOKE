//
//  EWDownloadManager.m
//  EarlyWorm
//
//  Created by Lee on 2/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWDownloadManager.h"

@implementation EWDownloadManager
@synthesize session;

+ (EWDownloadManager *)sharedInstance{
    static EWDownloadManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWDownloadManager alloc] init];
    });
    return manager;
}

- (NSURLSession *)session{
    if (!session) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *identifier = @"com.wokealarm.download";
            NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
            session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                    delegate:self
                                               delegateQueue:[NSOperationQueue mainQueue]];
        });
        
    }
    return session;
}

- (NSURLSession *)backgroundURLSession
{
    
}
@end
