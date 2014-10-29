//
//  EWDownloadManager.h
//  EarlyWorm
//
//  Created by Lee on 2/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EWMedia, EWTaskItem;

@interface EWDownloadManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic) NSURLSession *session;
/**
 The queue to store the media being downloaded
 */
@property (nonatomic) NSMutableDictionary *downloadQueue;
/**
 *The queue to store completion task for each download;
 */
@property (nonatomic) NSMutableDictionary *completionTaskQueue;
@property (copy) void (^backgroundSessionCompletionHandler)();
@property (copy) void (^completionTask)();

+ (EWDownloadManager *)sharedInstance;

/**
 *Download content in url and save to cache
 */
- (void)downloadUrl:(NSURL *)Url;

/**
 *Download content in url and save to cache, and finish the download with a block.
 */
- (void)downloadUrl:(NSURL *)Url withCompletionBlock:(void (^)(NSData *data))block;

/**
 The main method for download media in background when another user sends a voice tone when app is suspended
 */
- (void)downloadMedia:(EWMedia *)media;

/**
 Download all medias (and anything needed) in task item in background mode.
 */
- (void)downloadTask:(EWTaskItem *)task withCompletionHandler:(void (^)(void))block;

@end
