//
//  AVManager.m
//  EarlyWorm
//
//  Created by Lei on 7/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "AVManager.h"
#import "EWMediaViewCell.h"
#import <AVFoundation/AVAudioPlayer.h>

@implementation AVManager
@synthesize player, recorder, progressBar, playStopBtn, currentTime;


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
        /*
        NSError *err = nil;
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:NULL error:&err];
        if (player)
        {
            [self updateViewForPlayerState:player];
            player.numberOfLoops = 0; //no repeat
            player.delegate = self;
        }*/
        
        //recorder
        NSString *tempDir = NSTemporaryDirectory ();
        NSString *soundFilePath =  [tempDir stringByAppendingString: @"recording.m4a"];
        recordingFileUrl = [[NSURL alloc] initFileURLWithPath: soundFilePath];
        
        //audio session
        [[AVAudioSession sharedInstance] setDelegate: self];
        NSError *error = nil;
        BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: &error];
        if (!success) NSLog(@"AVAudioSession error setting category:%@",error);
        success = [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                                                     error:&error];
        if (!success) NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
        [[AVAudioSession sharedInstance] setActive:YES error:nil];

    }
    return self;
}

- (void)setProgressBar:(UISlider *)slider{
    progressBar = slider;
    [progressBar addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
}


#pragma mark - PLAY FUNCTIONS
//play for cell with progress
-(void)playForCell:(EWMediaViewCell *)cell{
    NSData *audioData = cell.media.audio;//TODO network background task
    
    //link progress bar with cell's progress bar
    progressBar = cell.progressBar;
    currentTime = cell.time;
    playStopBtn = cell.playBtn;
    NSError *err;
    player = [[AVAudioPlayer alloc] initWithData:audioData error:&err];
    if (err) {
        NSLog(@"Cannot init player. Reason: %@", err.description);
    }
    self.player.delegate = self;
    [player prepareToPlay];
    if (![player play]) NSLog(@"Could not play media.");
    [self updateViewForPlayerState:player];
}



//play for file in main bundle
-(void)playSoundFromFile:(NSString *)fileName {
    
    NSArray *array = [fileName componentsSeparatedByString:@"."];
    
    NSString *file = nil;
    NSString *type = nil;
    if (array.count >= 2) {
        file = [array firstObject];
        type = [array lastObject];
    }
    else {
        file = fileName;
        type = @"";
    }
    NSURL *soundURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:file ofType:type]];
    //call the core play function
    [self playSoundFromURL:soundURL];
}

//main play function
- (void)playSoundFromURL:(NSURL *)url{
    NSLog(@"About to play %@", [url path]);
    if ([url isFileURL]) {
        
        if (!progressBar) {
            NSLog(@"Progress bar not set! Remember to add it before playing.");
        }
        
        //data
        NSError *err;
        NSData *audioData = [NSData dataWithContentsOfFile:[url path]];
        if (audioData) {
            self.player = [[AVAudioPlayer alloc] initWithData:audioData error:&err];
        }else{
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
        }
        
        if (err) {
            NSLog(@"Cannot init player. Reason: %@", err.description);
        }
        self.player.delegate = self;
        [player prepareToPlay];
        if (![player play]) NSLog(@"Could not play %@\n", url);
        [self updateViewForPlayerState:player];
    }else{
        //network url
        NSLog(@"Network URL streaming is not supported yet");
    }
}

//UI event from UISlider
- (IBAction)sliderChanged:(UISlider *)sender {
    // Fast skip the music when user scroll the UISlider
    [player stop];
    [player setCurrentTime:progressBar.value];
    currentTime.text = [NSString stringWithFormat:@"%d:%02d", (NSInteger)progressBar.value / 60, (NSInteger)progressBar.value % 60, nil];
    [player prepareToPlay];
    [player play];
    
}

#pragma mark - Record
- (NSURL *)record{
    if (recorder.isRecording) {
        
        [recorder stop];
        recorder = nil;
        
        [[AVAudioSession sharedInstance] setActive: NO error: nil];
        
        return recordingFileUrl;
        NSLog(@"Recording finished: %@", recordingFileUrl);
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
        
        recorder.delegate = self;
        NSTimeInterval maxTime = kMaxRecordTime;
        [recorder recordForDuration:maxTime];
        if (![recorder record]){
            int errorCode = CFSwapInt32HostToBig ([err code]);
            NSLog(@"Error: %@ [%4.4s])" , [err localizedDescription], (char*)&errorCode);
        }
        //update
        [self updateViewForRecorderState:recorder];
        NSLog(@"Recording...");
    }
    return nil;
}

