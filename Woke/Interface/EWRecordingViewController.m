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
//#import "EWTaskManager.h"
#import "EWDefines.h"
#import "UAProgressView.h"
//object
//#import "EWTaskItem.h"
//#import "EWTaskManager.h"
#import "EWMedia.h"
#import "EWMediaManager.h"
#import "EWPerson.h"
#import "EWPersonManager.h"

//backend
#import "EWDataStore.h"
#import "EWServer.h"
#import "ATConnect.h"
#import "EWBackgroundingManager.h"
#import "UAProgressView.h"
#import "EWAlarmManager.h"
#define BUTTONCENTER  CGPointMake(470, EWScreenWidth/2)

@interface EWRecordingViewController (){
    NSArray *personSet;
    NSURL *recordingFileUrl;
    AVManager *manager;
    
    BOOL  everPlayed;
    BOOL  everRecord;
    //EWMedia *media;
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

- (void)viewDidLoad{
    [super viewDidLoad];
    [self initProgressView];
    [self initButtonAndLabel];
    [self initView];
    
    //NavigationController
    [EWUIUtil addTransparantNavigationBarToViewController:self withLeftItem:nil rightItem:nil];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MoreButton"] style:UIBarButtonItemStylePlain target:self action:@selector(more:)];
    
    //collection view
    UINib *nib = [UINib nibWithNibName:@"EWCollectionPersonCell" bundle:nil];
    [self.peopleView registerNib:nib forCellWithReuseIdentifier:@"cellIdentifier"];
    self.peopleView.backgroundColor = [UIColor clearColor];
    

    //waveform
    [self.waveformView setWaveColor:[UIColor colorWithWhite:1.0 alpha:0.75]];
    [AVManager sharedManager].waveformView = self.waveformView;

    [AVManager sharedManager].playStopBtn = playBtn;
    [AVManager sharedManager].recordStopBtn = recordBtn;
}

-(void)initProgressView{
    
    self.progressView.tintColor = [UIColor whiteColor];
	self.progressView.borderWidth = 0.0;
	self.progressView.lineWidth = 1;
    
//	self.progressView.fillOnTouch = YES;
	
	UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 32.0)];
	textLabel.font = [UIFont fontWithName:@"Lane-Narrow.ttf" size:24];
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
-(void)initButtonAndLabel
{
    self.playLabel.text = @"Take";
    [self.playBtn setImage:[UIImage imageNamed:@"Record Button Red "] forState:UIControlStateNormal];
//    self.recordBtn.hidden = YES;
//    self.sendBtn.hidden = YES;
//
//    self.retakeLabel.hidden = YES;
//    self.sendLabel.hidden = YES;
    everPlayed = NO;
    everRecord = NO;
    self.recordBtn.alpha = 0.0;
    self.sendBtn.alpha = 0.0;
    self.sendLabel.alpha = 0.0;
    self.retakeLabel.alpha = 0.0;
    
    
}
-(void)initView{
    
    self.title = @"Recording";
    
    if (personSet.count == 1) {
        EWPerson *receiver = personSet[0];
        
        NSString *statement = [[EWAlarmManager sharedInstance] nextStatementForPerson:receiver];
        
        _detail.font = [UIFont fontWithName:@"Lato-Light.ttf" size:20];
        _wish.font = [UIFont fontWithName:@"Lato-Light.ttf" size:16];
        
        self.detail.text = [NSString stringWithFormat:@"%@ wants to hear", receiver.name];
        if (statement) {
            _wish.text = [NSString stringWithFormat:@"\"%@\"", statement];
        }else{
            _wish.text = @"\"say good morning\"";
        }
        
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
    
    [[EWBackgroundingManager sharedInstance] registerBackgroudingAudioSession];
}

#pragma mark - collection view
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    EWCollectionPersonCell *cell = (EWCollectionPersonCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    cell.showName = NO;
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
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(80, 100);
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
    
    if (!everRecord || self.manager.recorder.isRecording) {
        [self record:nil];
        
        
        return ;
    }
    
    if (!recordingFileUrl){
        NSLog(@"Recording url empty");
        
        return;
    }
    
    if ([manager.recorder isRecording]) {
        return;
    }
    
    if (!manager.player.isPlaying) {

        everPlayed = YES;
        [manager playSoundFromURL:recordingFileUrl];
        self.playLabel.text = @"Stop";
        [self.playBtn setImage:[UIImage imageNamed:@"Stop Button"] forState:UIControlStateNormal];
        
    }else{
        
        self.playLabel.text = @"Play";
        [self.playBtn setImage:[UIImage imageNamed:@"Play Button"] forState:UIControlStateNormal];     [manager stopAllPlaying];
    }
}

- (IBAction)record:(id)sender {
    
    if (manager.player.isPlaying) {
        
        return ;
    }
    
    
    recordingFileUrl = [manager record];
    
    if (manager.recorder.isRecording) {
        if (!everRecord) {
            // 第一次进入 直接改变
            [self.playBtn setImage:[UIImage imageNamed:@"Stop Button Red "] forState:UIControlStateNormal];
            self.playLabel.text = @"Stop";
        }
        else
        {
            [UIView animateWithDuration:1.0 animations:^(){
                self.sendBtn.alpha = 0.0;
                self.recordBtn.alpha = 0.0;
                self.sendLabel.alpha = 0.0;
                self.retakeLabel.alpha = 0.0;
                self.playLabel.text = @"Stop";
                  [self.playBtn setImage:[UIImage imageNamed:@"Stop Button Red "] forState:UIControlStateNormal];
                
            }];
        }
    }else{
        if (!everRecord) {
            everRecord = YES;
        }
        [UIView animateWithDuration:1.0 animations:^(){
            self.sendBtn.alpha = 1.0;
            self.recordBtn.alpha = 1.0;
            self.sendLabel.alpha = 1.0;
            self.retakeLabel.alpha = 1.0;
            self.retakeLabel.text = @"Retake";
            self.playLabel.text  = @"Play";
            [self.playBtn setImage:[UIImage imageNamed:@"Play Button"] forState:UIControlStateNormal];
        }];
        
    }
}

- (IBAction)send:(id)sender {
    if (recordingFileUrl) {
        
        
        //finished recording, prepare for data
//        NSError *err;
//        NSData *recordData = [NSData dataWithContentsOfFile:[recordingFileUrl path] options:0 error:&err];
//        if (!recordData) {
//            return;
//        }
//        //NSString *fileName = [NSString stringWithFormat:@"voice_%@_%@.m4a", me.username, [[NSDate date] date2numberDateString]];
//        
//        //save data to task
//        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        
//        [[ATConnect sharedConnection] engage:kRecordVoiceSuccess fromViewController:self];
//        
//        EWMedia *media = [EWMedia newMedia];
//        media.author = [EWSession sharedSession].currentUser;
//        media.type = kMediaTypeVoice;
////        media.message = self.message.text;
//        
//        //Add to media queue instead of task
//        media.receiver = personSet;
//        
//        media.audio = recordData;
//        media.createdAt = [NSDate date];
//        
//        
//        //save
//        [EWSync saveWithCompletion:^{
//            
//            //set ACL
//            PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
//            if ([[EWSession sharedSession].currentUser.objectId isEqualToString:WokeUserID]) {
//                //if WOKE, set public
//                [acl setPublicReadAccess:YES];
//                [acl setPublicWriteAccess:YES];
//            }else{
//                for (NSString *userID in [personSet valueForKey:kParseObjectID]) {
//                    [acl setReadAccess:YES forUserId:userID];
//                    [acl setWriteAccess:YES forUserId:userID];
//                }
//            }
//            
//            PFObject *object = media.parseObject;
//            [object setACL:acl];
//            [object saveInBackground];
//            
//            //send push notification
//            for (EWPerson *receiver in personSet) {
//                [EWServer pushVoice:media toUser:receiver];
//            }
//        }];
//        
//        
//        //clean up
//        recordingFileUrl = nil;
//        
//        //dismiss hud
//        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//        
//        //dismiss
//        [rootViewController dismissBlurViewControllerWithCompletionHandler:NULL];
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

        [self dismissBlurViewControllerWithCompletionHandler:NULL];
    }
}


- (void)updateProgress:(NSTimer *)timer {
    
    if ([manager.recorder isRecording]) {
        
        float progress = (float) manager.recorder.currentTime /kMaxRecordTime;
        [self.progressView  setProgress:progress>0.999?0.999:progress];
    
    }
    if(manager.player.isPlaying)
    {
        float progress = (float) manager.player.currentTime /kMaxRecordTime;
        [self.progressView  setProgress:progress>0.999?0.999:progress];
   
    }
    if (!manager.player.isPlaying&&everPlayed&&!manager.recorder.recording) {
        [playBtn setImage:[UIImage imageNamed:@"Play Button"] forState:UIControlStateNormal];
//        [self.progressView  setProgress: 0];
        
        [self.playLabel setText:@"Play"];
    }
    if (!manager.recorder.isRecording && recordingFileUrl) {
        [recordBtn setTitle:@"Retake" forState:UIControlStateNormal];
    }
  
//		[self.progressView setProgress:_localProgress];

}
@end
