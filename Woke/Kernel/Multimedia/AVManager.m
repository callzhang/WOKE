//
//  AVManager.m
//  EarlyWorm
//
//  Created by Lei on 7/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "AVManager.h"
#import "EWMediaViewCell.h"
#import "EWTaskItem.h"
#import "EWMedia.h"
#import "EWMediaFile.h"
#import "EWDataStore.h"
#import "EWMediaSlider.h"
#import "EWMediaStore.h"
#import "EWBackgroundingManager.h"
#import "EWAlarmManager.h"
#import "EWAlarm.h"

@import MediaPlayer;

@interface AVManager(){
    id AVPlayerUpdateTimer;
    CADisplayLink *displaylink;
	MPVolumeView *volumeView;
}

@end

@implementation AVManager
@synthesize player, recorder;
@synthesize playStopBtn, recordStopBtn, currentCell, progressBar, currentTime, media;


+(AVManager *)sharedManager{
    static AVManager *sharedManager_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager_ = [[AVManager alloc] init];
    });
    return sharedManager_;
}

-(id)init{
    //static AVManager *sharedManager_ = nil;
    self = [super init];
    if (self) {
        //regist the player
        
        //recorder path
        NSString *tempDir = NSTemporaryDirectory ();
        NSString *soundFilePath =  [tempDir stringByAppendingString: @"recording.m4a"];
        recordingFileUrl = [[NSURL alloc] initFileURLWithPath: soundFilePath];
        
        //Volume view
		volumeView = [[MPVolumeView alloc] init];
    }
    return self;
}

#pragma mark - Audio Sessions
//register the ACTIVE playing session
- (void)registerActiveAudioSession{
	[self setDeviceVolume:1.0];
	[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    //audio session
    [[AVAudioSession sharedInstance] setDelegate: self];
    NSError *error = nil;
    
    //set category
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback
													withOptions: AVAudioSessionCategoryOptionAllowBluetooth
														  error: &error];
    if (!success) DDLogVerbose(@"AVAudioSession error setting category:%@",error);
    
    //set active
    success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success){
        DDLogInfo(@"Unable to activate ACTIVE audio session:%@", error);
    }else{
        DDLogInfo(@"ACTIVE Audio session activated!");
    }
}

- (void)registerRecordingAudioSession{
    [self stopAllPlaying];
    [[AVAudioSession sharedInstance] setDelegate: self];
    NSError *error = nil;
    
    //set category
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord
                                                    withOptions: AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth
                                                          error: &error];
    if (!success) DDLogVerbose(@"AVAudioSession error setting category:%@",error);
    
    //set active
    success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success || error){
        DDLogVerbose(@"Unable to activate ACTIVE audio session:%@", error);
    }else{
        DDLogVerbose(@"RECODING Audio session activated!");
    }
}

#pragma mark - PLAY FUNCTIONS
//play for cell with progress
-(void)playForCell:(UITableViewCell *)cell{
    //Active session
    //[self registerActiveAudioSession];
    
    //determine cell type
    if (![cell isKindOfClass:[EWMediaViewCell class]]) return;
    EWMediaViewCell *mediaCell = (EWMediaViewCell *)cell;
    
    //link progress bar with cell's progress bar
    self.currentCell = mediaCell;

    
    //play
    //[self playSoundFromURL:[NSURL URLWithString:mediaCell.media.audioKey]];
    [self playMedia:mediaCell.media];

    
}

- (void)setCurrentCell:(EWMediaViewCell *)cell{
    
    //assign new value
    progressBar = cell.mediaBar;
    //media = cell.media;
    currentCell = cell;
}


- (void)playMedia:(EWMedia *)mi{
    NSParameterAssert([NSThread isMainThread]);
	//set to max volume
	[self setDeviceVolume:1.0];
    if (!mi){
        [self playSoundFromFileName:kSilentSound];
    }else if (media == mi){
        DDLogInfo(@"Same media passed in, skip.");
		if (!self.player.isPlaying) {
			[self.player play];
		}
		[self updateViewForPlayerState:player];
        return;
    }
    else{
        //new media
        media = mi;
		
		//lock screen
		[self displayNowPlayingInfoToLockScreen:mi];
		
        if ([media.type isEqualToString:kMediaTypeVoice] || !media.type) {
            
            [self playSoundFromData:mi.mediaFile.audio];
			
        }else{
            DDLogVerbose(@"Unknown type of media, skip");
            [self playSoundFromFileName:kSilentSound];
        }
    }
}

