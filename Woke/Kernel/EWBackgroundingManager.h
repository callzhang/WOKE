//
//  EWSleepManager.h
//  Woke
//
//  Created by Lee on 8/6/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

@import Foundation;
@import AVFoundation;
@import AudioToolbox;

#define kBackgroundingEnterNotice	@"enter_backgrounding"
#define kBackgroundingEndNotice		@"end_backgrounding"

@class EWTaskItem;

@interface EWBackgroundingManager : NSObject <AVAudioSessionDelegate>
@property (nonatomic) BOOL sleeping;
@property (nonatomic) EWTaskItem *task;

+ (EWBackgroundingManager *)sharedInstance;
+ (BOOL)supportBackground;
- (void)startBackgrounding;
- (void)endBackgrounding;
- (void)beginInterruption;
- (void)endInterruption;
- (void)backgroundKeepAlive:(NSTimer *)timer;

/**
 *register for backgrounding AudioSession
 @discussion This session starts with option of mix & speaker
 */
- (void)registerBackgroudingAudioSession;
- (void)playSilentSound;
@end
