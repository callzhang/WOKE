//
//  EWRecordingViewController.h
//  EarlyWorm
//
//  Created by Lei on 12/24/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWViewController.h"
#import "AVManager.h"
@class EWTaskItem;


@interface EWRecordingViewController : EWViewController{
    NSURL *recordingFileUrl;
    AVManager *manager;
}

@property (nonatomic) EWTaskItem *task;
@property (weak, nonatomic) IBOutlet UISlider *progressBar;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;

- (IBAction)play:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)send:(id)sender;
- (IBAction)seek:(id)sender;
- (IBAction)back:(id)sender;

@end
