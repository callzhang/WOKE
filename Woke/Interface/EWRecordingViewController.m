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

//object
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWMediaItem.h"
#import "EWMediaStore.h"
#import "EWPerson.h"
#import "EWPersonStore.h"

//backend
#import "StackMob.h"
#import "EWDataStore.h"
#import "EWServer.h"

@interface EWRecordingViewController (){
    NSArray *personSet;
    NSURL *recordingFileUrl;
    AVManager *manager;
    //EWMediaItem *media;
}

@end

@implementation EWRecordingViewController
@synthesize progressBar, playBtn, recordBtn, closeBtn;


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
    if (personSet.count == 1) {
        EWPerson *receiver = personSet[0];
        EWTaskItem *task = [[EWTaskStore sharedInstance] nextValidTaskForPerson:receiver];
        self.detail.text = [NSString stringWithFormat:@"Leave voice to %@ for %@", receiver.name, [task.time weekday]];
    }else{
        self.detail.text = @"Sent voice greeting for their next wake up";
    }
    
    //collection view
    UINib *nib = [UINib nibWithNibName:@"EWCollectionPersonCell" bundle:nil];
    [self.peopleView registerNib:nib forCellWithReuseIdentifier:@"cellIdentifier"];
    self.peopleView.backgroundColor = [UIColor clearColor];
    
    //close btn
    closeBtn.layer.cornerRadius = 5;
    
    //waveform
    [self.waveformView setWaveColor:[UIColor colorWithWhite:1.0 alpha:0.6]];
    [AVManager sharedManager].waveformView = self.waveformView;
    [AVManager sharedManager].progressBar = (EWMediaSlider *)progressBar;
    [AVManager sharedManager].playStopBtn = playBtn;
    [AVManager sharedManager].recordStopBtn = recordBtn;
    
    //slider
    [progressBar setThumbImage:[UIImage imageNamed:@"MediaCellThumb"] forState:UIControlStateNormal];
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
    [cell applyHexagonMask];
    EWPerson *receiver = personSet[indexPath.row];
    cell.profilePic.image = receiver.profilePic;
    cell.initial.text = [receiver.name initial];
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
        [manager playSoundFromURL:recordingFileUrl];
    }else{
        [playBtn setTitle:@"Play" forState:UIControlStateNormal];
        [manager stopAllPlaying];
    }
}

- (IBAction)record:(id)sender {
    progressBar.maximumValue = kMaxRecordTime;
    recordingFileUrl = [manager record];
    
    if (manager.recorder.isRecording) {
        [recordBtn setTitle:@"Stop" forState:UIControlStateNormal];
    }else{
        [recordBtn setTitle:@"Record" forState:UIControlStateNormal];
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
        NSString *fileName = [NSString stringWithFormat:@"voice_%@_%@.m4a", currentUser.username, [[NSDate date] date2numberDateString]];
        
        NSString *recordDataString = [SMBinaryDataConversion stringForBinaryData:recordData name:	fileName contentType:@"audio/aac"];
        
        //save data to task
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        for (EWPerson *receiver in personSet) {
            __block EWMediaItem *media = [[EWMediaStore sharedInstance] createMedia];
            media.author = currentUser;
            media.message = self.message.text;
            
            //Add to media queue instead of task
            media.receiver = receiver;
            
            media.audioKey = recordDataString;
            media.createddate = [NSDate date];
            
            
            //save
            [[EWDataStore currentContext] saveOnSuccess:^{
                [[EWDataStore currentContext] refreshObject:media mergeChanges:YES];
                NSInteger n = 10;
                while (media.audioKey.length > 500 && n > 0) {
                    media = [[EWMediaStore sharedInstance] getMediaByID:media.ewmediaitem_id];
                    n--;
                    NSLog(@"Retry %ld", (long)n);
                }
                //send push notification
                [EWServer pushMedia:media ForUser:receiver];
            } onFailure:^(NSError *error) {
                NSLog(@"*** Save media error audio data");
            }];
            
        }
        
        //clean up
        recordingFileUrl = nil;
        
        //dismiss hud
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        //dismiss
        [rootViewController dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (IBAction)seek:(id)sender {
}

- (IBAction)back:(id)sender {
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
}
@end
