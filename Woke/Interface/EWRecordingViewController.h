//
//  EWRecordingViewController.h
//  EarlyWorm
//
//  Created by Lei on 12/24/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWViewController.h"
#import "AVManager.h"
#import "UAProgressView.h"
@class EWTaskItem;
@class SCSiriWaveformView;

@interface EWRecordingViewController : EWViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong,nonatomic)     AVManager *manager;


@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;

@property (weak, nonatomic) IBOutlet UILabel *detail;
@property (weak, nonatomic) IBOutlet UICollectionView *peopleView;
@property (weak, nonatomic) IBOutlet SCSiriWaveformView *waveformView;
@property (strong, nonatomic) IBOutlet UAProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *wish;

- (IBAction)play:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)send:(id)sender;


- (EWRecordingViewController *)initWithPerson:(EWPerson *)user;
- (EWRecordingViewController *)initWithPeople:(NSSet *)personSet;
@end
