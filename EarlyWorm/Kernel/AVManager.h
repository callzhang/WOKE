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

@interface AVManager : NSObject <UIPickerViewDelegate, AVAudioPlayerDelegate>
{
    //CALevelMeter *lvlMeter_in;
    NSTimer *updateTimer;
}

+(AVManager *)sharedManager;

//-(void)playSound:(NSString *)fileName;
-(void)playMedia:(NSString *)fileName;
-(void)playSoundFromFile:(NSString *)fileName;
-(void)playForCell:(EWMediaViewCell *)cell;
-(void)pausePlaybackForPlayer:(AVAudioPlayer *)player;
-(void)updateViewForPlayerState:(AVAudioPlayer *)player;

// TODO: 需要停止播放的接口
// - (void)stopPlaying:(NSString *)fileName;
- (void)stopAllPlaying;

@property (retain, nonatomic) AVAudioPlayer *player;
@property (weak, nonatomic) UISlider *progressBar;
//@property (strong) id playerObserver;
@end
