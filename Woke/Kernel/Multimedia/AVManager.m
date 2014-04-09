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
#import "TestFlight.h"
#import "EWMediaSlider.h"
#import "EWDownloadManager.h"

@import MediaPlayer;

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
        
        //Register for remote control event
        //[self prepareRemoteControlEventsListener];
        
        //playlist
        //playlist = [[NSMutableArray alloc] init];
        
        //Loop
        //self.loop = YES;
        
    }
    return self;
}

- (void)registerAudioSession{
    
    //audio session
    [[AVAudioSession sharedInstance] setDelegate: self];
    NSError *error = nil;
    //set category
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &error];
    if (!success) NSLog(@"AVAudioSession error setting category:%@",error);
    //force speaker
    success = [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                                                 error:&error];
    if (!success || error) NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    //set active
    success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success || error){
        NSLog(@"Unable to activate audio session:%@", error);
    }else{
        NSLog(@"Audio session activated!");
    }
    
}


#pragma mark - PLAY FUNCTIONS
//play for cell with progress
-(void)playForCell:(UITableViewCell *)cell{
    
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
    progressBar = cell.mediaBar;
    currentTime = progressBar.timeLabel;
    media = cell.media;
    
    
    [progressBar addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
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
        NSLog(@"Wrong file name passed in");
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

//main play function
- (void)playSoundFromURL:(NSURL *)url{
    if (!url) {
        NSLog(@"Url is empty, skip playing");
        //[self audioPlayerDidFinishPlaying:player successfully:YES];
        return;
    }
    
    //data
    NSError *err;
    NSData *audioData = [[EWDataStore alloc] getRemoteDataWithKey:url.absoluteString];
    //play
    if (audioData) {
        player = [[AVAudioPlayer alloc] initWithData:audioData error:&err];
    }else{
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    }
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

- (void)playMedia:(EWMediaItem *)mi{
    media = mi;
    [self playSoundFromURL:[NSURL URLWithString:mi.audioKey]];
    
    //lock screen
    [self displayNowPlayingInfoToLockScreen:mi];
}

//play media for task (Depreciated)
//- (void)playTask:(EWTaskItem *)task{
//
//    playlist = [[task.medias allObjects] mutableCopy];
//    
//    if (playlist.firstObject) {
//        [self playMedia:playlist.firstObject];
//    }
//    
//}

#pragma mark - UI event
- (IBAction)sliderChanged:(UISlider *)sender {
    // Fast skip the music when user scroll the UISlider
    [player stop];
    [player setCurrentTime:progressBar.value];
    NSString *timeStr = [NSString stringWithFormat:@"%ld:%02ld", (long)progressBar.value / 60, (long)progressBar.value % 60, nil];
    currentTime.text = timeStr;
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
        if (![recorder prepareToRecord]) {
            NSLog(@"Unable to start record");
        };
        if (![recorder record]){
            int errorCode = CFSwapInt32HostToBig ([err code]);
            NSLog(@"Error: %@ [%4.4s])" , [err localizedDescription], (char*)&errorCode);
        }
        //setup the UI
        [self updateViewForRecorderState:recorder];
        NSLog(@"Recording...");
    }
    return nil;
}

#pragma mark - update UI
- (void)updateViewForPlayerState:(AVAudioPlayer *)p
{
    //init the progress bar
    if (progressBar) {
        [self updateCurrentTime];
        progressBar.maximumValue = player.duration;
    }
    //timer stop first
	if (updateTimer)
		[updateTimer invalidate];
    //set up timer
	if (p.playing){
		//[lvlMeter_in setPlayer:p];
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTime) userInfo:p repeats:YES];
	}
	else{
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

-(void)updateCurrentTime{
    if (!progressBar.isTouchInside) {
        progressBar.value = player.currentTime;
        currentTime.text = [NSString stringWithFormat:@"%ld:%02ld", (long)player.currentTime / 60, (long)player.currentTime % 60, nil];
    }
}

-(void)updateCurrentTimeForRecorder{
    if (!progressBar.isTouchInside) {
        progressBar.value = recorder.currentTime;
        currentTime.text = [NSString stringWithFormat:@"%ld:%02ld", (long)recorder.currentTime / 60, (long)recorder.currentTime % 60, nil];
    }
}


#pragma mark - AVAudioPlayer delegate method
- (void) audioPlayerDidFinishPlaying: (AVAudioPlayer *)p successfully:(BOOL)flag {
    [updateTimer invalidate];
    self.player.currentTime = 0.0;
    progressBar.value = 0.0;
    //NSLog(@"Playback fnished");
    [[NSNotificationCenter defaultCenter] postNotificationName:kAudioPlayerDidFinishPlaying object:nil];
    
    //play next
//    NSString *currentPath = p.url.absoluteString;
//    NSUInteger currentCount = [playlist indexOfObject:currentPath];
//    if (currentCount == NSNotFound) return;
//    NSString *nextPath;
//    if (currentCount < playlist.count - 1) {
//        nextPath = playlist[currentCount+1];
//    }else{
//        if (self.loop) {
//            nextPath = playlist.firstObject;
//        }else{
//            return;
//        }
//    }
//    [[NSNotificationCenter defaultCenter] postNotificationName:kAudioPlayerWillStart object:nil userInfo:@{kAudioPlayerNextPath: nextPath}];
//    [self playSoundFromFile:nextPath];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    [updateTimer invalidate];
    [recordStopBtn setTitle:@"Record" forState:UIControlStateNormal];
    //NSLog(@"Recording reached max length");
}


#pragma mark - Delegate events
- (void)stopAllPlaying{
    [player stop];
    //[qPlayer pause];
    [avplayer pause];
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)p{
    [p stop];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)p{
    [p play];
}

#pragma mark - AVPlayer (used to play sound and keep the audio capability open)
- (void)playAvplayerWithURL:(NSURL *)url{
    NSLog(@"AVPlayer is about to play %@", url);
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    avplayer = [AVPlayer playerWithPlayerItem:item];
    [avplayer setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    avplayer.volume = 1.0;
    //[avplayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    [avplayer play];
}



//- (void)observeValueForKeyPath:(NSString *)keyPath
//                      ofObject:(id)object
//                        change:(NSDictionary *)change
//                       context:(void *)context{
//    if ([object isKindOfClass:[avplayer class]] && [keyPath isEqual:@"status"]) {
//        //observed status change for avplayer
//        if (avplayer.status == AVPlayerStatusReadyToPlay) {
//            [avplayer play];
//            //tracking time
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
//        }else if(avplayer.status == AVPlayerStatusFailed){
//            // deal with failure
//            NSLog(@"Failed to load audio");
//        }
//    }
//}



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
    NSLog(@"%s: Received background event notification", __func__);
}



#pragma  mark - System Sound Service
- (void)playSystemSound:(NSURL *)path{
    //release old id first
    AudioServicesRemoveSystemSoundCompletion(soundID);
    AudioServicesDisposeSystemSoundID(soundID);
    
    //SystemSound
    NSURL *soundUrl;
    if (!path) {
        soundUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"new" ofType:@"caf"]];
    }else{
        if ([path isFileURL] || ![path.absoluteString hasPrefix:@"http"]) {
            //local file
            soundUrl = path;
        }else{
            NSString *cachePath = [[EWDataStore sharedInstance] localPathForKey:path.absoluteString];
            if (cachePath) {
                soundUrl = [NSURL fileURLWithPath:cachePath];
            }else{
                NSLog(@"Passed remote url to system audio service");
                soundUrl = path;
            }
            
        }
        
    }
    //play
    NSLog(@"Start playing system sound");
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundUrl, &soundID);
    AudioServicesPlayAlertSound(soundID);
    //AudioServicesPlaySystemSound(soundID);
    
    //long background server
    UIBackgroundTaskIdentifier bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"Playing timer for system audio service is ending");
    }];
    
    //completion callback
    AudioServicesAddSystemSoundCompletion(soundID, nil, nil, systemSoundFinished, (void *)bgTaskId);
}

