//
//  AVManager.h
//  EarlyWorm
//
//  Created by Lei on 7/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "EWDefines.h"

@class EWMediaViewCell;

@interface AVManager : NSObject <AVAudioPlayerDelegate, AVAudioRecorderDelegate, AVAudioSessionDelegate>
{
    //CALevelMeter *lvlMeter_in;
    NSTimer *updateTimer;
    NSURL *recordingFileUrl;
}

+(AVManager *)sharedManager;

//-(void)playSound:(NSString *)fileName;
/**
 Use AVPlayer to play assets via HTTP live stream(advanced)
 */
- (void)playMedia:(NSString *)fileName;
- (void)playSoundFromFile:(NSString *)fileName;
- (void)playSoundFromURL:(NSURL *)url;
- (void)playForCell:(EWMediaViewCell *)cell;
- (void)pausePlaybackForPlayer:(AVAudioPlayer *)player;
- (void)updateViewForPlayerState:(AVAudioPlayer *)player;
- (NSURL *)record;


// - (void)stopPlaying:(NSString *)fileName;
- (void)stopAllPlaying;

@property (retain, nonatomic) AVAudioPlayer *player;
@property (retain, nonatomic) AVAudioRecorder *recorder;
@property (weak, nonatomic) UISlider *progressBar;
@property (weak, nonatomic) UIButton *playStopBtn;
@property (weak, nonatomic) UIButton *recordStopBtn;
@property (weak, nonatomic) UILabel *currentTime;

//@property (strong) id playerObserver;
@end
