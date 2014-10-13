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

@interface EWBackgroundingManager : NSObject <AVAudioSessionDelegate>
@property (nonatomic) BOOL sleeping;

+ (EWBackgroundingManager *)sharedInstance;
- (void)startBackgrounding;
- (void)endBackgrounding;
/**
 *register for backgrounding AudioSession
 @discussion This session starts with option of mix & speaker
 */
- (void)registerBackgroudingAudioSession;
@end
