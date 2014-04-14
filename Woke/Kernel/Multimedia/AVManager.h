//
//  AVManager.h
//  EarlyWorm
//
//  Created by Lei on 7/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//
/**  AVManager: Controls the overall audio/video play
//
//  - playForCell: highest level of control, controlled by WakeUpManager
//          |
//  - playMedia: Intermediate level of play, controlled by avmanager self
//          |
//  - playSoundFromURL: Lower level control, may called from outside
//
*/

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "EWDefines.h"

@class EWMediaViewCell, EWTaskItem, EWMediaItem, EWMediaSlider;

@interface AVManager : UIResponder <AVAudioPlayerDelegate, AVAudioRecorderDelegate, AVAudioSessionDelegate>
{
    //CALevelMeter *lvlMeter_in;
    NSTimer *updateTimer;
    NSURL *recordingFileUrl;
    AVPlayer *avplayer;
    SystemSoundID soundID;
}

@property (retain, nonatomic) AVAudioPlayer *player;
@property (retain, nonatomic) AVAudioRecorder *recorder;
@property (weak, nonatomic) EWMediaViewCell *currentCell; //current cell, assigned by others
@property (weak, nonatomic) EWMediaItem *media;
@property (weak, nonatomic) UIButton *recordStopBtn;
@property (weak, nonatomic) UIButton *playStopBtn;
@property (weak, nonatomic) EWMediaSlider *progressBar;
@property (weak, nonatomic) UILabel *currentTime;
//@property (nonatomic) BOOL loop;

+(AVManager *)sharedManager;

//play
- (void)playForCell:(UITableViewCell *)cell;
- (void)playMedia:(EWMediaItem *)media;

/**
 Main play function. Support FTW cache method.
 */
- (void)playSoundFromURL:(NSURL *)url;
- (void)playSoundFromFile:(NSString *)fileName;

//update states
- (void)updateViewForPlayerState:(AVAudioPlayer *)player;

/**
 (Depreciated)
 Use WakeUpManager to control the playing
 */
//- (void)playTask:(EWTaskItem *)task;


- (NSURL *)record;

// - (void)stopPlaying:(NSString *)fileName;
- (void)stopAllPlaying;

/**
 *register for AudioSession
 */
- (void)registerAudioSession;

/**
 Play audio using AVPlayer
 */
- (void)playAvplayerWithURL:(NSURL *)url;
- (void)playSilentSound;
- (void)stopAvplayer;

/**
 Play sound with system sound service
 */
- (void)playSystemSound:(NSURL *)path;



/**
 Display the playing info to lock screen
 */
- (void)displayNowPlayingInfoToLockScreen:(EWMediaItem *)media;

///**
// *Register self as the first responder for remote control event
// */
//- (void)prepareRemoteControlEventsListener;
///**
// *Resign self as the first responder for remote control event
// */
//- (void)resignRemoteControlEventsListener;

@end
