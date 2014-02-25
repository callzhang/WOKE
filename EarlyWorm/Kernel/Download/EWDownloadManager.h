//
//  EWDownloadManager.h
//  EarlyWorm
//
//  Created by Lee on 2/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWDownloadManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property NSURLSession *session;

+ (EWDownloadManager *)sharedInstance;
@end