void systemSoundFinished (SystemSoundID sound, void *bgTaskId){
    //NSLog(@"System audio playback fnished");
    
    if ([AVManager sharedManager].media) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAudioPlayerDidFinishPlaying object:nil];
        NSLog(@"broadcasting finish event");
    }    
    [[UIApplication sharedApplication] endBackgroundTask:(NSInteger)bgTaskId];
}


#pragma mark - Remote control
- (void)displayNowPlayingInfoToLockScreen:(EWMediaItem *)m{
    //only support iOS5+
    if (NSClassFromString(@"MPNowPlayingInfoCenter")){
        
        if (!m) m = media;
        EWTaskItem *task = [m.tasks anyObject];
        NSString *title = [task.time weekday];
        
        //info
        NSMutableDictionary *dict = [NSMutableDictionary new];
        dict[MPMediaItemPropertyTitle] = @"Time to wake up";
        dict[MPMediaItemPropertyArtist] = m.author.name;
        dict[MPMediaItemPropertyAlbumTitle] = title;
        
        //cover
        UIImage *cover = media.image ? media.image : media.author.profilePic;
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:cover];
        dict[MPMediaItemPropertyArtwork] = artwork;
        //TODO: media message can be rendered on image
        
        //set
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dict];
        
        NSLog(@"Set lock screen informantion");
    }
}
@end
