//
//  EWDownloadManager.h
//  EarlyWorm
//
//  Created by Lee on 2/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EWMediaItem, EWTaskItem;

@interface EWDownloadManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSMutableDictionary *downloadQueue;
@property (copy) void (^backgroundSessionCompletionHandler)();

+ (EWDownloadManager *)sharedInstance;
/**
 The main method for download media in background when another user sends a voice tone when app is suspended
 */
- (void)downloadMedia:(EWMediaItem *)media;

/**
 Download all medias (and anything needed) in task item in background mode.
 */
- (void)downloadTask:(EWTaskItem *)task;
@end
