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

//object
#import "EWTaskItem.h"
#import "EWMediaItem.h"
#import "EWMediaStore.h"
#import "EWPerson.h"
#import "EWPersonStore.h"

//backend
#import "StackMob.h"
#import "EWDataStore.h"
#import "EWServer.h"

@interface EWRecordingViewController (){
    EWPerson *person;
}

@end

@implementation EWRecordingViewController
@synthesize progressBar, playBtn, recordBtn, closeBtn;
@synthesize task;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        manager = [AVManager sharedManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //person
    person = task.owner?task.owner:task.pastOwner;
    self.view.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    self.profilePic.image = person.profilePic;
    self.profilePic.layer.cornerRadius = 50;
    self.detail.text = [NSString stringWithFormat:@"Leave voice to %@ for %@", person.name, [task.time weekday]];
    //close btn
    closeBtn.layer.cornerRadius = 5;
    closeBtn.layer.borderWidth = 1.0f;
    closeBtn.layer.borderColor = [UIColor whiteColor].CGColor;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)play:(id)sender {
    manager.progressBar = (EWMediaSlider *)progressBar;
    manager.playStopBtn = playBtn;
    
    if (!manager.player.isPlaying) {
        [playBtn setTitle:@"Stop" forState:UIControlStateNormal];
        [manager playSoundFromURL:recordingFileUrl];
    }else{
        [playBtn setTitle:@"Play" forState:UIControlStateNormal];
        [manager stopAllPlaying];
    }
}

- (IBAction)record:(id)sender {
    manager.progressBar = (EWMediaSlider *)progressBar;
    progressBar.maximumValue = kMaxRecordTime;
    manager.recordStopBtn = recordBtn;
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
        //save data to task
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSString *fileName = [NSString stringWithFormat:@"voice_%@_%@.m4a", currentUser.username, [NSString stringWithFormat:@"%ld",(long)[NSDate timeIntervalSinceReferenceDate]]];
        NSString *recordDataString = [SMBinaryDataConversion stringForBinaryData:recordData name:fileName contentType:@"audio/aac"];
        if (!media) {
            media = [[EWMediaStore sharedInstance] createMedia];
            media.author = currentUser;
            media.message = self.message.text;
            [media addTasksObject:task];
            media.audioKey = recordDataString;
            media.createddate = [NSDate date];
        }
        
        
        //save
        //NSManagedObjectContext *context = [[[SMClient defaultClient] coreDataStore] contextForCurrentThread];
        [[EWDataStore currentContext] saveOnSuccess:^{
            [media.managedObjectContext refreshObject:media mergeChanges:YES];
            
            //dismiss hud
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
            if ([media.audioKey length]<300) {
                //clean
                recordingFileUrl = nil;
                
                NSLog(@"Audio uploaded to server: %@", media.audioKey);
            }else{
                media = [[EWMediaStore sharedInstance] getMediaByID:media.ewmediaitem_id];
                if (media.audioKey.length > 500) {
                    NSLog(@"audioKey failed to upload to S3 server and remained as string data");
                    EWAlert(@"Server busy, please try again.");
                    
                    return;
                }else{
                    recordingFileUrl = nil;
                }
                
            }
            
            //send push notification
            [EWServer pushMedia:media.ewmediaitem_id ForUsers:@[person] ForTask:task.ewtaskitem_id];
            
            //dismiss
            [self dismissViewControllerAnimated:YES completion:NULL];
            
        } onFailure:^(NSError *error) {
            EWAlert(@"Server failed to save. Please try again");
        }];
    }
}

- (IBAction)seek:(id)sender {
}

- (IBAction)back:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}
@end