//play for file in main bundle
-(void)playSoundFromFileName:(NSString *)fileName {
    
    NSArray *array = [fileName componentsSeparatedByString:@"."];
    
    NSString *file = nil;
    NSString *type = nil;
    if (array.count == 1) {
        file = fileName;
        type = @"";
    }else if (array.count == 2) {
        file = [array firstObject];
        type = [array lastObject];
    }else {
        DDLogVerbose(@"Wrong file name(%@) passed to play sound", fileName);
        return;
    }
    NSString *str = [[NSBundle mainBundle] pathForResource:file ofType:type];
    if (!str) {
        DDLogVerbose(@"File doesn't exsits in main bundle");
        return;
    }
    NSURL *soundURL = [[NSURL alloc] initFileURLWithPath:str];
    //call the core play function
    [self playSoundFromURL:soundURL];
}

//Depreciated: play from url
- (void)playSoundFromURL:(NSURL *)url{
	if (!url) {
		DDLogVerbose(@"Url is empty, skip playing");
		//[self audioPlayerDidFinishPlaying:player successfully:YES];
		return;
	}
	
	//data
	NSError *err;
	player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
	player.volume = 1.0;
	
	if (err) {
		DDLogVerbose(@"*** Cannot init player. Reason: %@", err);
		[self playSystemSound:url];
		return;
	}
	self.player.delegate = self;
	if ([player play]){
		[self updateViewForPlayerState:player];
	}else{
		DDLogVerbose(@"*** Could not play with AVPlayer, using system sound");
		[self playSystemSound:url];
	}
}

- (void)playSoundFromData:(NSData *)data{
	if (!data || data.length == 0) {
		DDLogError(@"Playing from empty data");
		return;
	}
	NSError *err;
	player = [[AVAudioPlayer alloc] initWithData:data error:&err];
	player.volume = 1.0;
	
	if (err) {
		DDLogVerbose(@"*** Cannot init AVAudioPlayer. Reason: %@", err);
		NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"audioTempFile"];
		[data writeToFile:path atomically:YES];
		[self playSystemSound:[NSURL URLWithString:path]];
		return;
	}
	self.player.delegate = self;
	if ([player play]){
		[self updateViewForPlayerState:player];
	}else{
		DDLogVerbose(@"*** Could not play with AVAudioPlayer, using system sound");
		NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"audioTempFile"];
		[data writeToFile:path atomically:YES];
		[self playSystemSound:[NSURL URLWithString:path]];
	}
	
}

- (void)stopAllPlaying{
	[player stop];
	//[qPlayer pause];
	[avplayer pause];
	[updateTimer invalidate];
	//remove target action
	
}

#pragma mark - UI event
- (IBAction)sliderChanged:(UISlider *)sender {
    if (![sender isEqual:progressBar]) {
        DDLogVerbose(@"Sender is not current slider in AVManager, skip");
        return;
    }
    // Fast skip the music when user scroll the UISlider
    [player stop];
    [player setCurrentTime:progressBar.value];
    NSString *timeStr = [NSString stringWithFormat:@"%02ld", (long)progressBar.value % 60];
    currentTime.text = timeStr;
    [player prepareToPlay];
    [player play];
    
}