#pragma mark - update UI
- (void)updateViewForPlayerState:(AVAudioPlayer *)p
{
    if (progressBar) {
        [self updateCurrentTime];
        progressBar.maximumValue = player.duration;
    }
    
	if (updateTimer)
		[updateTimer invalidate];
    
	if (p.playing)
	{
		//[lvlMeter_in setPlayer:p];
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTime) userInfo:p repeats:YES];
	}
	else
	{
		//[lvlMeter_in setPlayer:nil];
		updateTimer = nil;
	}
}

- (void)updateViewForRecorderState:(AVAudioRecorder *)r{
    if (progressBar) {
        [self updateCurrentTimeForRecorder];
        progressBar.maximumValue = kMaxRecordTime;
    }
    
	if (updateTimer)
		[updateTimer invalidate];
    
	if (r.recording)
	{
		//[lvlMeter_in setPlayer:p];
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTimeForRecorder) userInfo:r repeats:YES];
	}
	else
	{
		//[lvlMeter_in setPlayer:nil];
		updateTimer = nil;
	}
}

-(void)updateCurrentTime
{
    if (!progressBar.isTouchInside) {
        progressBar.value = player.currentTime;
        currentTime.text = [NSString stringWithFormat:@"%d:%02d", (NSInteger)player.currentTime / 60, (NSInteger)player.currentTime % 60, nil];
    }
}

-(void)updateCurrentTimeForRecorder
{
    if (!progressBar.isTouchInside) {
        progressBar.value = recorder.currentTime;
        currentTime.text = [NSString stringWithFormat:@"%d:%02d", (NSInteger)recorder.currentTime / 60, (NSInteger)recorder.currentTime % 60, nil];
    }
}


#pragma mark - AVAudioPlayer delegate method
- (void) audioPlayerDidFinishPlaying: (AVAudioPlayer *)player successfully:(BOOL)flag {
    [updateTimer invalidate];
    self.player.currentTime = 0.0;
    [self.playStopBtn setTitle:@"Play" forState:UIControlStateNormal];
    NSLog(@"Playback fnished");
    [[NSNotificationCenter defaultCenter] postNotificationName:kAudioPlayerDidFinishPlaying object:nil];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    [updateTimer invalidate];
    [self.playStopBtn setTitle:@"Record" forState:UIControlStateNormal];
    //NSLog(@"Recording reached max length");
    
}


#pragma mark - UI Events
- (void)stopAllPlaying{
    [player stop];
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)p{
    [p stop];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)p{
    [p play];
}

#pragma mark - AVPlayer (Advanced, for stream audio, future)
//use AVPlayer to play assets via HTTP live stream(advanced)
-(void)playMedia:(NSString *)fileName{
    NSURL *url = [NSURL URLWithString:@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"];
    AVPlayerItem *playerItem = [AVPlayerItem alloc];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    if (asset.tracks) {
        //try to load locally first
        playerItem = [playerItem initWithAsset:asset];
    }else{
        //network
        playerItem = [playerItem initWithURL:url];
    }
    //observe status
    [playerItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    //define player
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    
}


/*
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context{
    if ([keyPath isEqual:@"status"]) {
        //NSNumber *length = [[[[[self.player tracks] objectAtIndex:0] assetTrack] asset] duration];
        
        if (self.player.status == AVPlayerStatusReadyToPlay) {
            [self playerPlay];
            //tracking time
            Float64 durationSeconds = CMTimeGetSeconds([self.player.currentItem duration]);
            CMTime durationInterval = CMTimeMakeWithSeconds(durationSeconds/100, 1);
            
            [self.player addPeriodicTimeObserverForInterval:durationInterval queue:NULL usingBlock:^(CMTime time){
                
                NSString *timeDescription = (NSString *)
//                CFBridgingRelease(CMTimeCopyDescription(NULL, self.player.currentTime));
                CFBridgingRelease(CMTimeCopyDescription(NULL, time));
                NSLog(@"Passed a boundary at %@", timeDescription);
            }];
        }else if(self.player.status == AVPlayerStatusFailed){
            // deal with failure
            NSLog(@"Failed to load audio");
        }
    }
}


//start to play media when ready
-(void)playerPlay{
    [self.player play];
}
*/



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

- (void)pausePlaybackForPlayer:(AVAudioPlayer *)player {
    NSLog(@"未知情况");
}

@end
