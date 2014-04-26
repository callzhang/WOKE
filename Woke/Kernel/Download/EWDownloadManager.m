//
//  EWDownloadManager.m
//  EarlyWorm
//
//  Created by Lee on 2/25/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWDownloadManager.h"
#import "EWMediaItem.h"
#import "EWDataStore.h"
#import "EWTaskItem.h"
#import "NSString+MD5.h"
#import "AVManager.h"

//#import "EWAppDelegate.h"

@interface EWDownloadManager(){}

//@property (nonatomic) EWTaskItem *task;
@end

@implementation EWDownloadManager
@synthesize session;
@synthesize downloadQueue;
@synthesize backgroundSessionCompletionHandler;
//@synthesize task;
@synthesize completionTask;
@synthesize completionTaskQueue;

+ (EWDownloadManager *)sharedInstance{
    static EWDownloadManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWDownloadManager alloc] init];
        manager.downloadQueue = [[NSMutableDictionary alloc] init];
        manager.completionTaskQueue = [[NSMutableDictionary alloc] init];
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

#pragma mark - Main download methods
- (void)downloadUrl:(NSURL *)Url{
    if ([Url isFileURL] || ![Url.absoluteString hasPrefix:@"http"]) {
        NSLog(@"Url is local file");
        return;
    }else if ([[EWDataStore sharedInstance] localPathForKey:Url.absoluteString]){
        //NSLog(@"Url already cached");
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:Url];
    //create task
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:request];
    //start task
    [downloadTask resume];
    
    NSLog(@"Url download task dispatched %@", Url);
}

- (void)downloadUrl:(NSURL *)Url withCompletionBlock:(void (^)(NSData *data))block{
    //assign
    [completionTaskQueue setObject:block forKey:Url];
    
    //dispatch
    [self downloadUrl:Url];
}

- (void)downloadMedia:(EWMediaItem *)media{
    //assume only audio to be downloaded
    NSString *path = media.audioKey;
    if (!path || path.length>500) return;
    
    //check if task has already exsited
    if ([downloadQueue objectForKey:path]) {
        return;
        
    }else if([[EWDataStore sharedInstance] localPathForKey:path]){
        //already cached
        NSLog(@"Media already cached");
        return;
        
    }else{
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:path]];
        //create task
        NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:request];
        //start task
        [downloadTask resume];
        //keep task info
        [downloadQueue setObject:media forKey:path];
        
        NSLog(@"Media download task dispatched: %@", media.audioKey);
    }
}

- (void)downloadTask:(EWTaskItem *)t withCompletionHandler:(void (^)(void))block{
    //task = t;
    completionTask = block;
    for (EWMediaItem *mi in t.medias) {
        
        [self downloadMedia:mi];
    }
    
    if (downloadQueue.count == 0) {
        NSLog(@"All media is cached already, no audio will be downloaded. Run completion block.");
        if (block) {
            block();
        }
    }
}

#pragma mark - URL delegate method

//Periodically informs the delegate about the download’s progress. (required)
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{

    /*
     Report progress on the task.
     If you created more than one task, you might keep references to them and report on them individually.
     */

    double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    NSLog(@"DownloadTask: %@ progress: (%lf%%)", downloadTask, progress * 100.0);
    dispatch_async(dispatch_get_main_queue(), ^{
        //self.progressView.progress = progress;
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL
{
    
    /*
     The download completed, you need to copy the file at targetPath before the end of this block.
     As an example, copy the file to the Documents directory of your app.
     */
    NSData *data = [NSData dataWithContentsOfURL:downloadURL];
    NSURLRequest *request = downloadTask.originalRequest;
    NSString *str = request.URL.absoluteString;
    
    //save
    [[EWDataStore sharedInstance] updateCacheForKey:str withData:data];
    NSLog(@"Saved FTW cache for %@", str);
    
    //completion task
    void (^completionBlock)(NSData *data) = completionTaskQueue[str];
    if (completionBlock) {
        NSLog(@"Excuting completion task for url download task: %@", str);
        completionBlock(data);
    }
    
    //media
    EWMediaItem *mi = downloadQueue[request.URL.absoluteString];
    if (mi) {
        NSLog(@"%s: media (%@) downloaded", __func__, mi.audioKey);
        //remove task from queue
        [downloadQueue removeObjectForKey:str];
    }
    
}

/**
 Tells the delegate that the task finished transferring data.
 Server errors are not reported through the error parameter. The only errors your delegate receives through the error parameter are client-side errors, such as being unable to resolve the hostname or connect to the host.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)t didCompleteWithError:(NSError *)error
{

    if (error == nil)
    {
        NSLog(@"%s: Task completed successfully: %@", __func__, t);
        
#ifdef BACKGROUND_TEST
        [[AVManager sharedManager] playSystemSound:t.originalRequest.URL];
#endif
        
    }
    else
    {
        NSLog(@"Task: %@ completed with error: %@", t, [error localizedDescription]);
    }
    if (completionTask) {
        completionTask();
    }
    
}

/*
 Tells the delegate that all messages enqueued for a session have been delivered.
 
 If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler: message, the session delegate will receive this message to indicate that all messages previously enqueued for this session have been delivered. At this time it is safe to invoke the previously stored completion handler, or to begin any internal updates that will result in invoking the completion handler.
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"%s: ======== Background Transfer download finished =========", __func__);
    
    
    //clear task
    //task = nil;
    if (backgroundSessionCompletionHandler) {
        NSLog(@"All tasks are finished, completionHandler returned");
        backgroundSessionCompletionHandler();
    }
}

//Tells the delegate that the download task has resumed downloading. (required)
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"Task %@ resumed to work", downloadTask);
}
@end