#pragma mark - Record
- (NSURL *)record{
    if (recorder.isRecording) {
        
        [recorder stop];
        [updateTimer invalidate];
        recorder = nil;
        
        [[AVAudioSession sharedInstance] setActive: NO error: nil];
        
        DDLogVerbose(@"Recording stopped");
    } else {
        NSDictionary *recordSettings = @{AVEncoderAudioQualityKey: @(AVAudioQualityLow),
                                         //AVEncoderAudioQualityKey: [NSNumber numberWithInt:kAudioFormatLinearPCM],
                                         //AVEncoderBitRateKey: @64,
                                         AVSampleRateKey: @24000.0,
                                         AVNumberOfChannelsKey: @1,
                                         AVFormatIDKey: @(kAudioFormatMPEG4AAC)}; //,
                                         //AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Variable};
        NSError *err;
        AVAudioRecorder *newRecorder = [[AVAudioRecorder alloc] initWithURL: recordingFileUrl
                                                                   settings: recordSettings
                                                                      error: &err];
        self.recorder = newRecorder;
        recorder.meteringEnabled = YES;
        recorder.delegate = self;
        NSTimeInterval maxTime = kMaxRecordTime;
        [recorder recordForDuration:maxTime];
        if (![recorder prepareToRecord]) {
            DDLogVerbose(@"Unable to start record");
        };
        if (![recorder record]){
            DDLogVerbose(@"Error: %@ [%ld])" , [err localizedDescription], (long)err.code);
            DDLogVerbose(@"Unable to record");
            return nil;
        }
        //setup the UI
        [self updateViewForRecorderState:recorder];
        
    }
    return recordingFileUrl;
}

#pragma mark - update UI
- (void)updateViewForPlayerState:(AVAudioPlayer *)p
{
    //init the progress bar
    if (progressBar) {
        //[self updateCurrentTime];
        progressBar.maximumValue = player.duration;
    }
    //timer stop first
    [updateTimer invalidate];
    //set up timer
    if (p.playing){
		player.volume = 1.0;
		//[lvlMeter_in setPlayer:p];
        //add new target
        //[progressBar addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:.05 target:self selector:@selector(updateCurrentTime:) userInfo:p repeats:YES];
        
        //unhide
        [UIView animateWithDuration:0.5 animations:^{
            self.progressBar.alpha = 1;
        }];
        [UIView animateWithDuration:0.5 animations:^{
            self.waveformView.alpha = 0;
        }];
        
	}
	else{
		//[lvlMeter_in setPlayer:nil];
		[updateTimer invalidate];
	}
}

- (void)updateViewForRecorderState:(AVAudioRecorder *)r{
    if (progressBar) {
        //[self updateCurrentTimeForRecorder];
        progressBar.maximumValue = kMaxRecordTime;
    }
    
	if (updateTimer)
		[updateTimer invalidate];
    
	if (r.recording)
	{
//        if (progressBar) {
//            DDLogVerbose(@"Updating progress bar");
//            updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTimeForRecorder:) userInfo:r repeats:YES];
//        }
		
        
        if (self.waveformView) {
            DDLogVerbose(@"Updating meter waveform");
            displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
            [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            
            [UIView animateWithDuration:0.5 animations:^{
                self.waveformView.alpha = 1;
            }];
            
            [UIView animateWithDuration:0.5 animations:^{
                self.progressBar.alpha = 0;
            }];
            
        }
	}
	else
	{
		[updateTimer invalidate];
        
	}
}

-(void)updateCurrentTime:(NSTimer *)timer{
    AVAudioPlayer *p = (AVAudioPlayer *)timer.userInfo;
    if (!progressBar.isTouchInside) {
        if(![p isEqual:player]) DDLogVerbose(@"***Player passed in is not correct");
        progressBar.value = player.currentTime;
        //currentTime.text = [NSString stringWithFormat:@"%02ld\"", (long)player.currentTime % 60, nil];
    }
}

-(void)updateCurrentTimeForRecorder:(NSTimer *)timer{
    AVAudioRecorder *r = (AVAudioRecorder *)timer.userInfo;
    if(![r isEqual:recorder]) DDLogVerbose(@"***Recorder passed in is not correct");
    if (!progressBar.isTouchInside) {
        progressBar.value = recorder.currentTime;
        currentTime.text = [NSString stringWithFormat:@"%02ld\"", (long)recorder.currentTime % 60, nil];
    }
}

- (void)updateMeters{
	[self.recorder updateMeters];
    CGFloat normalizedValue = pow (10, [self.recorder averagePowerForChannel:0]/30);
    [self.waveformView updateWithLevel:normalizedValue];
}


#pragma mark - AVAudioPlayer delegate method
- (void) audioPlayerDidFinishPlaying: (AVAudioPlayer *)p successfully:(BOOL)flag {
    DDLogVerbose(@"Player finished (%@)", flag?@"Success":@"Failed");
    [updateTimer invalidate];
    self.player.currentTime = 0.0;
    progressBar.value = 0.0;
    if (self.media) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAudioPlayerDidFinishPlaying object:self.media];
    }
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    [updateTimer invalidate];
    [displaylink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    displaylink = nil;
    [UIView animateWithDuration:0.5 animations:^{
        self.waveformView.alpha = 0;
    }];
    [recordStopBtn setTitle:@"Record" forState:UIControlStateNormal];
    DDLogVerbose(@"Recording reached max length");
}



- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)p{
	[p stop];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)p{
	[p play];
}

#pragma mark - AudioSeesion Delegate events
- (void)beginInterruption{
	//
}

- (void)endInterruptionWithFlags:(NSUInteger)flags{
    if (flags) {
        if (AVAudioSessionInterruptionOptionShouldResume) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				if (self.media) {
					[self.player play];
				}
            });
        }
    }
}

#pragma mark - AVPlayer (Depreciated)
- (void)playAvplayerWithURL:(NSURL *)url{
    if (AVPlayerUpdateTimer) {
        [avplayer removeTimeObserver:AVPlayerUpdateTimer];
        [AVPlayerUpdateTimer invalidate];
    }
    
    //AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    
}


- (void)stopAvplayer{
    [avplayer pause];
    @try {
        [avplayer removeTimeObserver:AVPlayerUpdateTimer];
        [AVPlayerUpdateTimer invalidate];
    }
    @catch (NSException *exception) {
        DDLogVerbose(@"AVplayer cannot remove update timer: %@", exception.description);
        
    }
    
    avplayer = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context{
    AVPlayer *p = (AVPlayer *)object;
    if(![p isEqual:avplayer]) DDLogVerbose(@"@@@ Inconsistant player");
    
    if ([object isKindOfClass:[avplayer class]] && [keyPath isEqual:@"status"]) {
        //observed status change for avplayer
        if (avplayer.status == AVPlayerStatusReadyToPlay) {
            //[avplayer play];
            //tracking time
//            Float64 durationSeconds = CMTimeGetSeconds([avplayer.currentItem duration]);
//            CMTime durationInterval = CMTimeMakeWithSeconds(durationSeconds/100, 1);
//            
//            [avplayer addPeriodicTimeObserverForInterval:durationInterval queue:NULL usingBlock:^(CMTime time){
//                
//                NSString *timeDescription = (NSString *)
//                //CFBridgingRelease(CMTimeCopyDescription(NULL, avplayer.currentTime));
//                CFBridgingRelease(CMTimeCopyDescription(NULL, time));
//                DDLogVerbose(@"Passed a boundary at %@", timeDescription);
//            }];
            
            CMTime interval = CMTimeMake(30, 1);//30s
            AVPlayerUpdateTimer = [avplayer addPeriodicTimeObserverForInterval:interval queue:NULL usingBlock:^(CMTime time){
                CMTime endTime = CMTimeConvertScale (p.currentItem.asset.duration, p.currentTime.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
                if (CMTimeCompare(endTime, kCMTimeZero) != 0) {
                    double normalizedTime = (double) p.currentTime.value / (double) endTime.value;
                    DDLogVerbose(@"AVPlayer is still playing %f", normalizedTime);
                }
            }];
        }else if(avplayer.status == AVPlayerStatusFailed){
            // deal with failure
            DDLogVerbose(@"Failed to load audio");
        }
    }
}



#pragma mark AudioSession handlers
/*
void RouteChangeListener(	void *inClientData,
                         AudioSessionPropertyID	inID,
                         UInt32 inDataSize,
                         const void *inData)
{
	AVManager* This = (__bridge AVManager *)inClientData;  //???
	
	if (inID == kAudioSessionProperty_AudioRouteChange) {
		
		CFDictionaryRef routeDict = (CFDictionaryRef)inData;
		NSNumber* reasonValue = (NSNumber*)CFDictionaryGetValue(routeDict, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
		
		NSInteger reason = [reasonValue intValue];
        
		if (reason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            DDLogVerbose(@"kAudioSessionRouteChangeReason_OldDeviceUnavailable");
			[This pausePlaybackForPlayer:This.player];
		}
	}
}*/


#pragma  mark - System Sound Service
- (void)playSystemSound:(NSURL *)path{
    //release old id first
    AudioServicesRemoveSystemSoundCompletion(soundID);
    AudioServicesDisposeSystemSoundID(soundID);
    
    //SystemSound
    NSURL *soundUrl;
    if (!path) {
        soundUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tock" ofType:@"caf"]];
    }else{
        if ([path isFileURL] || ![path.absoluteString hasPrefix:@"http"]) {
            //local file
            soundUrl = path;
        }else{
            DDLogVerbose(@"Passed remote url to system audio service");
            soundUrl = path;
        }
    }
    
    //play
    DDLogVerbose(@"Start playing system sound");
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundUrl, &soundID);
    //AudioServicesPlayAlertSound(soundID);
    AudioServicesPlaySystemSound(soundID);
    
    //long background server
    UIBackgroundTaskIdentifier bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        DDLogVerbose(@"Playing timer for system audio service is ending");
    }];
    
    //completion callback
    AudioServicesAddSystemSoundCompletion(soundID, nil, nil, systemSoundFinished, (void *)bgTaskId);
}

