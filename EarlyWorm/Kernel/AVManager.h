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

@class EWMediaViewCell, EWTaskItem, EWMediaItem;

@interface AVManager : NSObject <AVAudioPlayerDelegate, AVAudioRecorderDelegate, AVAudioSessionDelegate>
{
    //CALevelMeter *lvlMeter_in;
    NSTimer *updateTimer;
    NSURL *recordingFileUrl;
    
}

+(AVManager *)sharedManager;

//-(void)playSound:(NSString *)fileName;
/**
 Use AVPlayer to play assets
 */
- (void)playLivePath:(NSString *)fileName;
/**
 Play sound from main bundle
 @param fileName: the file name without path
 */
- (void)playSoundFromFile:(NSString *)fileName;
/**
 Main play function. Support FTW cache method.
 */
- (void)playSoundFromURL:(NSURL *)url;
- (void)playForCell:(EWMediaViewCell *)cell;
- (void)playMedia:(EWMediaItem *)media;
- (void)pausePlaybackForPlayer:(AVAudioPlayer *)player;
- (void)updateViewForPlayerState:(AVAudioPlayer *)player;
- (void)playTask:(EWTaskItem *)task;
- (NSURL *)record;


// - (void)stopPlaying:(NSString *)fileName;
- (void)stopAllPlaying;

@property (retain, nonatomic) AVAudioPlayer *player;
@property (retain, nonatomic) AVAudioRecorder *recorder;
@property (weak, nonatomic) UITableView *wakeUpTableView; //holds all the cells
@property (weak, nonatomic) EWMediaViewCell *currentCell; //current cell
@property (retain, nonatomic) UISlider *progressBar;
@property (retain, nonatomic) UIButton *playStopBtn;
@property (retain, nonatomic) UIButton *recordStopBtn;
@property (retain, nonatomic) UILabel *currentTime;
@end
