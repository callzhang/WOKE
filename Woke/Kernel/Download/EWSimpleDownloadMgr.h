//
//  EWSimpleDownloadMgr.h
//  EarlyWorm
//
//  Created by shenslu on 13-10-3.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWSimpleDownloadMgr;
@protocol EWSimpleDownloadMgrDelegate <NSObject>

- (void)EWSimpleDownloadMgr:(EWSimpleDownloadMgr *)mgr didFinishedDownload:(NSData *)result;
- (void)EWSimpleDownloadMgr:(EWSimpleDownloadMgr *)mgr didFailedDownload:(NSError *)error;

@end

@interface EWSimpleDownloadMgr : NSObject

@property (nonatomic, weak) id<EWSimpleDownloadMgrDelegate> delegate;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) NSData *resultData;
@property (nonatomic, strong) NSString *description;

//+ (EWSimpleDownloadMgr *)sharedInstance;

- (NSString *)sessionID;

// 异步下载
- (void)startDownload;
- (void)cancelDownload;

// 同步下载
- (NSData *)syncDownloadByGet;

@end