void systemSoundFinished (SystemSoundID sound, void *bgTaskId){
    DDLogVerbose(@"System audio playback fnished");
    
    if ([AVManager sharedManager].media) {
        //[[NSNotificationCenter defaultCenter] postNotificationName:kAudioPlayerDidFinishPlaying object:nil];
        //DDLogVerbose(@"broadcasting finish event");
    }    
    [[UIApplication sharedApplication] endBackgroundTask:(NSInteger)bgTaskId];
}


#pragma mark - Remote control
- (void)displayNowPlayingInfoToLockScreen:(EWMedia *)m{
    if (!m.author) return;
        
    //only support iOS5+
    if (NSClassFromString(@"MPNowPlayingInfoCenter")){
        
        if (!m) m = media;
        EWAlarm *nextAlarm = [EWAlarmManager myNextAlarm];
        
        NSString *title = nextAlarm.time.weekday;
        
        //info
        NSMutableDictionary *dict = [NSMutableDictionary new];
        dict[MPMediaItemPropertyTitle] = @"Time to wake up";
        dict[MPMediaItemPropertyArtist] = m.author.name?m.author.name:@"";
        dict[MPMediaItemPropertyAlbumTitle] = title?:@"";
        
        //cover
        UIImage *cover = media.mediaFile.image ?: media.author.profilePic;
        if (cover) {
            MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:cover];
            dict[MPMediaItemPropertyArtwork] = artwork;
        }
        
        //TODO: media message can be rendered on image
        
        //set
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = dict;
        
        DDLogInfo(@"Set lock screen informantion");
    }
}



#pragma mark - Volume control
- (void)volumeFadeWithCompletion:(void (^)(void))block{
    if (self.player.volume > 0) {
        self.player.volume = self.player.volume - 0.1;
        [self performSelector:@selector(volumeFadeWithCompletion:) withObject:block afterDelay:0.2];
    } else {
        // Stop and get the sound ready for playing again
        [self.player stop];
        self.player.currentTime = 0;
        //[self.player prepareToPlay];
        self.player.volume = 1.0;
        if (block) {
            block();
        }
    }
}

- (void)setDeviceVolume:(float)volume{
	UISlider* volumeViewSlider = nil;
	for (UIView *view in [volumeView subviews]){
		if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
			volumeViewSlider = (UISlider*)view;
			break;
		}
	}
	
	[NSTimer bk_scheduledTimerWithTimeInterval:0.2 block:^(NSTimer *aTimer){
		float currentVolume = volumeViewSlider.value;
		float delta = volume - currentVolume;
		if (delta > 0.1) {
			delta = 0.1;
		}else if(delta < -0.1){
			delta = -0.1;
		}
		[volumeViewSlider setValue:currentVolume + delta animated:YES];
		[volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
		
		if (currentVolume == volume || !volumeViewSlider) {
			[aTimer invalidate];
			DDLogVerbose(@"Volume set to %f", volume);
			return;
		}
	} repeats:YES];
	
	
}
@end
