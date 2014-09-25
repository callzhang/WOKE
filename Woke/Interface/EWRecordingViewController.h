//
//  EWRecordingViewController.h
//  EarlyWorm
//
//  Created by Lei on 12/24/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

//#import "EWViewController.h"
#import "AVManager.h"
#import "UAProgressView.h"
@class EWTaskItem;
@class SCSiriWaveformView;
@class EWPerson;

@interface EWRecordingViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong,nonatomic)     AVManager *manager;


@property (strong, nonatomic) IBOutlet UIButton *playBtn;
@property (strong, nonatomic) IBOutlet UIButton *recordBtn;
@property (strong, nonatomic) IBOutlet UIButton *sendBtn;

@property (strong, nonatomic) IBOutlet UILabel *detail;
@property (strong, nonatomic) IBOutlet UICollectionView *peopleView;
@property (weak, nonatomic) IBOutlet SCSiriWaveformView *waveformView;
@property (strong, nonatomic) IBOutlet UAProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *wish;

@property (strong, nonatomic) IBOutlet UILabel *retakeLabel;

@property (strong, nonatomic) IBOutlet UILabel *playLabel;

@property (strong, nonatomic) IBOutlet UILabel *sendLabel;

- (IBAction)play:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)send:(id)sender;


- (EWRecordingViewController *)initWithPerson:(EWPerson *)user;
- (EWRecordingViewController *)initWithPeople:(NSSet *)personSet;
@end
