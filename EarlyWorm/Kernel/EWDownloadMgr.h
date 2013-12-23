//
//  EWDownloadMgr.h
//  EarlyWorm
//
//  Created by shenslu on 13-10-3.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWDownloadMgr;
@protocol EWDownloadMgrDelegate <NSObject>

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFinishedDownloadData:(NSData *)resultData;
- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFinishedDownloadString:(NSString *)resultString;

- (void)EWDownloadMgr:(EWDownloadMgr *)mgr didFailedDownload:(NSError *)error;

@end

@interface EWDownloadMgr : NSObject

@property (nonatomic, weak) id<EWDownloadMgrDelegate> delegate;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) NSString *description;

@property (nonatomic, strong) NSData *resultData;
@property (nonatomic, strong) NSString *resultString;

- (NSString *)sessionID;

// 异步下载
- (void)startDownload;

// 同步下载
- (NSData *)syncDownloadByGet;

@end
