//
//  EWDownloadManager.h
//  EarlyWorm
//
//  Created by Lee on 2/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EWMediaItem;

@interface EWDownloadManager : NSObject <NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSMutableDictionary *downloadTasks;

+ (EWDownloadManager *)sharedInstance;
- (void)downloadMedia:(EWMediaItem *)media;
@end
