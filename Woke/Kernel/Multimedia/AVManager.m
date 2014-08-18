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
#import "EWMediaItem.h"
#import "EWTaskStore.h"
#import <AVFoundation/AVAudioPlayer.h>
#import "EWDataStore.h"
#import "EWMediaSlider.h"
//#import "EWDownloadManager.h"
#import "EWMediaStore.h"
#import "EWBackgroundingManager.h"

@import MediaPlayer;

@interface AVManager(){
    id AVPlayerUpdateTimer;
    CADisplayLink *displaylink;
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
        
        //observe the background event
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        //recorder path
        NSString *tempDir = NSTemporaryDirectory ();
        NSString *soundFilePath =  [tempDir stringByAppendingString: @"recording.m4a"];
        recordingFileUrl = [[NSURL alloc] initFileURLWithPath: soundFilePath];
        
        //Audio session
        //[self registerAudioSession];
        
    }
    return self;
}

#pragma mark - Audio Sessions
//register the normal audio session
- (void)registerAudioSession{
    //deactivated first
    [[AVAudioSession sharedInstance] setActive:NO error:NULL];
    
    //audio session
    [[AVAudioSession sharedInstance] setDelegate: self];
    NSError *error = nil;
    //set category
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback
                                                    withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                                          error:&error];
    if (!success) NSLog(@"AVAudioSession error setting category:%@",error);
    //force speaker
//    success = [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
//                                                                 error:&error];
//    if (!success || error) NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    //set active
    success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success || error){
        NSLog(@"Unable to activate BACKGROUNDING audio session:%@", error);
    }else{
        NSLog(@"BACKGROUNDING Audio session activated!");
    }
    //set active bg sound
    [self playSilentSound];
}

//register the playing session
- (void)registerActiveAudioSession{
    //deactivated first
    [[AVAudioSession sharedInstance] setActive:NO error:NULL];
    [self stopAvplayer];
    
    //audio session
    [[AVAudioSession sharedInstance] setDelegate: self];
    NSError *error = nil;
    
    //set category
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback
                                                    withOptions: AVAudioSessionCategoryOptionDuckOthers
                                                          error: &error];
    if (!success) NSLog(@"AVAudioSession error setting category:%@",error);
    
    //set active
    success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success || error){
        NSLog(@"Unable to activate ACTIVE audio session:%@", error);
    }else{
        NSLog(@"ACTIVE Audio session activated!");
    }
}

- (void)registerRecordingAudioSession{
    //deactivated first
    [[AVAudioSession sharedInstance] setActive:NO error:NULL];
    [self stopAvplayer];
    
    [[AVAudioSession sharedInstance] setDelegate: self];
    NSError *error = nil;
    
    //set category
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord
                                                    withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                                          error:&error];
    if (!success) NSLog(@"AVAudioSession error setting category:%@",error);
    
    //set active
    success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success || error){
        NSLog(@"Unable to activate ACTIVE audio session:%@", error);
    }else{
        NSLog(@"RECODING Audio session activated!");
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
//    currentTime = progressBar.timeLabel;
    media = cell.media;
    currentCell = cell;
}


- (void)playMedia:(EWMediaItem *)mi{
    NSParameterAssert([NSThread isMainThread]);
    media = (EWMediaItem *)[[EWDataStore mainContext] objectWithID:mi.objectID];
    if ([media.type isEqualToString:kMediaTypeVoice] || !media.type) {
        
        [self playSoundFromURL:[NSURL URLWithString:mi.audioKey]];
        
        //lock screen
        [self displayNowPlayingInfoToLockScreen:mi];
    }else if([media.type isEqualToString:kMediaTypeBuzz]){
        if ([media.buzzKey isEqualToString: @"default"]) {
            [self playSoundFromFile:@"buzz.caf"];
        }else{
            //TODO
            [self playSoundFromFile:@"buzz.caf"];
        }
        
    }else{
        NSLog(@"Unknown type of media, skip");
        [self playSoundFromFile:@"Silence04s.caf"];
        
    }
    
}

//Depreciated: play from url
- (void)playSoundFromURL:(NSURL *)url{
    if (!url) {
        NSLog(@"Url is empty, skip playing");
        //[self audioPlayerDidFinishPlaying:player successfully:YES];
        return;
    }
    
    //data
    NSError *err;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    player.volume = 1.0;
    
    if (err) {
        NSLog(@"Cannot init player. Reason: %@", err);
        [self playSystemSound:url];
        return;
    }
    self.player.delegate = self;
    if ([player play]){
        [self updateViewForPlayerState:player];
    }else{
        NSLog(@"Could not play with AVPlayer, using system sound");
        [self playSystemSound:url];
    }
}



