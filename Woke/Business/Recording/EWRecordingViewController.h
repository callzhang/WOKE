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
@class SCSiriWaveformView;

@interface EWRecordingViewController : EWViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UISlider *progressBar;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UITextField *message;
@property (weak, nonatomic) IBOutlet UILabel *detail;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;
@property (weak, nonatomic) IBOutlet UICollectionView *peopleView;
@property (weak, nonatomic) IBOutlet SCSiriWaveformView *waveformView;

- (IBAction)play:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)send:(id)sender;
- (IBAction)seek:(id)sender;
- (IBAction)back:(id)sender;


- (EWRecordingViewController *)initWithPerson:(EWPerson *)user;
- (EWRecordingViewController *)initWithPeople:(NSSet *)personSet;
@end
