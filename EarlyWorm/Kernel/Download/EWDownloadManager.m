//
//  EWDownloadManager.m
//  EarlyWorm
//
//  Created by Lee on 2/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWDownloadManager.h"
#import "EWMediaItem.h"

@implementation EWDownloadManager
@synthesize session;
@synthesize downloadTasks;

+ (EWDownloadManager *)sharedInstance{
    static EWDownloadManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWDownloadManager alloc] init];
    });
    return manager;
}

- (NSURLSession *)session{
    if (session == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.wokealarm.media"];
            session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                    delegate:self
                                               delegateQueue:[NSOperationQueue mainQueue]];
        });
    }
    return session;
}

- (void)downloadMedia:(EWMediaItem *)media{
    //assume only audio to be downloaded
    NSString *path = media.audioKey;
    //check if task has already exsited
    if ([downloadTasks objectForKey:path]) {
        return;
    }else{
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:path]];
        NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:request];
        [downloadTask resume];
        //save
        [downloadTasks setObject:downloadTask forKey:path];
    }
}




@end

@implementation EWDownloadManager() <NSURLSessionDelegate>

<#methods#>

@end