//play for file in main bundle
-(void)playSoundFromFile:(NSString *)fileName {
    
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
        NSLog(@"Wrong file name(%@) passed to play sound", fileName);
        return;
    }
    NSString *str = [[NSBundle mainBundle] pathForResource:file ofType:type];
    if (!str) {
        NSLog(@"File doesn't exsits in main bundle");
        return;
    }
    NSURL *soundURL = [[NSURL alloc] initFileURLWithPath:str];
    //call the core play function
    [self playSoundFromURL:soundURL];
}



#pragma mark - UI event
- (IBAction)sliderChanged:(UISlider *)sender {
    if (![sender isEqual:progressBar]) {
        NSLog(@"Sender is not current slider in AVManager, skip");
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
        
        NSLog(@"Recording stopped");
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
            NSLog(@"Unable to start record");
        };
        if (![recorder record]){
            NSLog(@"Error: %@ [%ld])" , [err localizedDescription], (long)err.code);
            NSLog(@"Unable to record");
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
		//[lvlMeter_in setPlayer:p];
        //add new target
        //[progressBar addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTime:) userInfo:p repeats:YES];
        
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
//            NSLog(@"Updating progress bar");
//            updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTimeForRecorder:) userInfo:r repeats:YES];
//        }
		
        
        if (self.waveformView) {
            NSLog(@"Updating meter waveform");
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
		updateTimer = nil;
        
	}
}

-(void)updateCurrentTime:(NSTimer *)timer{
    AVAudioPlayer *p = (AVAudioPlayer *)timer.userInfo;
    if(![p isEqual:player]) NSLog(@"***Player passed in is not correct");
    if (!progressBar.isTouchInside) {
        player.volume = 1.0;
        progressBar.value = player.currentTime;
        //currentTime.text = [NSString stringWithFormat:@"%02ld\"", (long)player.currentTime % 60, nil];
    }
}

-(void)updateCurrentTimeForRecorder:(NSTimer *)timer{
    AVAudioRecorder *r = (AVAudioRecorder *)timer.userInfo;
    if(![r isEqual:recorder]) NSLog(@"***Recorder passed in is not correct");
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
    NSString *success = flag?@"Success":@"Failed";
    NSLog(@"Player finished (%@)", success);
    p.delegate = nil;
    p = nil;
    //[progressBar removeTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [updateTimer invalidate];
    self.player.currentTime = 0.0;
    progressBar.value = 0.0;
    //NSLog(@"Playback fnished");
    [[NSNotificationCenter defaultCenter] postNotificationName:kAudioPlayerDidFinishPlaying object:nil];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    [updateTimer invalidate];
    [displaylink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    displaylink = nil;
    [UIView animateWithDuration:0.5 animations:^{
        self.waveformView.alpha = 0;
    }];
    [recordStopBtn setTitle:@"Record" forState:UIControlStateNormal];
    NSLog(@"Recording reached max length");
}


#pragma mark - Delegate events
- (void)stopAllPlaying{
    [player stop];
    //[qPlayer pause];
    [avplayer pause];
    [updateTimer invalidate];
    //remove target action
    
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)p{
    [p stop];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)p{
    [p play];
}

- (void)endInterruptionWithFlags:(NSUInteger)flags{
    if (flags) {
        if (AVAudioSessionInterruptionOptionShouldResume) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                
                EWBackgroundingManager *manager = [EWBackgroundingManager sharedInstance];
                if (manager.sleeping == YES) {
                    UILocalNotification *n = [UILocalNotification new];
                    n.alertBody = @"Woke is active";
                    [[UIApplication sharedApplication] scheduleLocalNotification:n];
                }
                
                [manager backgroundKeepAlive:NULL];
                
#ifdef DEBUG
                [[AVManager sharedManager] playSoundFromFile:@"Sunny Afternoon.caf"];
#endif
            });
        }
    }
}

