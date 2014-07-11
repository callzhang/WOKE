//
//  EWRecordingViewController.m
//  EarlyWorm
//
//  Created by Lei on 12/24/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWRecordingViewController.h"
#import "EWAppDelegate.h"

//Util
#import "NSDate+Extend.h"
#import "MBProgressHUD.h"
#import "EWCollectionPersonCell.h"
#import "SCSiriWaveformView.h"
#import "EWUIUtil.h"
#import "EWTaskStore.h"

//object
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWMediaItem.h"
#import "EWMediaStore.h"
#import "EWPerson.h"
#import "EWPersonStore.h"

//backend
#import "EWDataStore.h"
#import "EWServer.h"


#import "UAProgressView.h"
@interface EWRecordingViewController (){
    NSArray *personSet;
    NSURL *recordingFileUrl;
    AVManager *manager;
    
    BOOL  everPlayed;
    //EWMediaItem *media;
}

@end

@implementation EWRecordingViewController
@synthesize playBtn, recordBtn;
@synthesize manager = manager;

- (EWRecordingViewController *)initWithPerson:(EWPerson *)user{
    self = [super init];
    if (self) {
        //person
        personSet = @[user];
        manager = [AVManager sharedManager];
    }
    return self;
}

- (EWRecordingViewController *)initWithPeople:(NSSet *)ps{
    self = [super init];
    if (self) {
        personSet = [ps allObjects];
        manager = [AVManager sharedManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initProgressView];
    

    [self initView];
    //collection view
    UINib *nib = [UINib nibWithNibName:@"EWCollectionPersonCell" bundle:nil];
    [self.peopleView registerNib:nib forCellWithReuseIdentifier:@"cellIdentifier"];
    self.peopleView.backgroundColor = [UIColor clearColor];
    

    //waveform
    [self.waveformView setWaveColor:[UIColor colorWithWhite:1.0 alpha:0.6]];
    [AVManager sharedManager].waveformView = self.waveformView;

    [AVManager sharedManager].playStopBtn = playBtn;
    [AVManager sharedManager].recordStopBtn = recordBtn;
}
-(void)initProgressView
{
//    self.progressView.tintColor = [UIColor colorWithRed:5/255.0 green:204/255.0 blue:197/255.0 alpha:1.0];
    self.progressView.tintColor = [UIColor whiteColor];
    //不显示外层
	self.progressView.borderWidth = 0.0;
	self.progressView.lineWidth = 2.5;
    
//	self.progressView.fillOnTouch = YES;
	
	UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 32.0)];
	textLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:20];
	textLabel.textAlignment = NSTextAlignmentCenter;
	textLabel.textColor = self.progressView.tintColor;
	textLabel.backgroundColor = [UIColor clearColor];
	self.progressView.centralView = textLabel;
	
      __weak  typeof (self) copySelf =  self;
    
	self.progressView.fillChangedBlock = ^(UAProgressView *progressView, BOOL filled, BOOL animated){
//		UIColor *color = (filled ? [UIColor redColor] : progressView.tintColor);
//      
//		if (animated) {
//			[UIView animateWithDuration:0.3 animations:^{
//                progressView.tintColor = [UIColor redColor];
//				[(UILabel *)progressView.centralView setTextColor:color];
//                [copySelf record:nil];
//			}];
//		} else {
//            progressView.tintColor = [UIColor whiteColor];
//			[(UILabel *)progressView.centralView setTextColor:color];
//		}
	};
	
	self.progressView.progressChangedBlock = ^(UAProgressView *progressView, float progress){
        
//        self.progressView.tintColor = [UIColor clearColor];
//        copySelf.progressView.borderWidth = 0;
        
        if (copySelf.manager.recorder.isRecording) {
            [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%2.0f",copySelf.manager.recorder.currentTime]];
            
        }
        if (copySelf.manager.player.isPlaying) {
            [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%2.0f",copySelf.manager.player.currentTime]];
        }
		
	};
	
		
	self.progressView.didSelectBlock = ^(UAProgressView *progressView){
		
//		[copySelf record:nil];
	};
	
	self.progressView.progress = 0;
	
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
    
}

-(void)initView{
    
    self.playBtn.enabled = NO;
    
    self.title = @"Recording";
    
    if (personSet.count == 1) {
        EWPerson *receiver = personSet[0];
        
        self.wish.text = receiver.cachedInfo[kNextTaskStatement];
        
        
        self.detail.text = [NSString stringWithFormat:@"%@ wants to hear", receiver.name];
        EWTaskItem *nextTask = [[EWTaskStore sharedInstance] nextValidTaskForPerson:receiver];
        NSString *str;
        if (nextTask.statement) {
            str = [NSString stringWithFormat:@"\"%@\"", nextTask.statement];
        }else if (receiver.cachedInfo[kNextTaskStatement]){
            str = [NSString stringWithFormat:@"\"%@\"", receiver.cachedInfo[kNextTaskStatement]];
        }else{
            str = @"\"say good morning\"";
        }
        self.wish.text = str;
        
    }else{
        self.detail.text = @"Sent voice greeting for their next morning";
        self.wish.text = @"";
    }
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[AVManager sharedManager] registerRecordingAudioSession];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [[AVManager sharedManager] registerAudioSession];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - collection view
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    EWCollectionPersonCell *cell = (EWCollectionPersonCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    cell.showName = YES;
    EWPerson *receiver = personSet[indexPath.row];
    cell.person = receiver;
    return cell;
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return personSet.count;
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    
    NSInteger numberOfCells = personSet.count;
    NSInteger edgeInsets = (self.peopleView.frame.size.width - (numberOfCells * kCollectionViewCellWidth) - numberOfCells * 10) / 2;
    edgeInsets = MAX(edgeInsets, 20);
    return UIEdgeInsetsMake(0, edgeInsets, 0, edgeInsets);
}

#pragma mark- Actions

- (IBAction)play:(id)sender {
    
    if (!recordingFileUrl){
        NSLog(@"Recording url empty");
        
        return;
    }
    
    if ([manager.recorder isRecording]) {
        return;
    }
    
    if (!manager.player.isPlaying) {
        [playBtn setTitle:@"Stop" forState:UIControlStateNormal];
        everPlayed = YES;
        [manager playSoundFromURL:recordingFileUrl];
    }else{
        [playBtn setTitle:@"Play" forState:UIControlStateNormal];
        [manager stopAllPlaying];
    }
}

- (IBAction)record:(id)sender {
    recordingFileUrl = [manager record];
    
    if (manager.recorder.isRecording) {
        [recordBtn setTitle:@"Stop" forState:UIControlStateNormal];
    }else{
        [recordBtn setTitle:@"Retake" forState:UIControlStateNormal];
    }
}

- (IBAction)send:(id)sender {
    if (recordingFileUrl) {
        //finished recording, prepare for data
        NSError *err;
        NSData *recordData = [NSData dataWithContentsOfFile:[recordingFileUrl path] options:0 error:&err];
        if (!recordData) {
            return;
        }
        //NSString *fileName = [NSString stringWithFormat:@"voice_%@_%@.m4a", me.username, [[NSDate date] date2numberDateString]];
        
        //save data to task
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        
        
        EWMediaItem *media = [[EWMediaStore sharedInstance] createMedia];
        media.author = me;
        media.type = kMediaTypeVoice;
//        media.message = self.message.text;
        
        //Add to media queue instead of task
        media.receivers = [NSSet setWithArray:personSet];
        
        media.audio = recordData;
        media.createdAt = [NSDate date];
        
        
        //save
        [EWDataStore saveWithCompletion:^{
            
            //set ACL
            PFACL *acl = [PFACL ACL];
            PFObject *object = media.parseObject;
            for (NSString *userID in [personSet valueForKey:kParseObjectID]) {
                [acl setReadAccess:YES forUserId:userID];
                [acl setWriteAccess:YES forUserId:userID];
            }
            [object setACL:acl];
            [object saveInBackground];
            
            //send push notification
            for (EWPerson *receiver in personSet) {
                [EWServer pushMedia:media ForUser:receiver];
            }
        }];
        
        
        //clean up
        recordingFileUrl = nil;
        
        //dismiss hud
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        //dismiss
        [rootViewController dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (IBAction)seek:(id)sender {
    //
}

- (IBAction)close:(id)sender {

    
    if ([self.manager.recorder isRecording]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Stop Record Before Close" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
    }
    else{

        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    }
}


- (void)updateProgress:(NSTimer *)timer {
    
    if ([manager.recorder isRecording]) {
        [self.progressView  setProgress: manager.recorder.currentTime/kMaxRecordTime];
    
    }
    if(manager.player.isPlaying)
    {
        [self.progressView  setProgress: manager.player.currentTime/kMaxRecordTime];
    }
    if (!manager.player.isPlaying&&everPlayed) {
        
        [playBtn setTitle:@"Replay" forState:UIControlStateNormal];
        [self.progressView  setProgress: 0];
        
//        [recordBtn setTitle:@"Retake" forState:UIControlStateNormal];
    }
    if (!manager.recorder.isRecording && recordingFileUrl) {
        [recordBtn setTitle:@"Retake" forState:UIControlStateNormal];
    }
  
//		[self.progressView setProgress:_localProgress];

}
@end
