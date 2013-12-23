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
@synthesize player, progressBar;

void RouteChangeListener(void *                  inClientData,
                         AudioSessionPropertyID  inID,
                         UInt32                  inDataSize,
                         const void *            inData);

-(id)init{
    //static AVManager *sharedManager_ = nil;
    self = [super init];
    if (self) {
        //regist the player
        NSError *err = nil;
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:NULL error:&err];
        if (self.player)
        {
            //NSLog(@"Playr URL: %@\n", player.url);
            //fileName.text = [NSString stringWithFormat: @"%@ (%d ch.)", [[player.url relativePath] lastPathComponent], player.numberOfChannels, nil];
            //[self updateViewForPlayerInfo:player];
            [self updateViewForPlayerState:player];
            player.numberOfLoops = 0; //no repeat
            player.delegate = self;
        }
        
        OSStatus result = AudioSessionInitialize(NULL, NULL, NULL, NULL);
        if (result)
            NSLog(@"Error initializing audio session! %ld", result);
        
        [[AVAudioSession sharedInstance] setDelegate: self];
        NSError *setCategoryError = nil;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError];
        if (setCategoryError)
            NSLog(@"Error setting category! %@", setCategoryError);
        
        result = AudioSessionAddPropertyListener (kAudioSessionProperty_AudioRouteChange, RouteChangeListener, (__bridge void *)(self));  //?????
        if (result) 
            NSLog(@"Could not add property listener! %ld", result);
    }
    return self;
}

+(AVManager *)sharedManager{
    static AVManager *sharedManager_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager_ = [[AVManager alloc] init];
    });
    return sharedManager_;
}

//play for cell with progress
-(void)playForCell:(EWMediaViewCell *)cell{
    NSArray *array = [cell.media.audioKey componentsSeparatedByString:@"."];
    
    NSString *file = nil;
    NSString *type = nil;
    if (array.count == 2) {
        file = [array firstObject];
        type = [array lastObject];
    }
    else {
        [NSException raise:@"Unexpected file format" format:@"Please provide a who file name with extension"];
    }
    //link progress bar with cell's progress bar
    progressBar = cell.progressBar;
    if (player.playing) {
        [player stop];
    } else {
        NSString *url = [[NSBundle mainBundle] pathForResource:file ofType:type];
        NSURL *soundURL = [NSURL fileURLWithPath:url];
        NSError *err;
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&err];
        [player prepareToPlay];
        if ([player play])
        {
            progressBar.maximumValue = player.duration;
            [self updateViewForPlayerState:player];
        }
        else
            NSLog(@"Could not play %@\n", player.url);
    }
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
    if (player.playing && player.url == soundURL) {
        [player stop];
    } else {
        NSError *err;
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&err];
        [player prepareToPlay];
        if (![player play]) NSLog(@"Could not play %@\n", player.url);
    }
}


- (void)updateViewForPlayerState:(AVAudioPlayer *)p
{
    if (progressBar) {
        [self updateCurrentTime];
    }
	
    
	if (updateTimer)
		[updateTimer invalidate];
    
	if (p.playing)
	{
		//[playButton setImage:((p.playing == YES) ? pauseBtnBG : playBtnBG) forState:UIControlStateNormal];
		//[lvlMeter_in setPlayer:p];
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(updateCurrentTime) userInfo:p repeats:YES];
	}
	else
	{
		//[playButton setImage:((p.playing == YES) ? pauseBtnBG : playBtnBG) forState:UIControlStateNormal];
		//[lvlMeter_in setPlayer:nil];
		updateTimer = nil;
	}
	
}

-(void)updateCurrentTime
{
	//currentTime.text = [NSString stringWithFormat:@"%d:%02d", (NSInteger)p.currentTime / 60, (NSInteger)p.currentTime % 60, nil];
	progressBar.value = player.currentTime;
}

#pragma mark AVAudioPlayer delegate method
- (void) audioPlayerDidFinishPlaying: (AVAudioPlayer *)myaudio successfully:(BOOL)flag {
    //soundplay = 0;
    NSLog(@"sound fnished");
}

//AVManager
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

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    self.player.currentTime = 0.0;
}

- (void)stopAllPlaying{
    [player stop];
}

#pragma mark AudioSession handlers
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
}

- (void)pausePlaybackForPlayer:(AVAudioPlayer *)player {
    
}

@end