#pragma mark - AVPlayer (used to play sound and keep the audio capability open)
- (void)playAvplayerWithURL:(NSURL *)url{
    if (AVPlayerUpdateTimer) {
        [avplayer removeTimeObserver:AVPlayerUpdateTimer];
        [AVPlayerUpdateTimer invalidate];
    }
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    avplayer = [AVPlayer playerWithPlayerItem:item];
    [avplayer setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    avplayer.volume = 1.0;
    if (avplayer.status != AVPlayerStatusReadyToPlay) {
        NSLog(@"!!! AV player not ready to play.");
    }
    //[avplayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    [avplayer play];
}

- (void)playSilentSound{
#if TARGET_IPHONE_SIMULATOR
    
#else
    NSLog(@"Play silent sound");
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"bg" withExtension:@"caf"];
    [self playAvplayerWithURL:path];
#endif
}

- (void)stopAvplayer{
    [avplayer pause];
    @try {
        [avplayer removeTimeObserver:AVPlayerUpdateTimer];
        [AVPlayerUpdateTimer invalidate];
    }
    @catch (NSException *exception) {
        NSLog(@"AVplayer cannot remove update timer: %@", exception.description);
        
    }
    
    avplayer = nil;
}



- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context{
    AVPlayer *p = (AVPlayer *)object;
    if(![p isEqual:avplayer]) NSLog(@"@@@ Inconsistant player");
    
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
//                NSLog(@"Passed a boundary at %@", timeDescription);
//            }];
            
            CMTime interval = CMTimeMake(30, 1);//30s
            AVPlayerUpdateTimer = [avplayer addPeriodicTimeObserverForInterval:interval queue:NULL usingBlock:^(CMTime time){
                CMTime endTime = CMTimeConvertScale (p.currentItem.asset.duration, p.currentTime.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
                if (CMTimeCompare(endTime, kCMTimeZero) != 0) {
                    double normalizedTime = (double) p.currentTime.value / (double) endTime.value;
                    NSLog(@"AVPlayer is still playing %f", normalizedTime);
                }
            }];
        }else if(avplayer.status == AVPlayerStatusFailed){
            // deal with failure
            NSLog(@"Failed to load audio");
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
            NSLog(@"kAudioSessionRouteChangeReason_OldDeviceUnavailable");
			[This pausePlaybackForPlayer:This.player];
		}
	}
}*/


#pragma mark - Background events handler
- (void)didEnterBackground:(NSNotification *)notification{
    //NSLog(@"%s: Received background event notification", __func__);
    [self registerAudioSession];
}



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
            NSLog(@"Passed remote url to system audio service");
            soundUrl = path;
        }
    }
    
    //play
    NSLog(@"Start playing system sound");
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundUrl, &soundID);
    //AudioServicesPlayAlertSound(soundID);
    AudioServicesPlaySystemSound(soundID);
    
    //long background server
    UIBackgroundTaskIdentifier bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"Playing timer for system audio service is ending");
    }];
    
    //completion callback
    AudioServicesAddSystemSoundCompletion(soundID, nil, nil, systemSoundFinished, (void *)bgTaskId);
}

void systemSoundFinished (SystemSoundID sound, void *bgTaskId){
    NSLog(@"System audio playback fnished");
    
    if ([AVManager sharedManager].media) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAudioPlayerDidFinishPlaying object:nil];
        NSLog(@"broadcasting finish event");
    }    
    [[UIApplication sharedApplication] endBackgroundTask:(NSInteger)bgTaskId];
}


#pragma mark - Remote control
- (void)displayNowPlayingInfoToLockScreen:(EWMediaItem *)m{
    if (!m.author) return;
        
    //only support iOS5+
    if (NSClassFromString(@"MPNowPlayingInfoCenter")){
        
        if (!m) m = media;
        EWTaskItem *task = [[m.tasks filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"owner = %@", me]] anyObject];
        
        NSString *title = [task.time weekday];
        
        //info
        NSMutableDictionary *dict = [NSMutableDictionary new];
        dict[MPMediaItemPropertyTitle] = @"Time to wake up";
        dict[MPMediaItemPropertyArtist] = m.author.name?m.author.name:@"";
        dict[MPMediaItemPropertyAlbumTitle] = title?title:@"";
        
        //cover
        UIImage *cover = media.image ? media.image : media.author.profilePic;
        if (cover) {
            MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:cover];
            dict[MPMediaItemPropertyArtwork] = artwork;
        }
        
        //TODO: media message can be rendered on image
        
        //set
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dict];
        
        NSLog(@"Set lock screen informantion");
    }
}
@end
