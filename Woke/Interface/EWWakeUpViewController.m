//
//  WakeUpViewController.m
//  EarlyWorm
//
//  Created by Lei Zhang on 7/28/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWWakeUpViewController.h"
#import "EWMediaViewCell.h"
#import "EWShakeManager.h"
#import "EWMediaStore.h"
#import "EWMediaItem.h"
#import "EWTaskItem.h"
#import "EWAppDelegate.h"
#import "ImageViewController.h"
#import "AVManager.h"
#import "NSDate+Extend.h"
#import "EWUIUtil.h"
#import "EWMediaSlider.h"
#import "EWWakeUpManager.h"


#import "ATConnect.h"
#import "EWDefines.h"
//test
#import "EWPostWakeUpViewController.h"

#define cellIdentifier                  @"EWMediaViewCell"


@interface EWWakeUpViewController (){
    
    NSMutableArray *medias;
    BOOL next;
    NSInteger loopCount;
    CGRect headerFrame;
    NSTimer *timerTimer;
    NSUInteger timePast;
}
@end



@implementation EWWakeUpViewController
@synthesize tableView = tableView_;
@synthesize timer, header;
@synthesize person, task;
@synthesize footer;

- (EWWakeUpViewController *)initWithTask:(EWTaskItem *)t{
    self = [self initWithNibName:nil bundle:nil];
    self.task = t;
    
    //first time loop
    next = YES;
    timePast = 1;
    loopCount = kLoopMediaPlayCount;
    
    //notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAudioPlayerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewBuzzNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextCell) name:kAudioPlayerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kNewBuzzNotification object:nil];
    
    //responder to remote control
    [self prepareRemoteControlEventsListener];
    
    
    return self;
}


#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    //origin header frame
    headerFrame = header.frame;
    
    //HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self initView];
    [self initView];
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    //start playing
    [self startPlayCells];
    
}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //timer updates
    timerTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
    [self updateTimer];
    
    //position the content
    [self scrollViewDidScroll:tableView_];
    [self.view setNeedsDisplay];
    
    //pre download everyone for postWakeUpVC
    dispatch_async([EWDataStore sharedInstance].dispatch_queue, ^{
        [[EWPersonStore sharedInstance] everyone];
    });
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self resignRemoteControlEventsListener];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAudioPlayerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewBuzzNotification object:nil];
    
    NSLog(@"WakeUpViewController popped out of view: remote control event listner stopped. Observers removed.");
    
    //Resume to normal session
    [[AVManager sharedManager] registerAudioSession];
    
    //invalid timer
    [timerTimer invalidate];
}

- (void)initData {
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:YES];
    medias = [[task.medias allObjects] mutableCopy];
    [medias sortUsingDescriptors:@[sort]];
    [tableView_ reloadData];
    
    //refresh media
    for (EWMediaItem *media in medias) {
        [media refreshRelatedInBackground];
    }
    
    
    //load MediaViewCell
    UINib *nib = [UINib nibWithNibName:@"EWMediaViewCell" bundle:nil];
    //register the nib
    [tableView_ registerNib:nib forCellReuseIdentifier:cellIdentifier];
    
    //_shakeManager = [[EWShakeManager alloc] init];
    //_shakeManager.delegate = self;
    //[_shakeManager register];
    
    
}

- (void)initView {
    
    header.layer.cornerRadius = 10;
    header.layer.masksToBounds = YES;
    header.layer.borderWidth = 1;
    header.layer.borderColor = [UIColor whiteColor].CGColor;
    header.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    
    timer.text = [task.time date2timeShort];
    self.AM.text = [task.time date2am];
    
    //table view
    //tableView_.frame = CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height-230);
    tableView_.dataSource = self;
    tableView_.delegate = self;
    tableView_.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView_.contentInset = UIEdgeInsetsMake(20, 0, 80, 0);//the distance of the content to the frame of tableview
    
    //alpha mask
    [EWUIUtil applyAlphaGradientForView:tableView_ withEndPoints:@[@0.1f, @0.9f]];
    
    
    if ([self.shakeProgress isShakeSupported]) {
        // need  update
        self.shakeProgress.progress = 0;
        self.shakeProgress.alpha = 0;
    }

    // use button to getup!;
    footer.top = [UIScreen mainScreen].bounds.size.height;
    [self.wakeupButton setTitle:@"Tap To Wake Up!" forState:UIControlStateNormal];
    [self.wakeupButton addTarget:self action:@selector(presentPostWakeUpVC) forControlEvents:UIControlEventTouchUpInside];

    
}

- (void)presentShakeProgressBar{
    [_wakeupButton removeTarget:self action:@selector(presentShakeProgressBar) forControlEvents:UIControlEventTouchUpInside];
    
    [_wakeupButton setTitle:@"" forState:UIControlStateNormal];
    [UIView animateWithDuration:0.5 animations:^{
        //show bar
        _shakeProgress.alpha = 1;
    } completion:^(BOOL finished) {
        //start motion detect
        [_shakeProgress startUpdateProgressBarWithProgressingHandler:^{
            
        } CompleteHandler:^{
            
            //show
            [UIView animateWithDuration:0.5 animations:^{
                _shakeProgress.alpha = 0;
            } completion:^(BOOL finished) {
                
                [_wakeupButton setTitle:@"Wake up others" forState:UIControlStateNormal];
                [_wakeupButton addTarget:self action:@selector(presentWakeUpView) forControlEvents:UIControlEventTouchUpInside];
            }];
        }];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAudioPlayerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewBuzzNotification object:nil];
    
    NSLog(@"WakeUpViewController deallocated. Observers removed.");
}


- (void)refresh{
    [self initData];
    [tableView_ reloadData];
}


- (void)setTask:(EWTaskItem *)t{
    task = t;
    medias = [[task.medias allObjects] mutableCopy];
    //KVO
    [self.task addObserver:self forKeyPath:@"medias" options:NSKeyValueObservingOptionNew context:nil];
    [self initData];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[EWTaskItem class]]) {
        if ([keyPath isEqualToString:@"medias"] && task.medias.count != medias.count) {
            //observed task.media changed
            [self refresh];
        }
    }
}

#pragma mark - UI Actions


- (void)OnCancel{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [[AVManager sharedManager] stopAllPlaying];
    }];
}

-(void)presentPostWakeUpVC
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    //stop music
    [[AVManager sharedManager] stopAllPlaying];
    [AVManager sharedManager].media = nil;
    
    //release the pointer in wakeUpManager
    [EWWakeUpManager woke];
    
    [[ATConnect sharedConnection] engage:kWakeupSuccess fromViewController:self];
    
    //set wakeup time
    if ([task.time isEarlierThan:[NSDate date]]) {
        task.completed = [NSDate date];
    }else{
        task.completed = [task.time dateByAddingTimeInterval:kMaxWakeTime];
    }
    [EWDataStore save];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollViewDidScroll:self.tableView];//prevent header move
    });
    
    EWPostWakeUpViewController * postWakeUpVC = [[EWPostWakeUpViewController alloc] initWithNibName:nil bundle:nil];
    postWakeUpVC.taskItem = task;
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self presentViewControllerWithBlurBackground:postWakeUpVC];
}

#pragma mark - tableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return medias.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

//Asks the data source for a cell to insert in a particular location of the table view. (required)
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    //Use reusable cell or create a new cell
    EWMediaViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    //get media item
    EWMediaItem *mi;
    if (indexPath.row >= medias.count) {
        NSLog(@"@@@ WakupView asking for deleted media");
        mi = nil;
    }else{
        mi = [medias objectAtIndex:indexPath.row];
    }
    
    
    //title
    cell.name.text = mi.author.name;
    
    //control
    cell.controller = self;
    
    //media -> set type and UI
    cell.media = mi;
    
    return cell;
}


//remove item
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    [self scrollViewDidScroll:tableView];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //media
        EWMediaItem *mi = [medias objectAtIndex:indexPath.row];
    
        
        //stop play if media is being played
        if ([[AVManager sharedManager].media isEqual:mi]) {
            //media is being played
            NSLog(@"Deleting current cell, play next");
            if ([tableView numberOfRowsInSection:0] > 1) {
                [self playNextCell];
            }
        }
        
        //remove from data source
        [medias removeObject:mi];
        
        //remove from view with animation
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        //delete
        [[EWMediaStore sharedInstance] deleteMedia:mi];
        [EWDataStore save];
        
        
        //update UI
        [self scrollViewDidScroll:self.tableView];
        
    }
    if (editingStyle==UITableViewCellEditingStyleInsert) {
        //do something
    }
}

//when click one item in table, push view to detail page
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    EWMediaViewCell *cell = (EWMediaViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    if ([cell.media.type isEqualToString:kMediaTypeVoice] || !cell.media.type) {
        [[AVManager sharedManager] playForCell:cell];
    }
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
    
    next = NO;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"Flag";
}

- (NSString *)tableView:(UITableView *)tableView titleForSwipeAccessoryButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Like";
}

- (void)tableView:(UITableView *)tableView swipeAccessoryButtonPushedForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view showSuccessNotification:@"Liked"];
    
    // Hide the More/Delete menu.
    [self setEditing:NO animated:YES];
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    
    //header
    //NSInteger tableOffsetY = scrollView.contentOffset.y;
    
    // mq
    
//    CGRect newFrame = headerFrame;
//    newFrame.origin.y = MAX(headerFrame.origin.y - (120 + scrollView.contentOffset.y), -70);
//    header.frame = newFrame;
//    //font size
//    CGRect f = self.timer.frame;
//    CGPoint c = self.timer.center;
//    f.size.width = 180 + newFrame.origin.y;
//    self.timer.frame = f;
//    self.timer.center = c;
    
    if (!wakeupButton) {
        
        return;
        
    }
    
    //footer
    CGRect footerFrame = wakeupButton.frame;
    if (scrollView.contentSize.height < 1) {
        //init phrase
        footerFrame.origin.y = self.view.frame.size.height - footerFrame.size.height;
    }else{
        CGPoint bottomPoint = [self.view convertPoint:CGPointMake(0, scrollView.contentSize.height) fromView:scrollView];
        //NSInteger footerOffset = scrollView.contentSize.height + scrollView.contentInset.top - (scrollView.contentOffset.y + scrollView.frame.size.height);
        footerFrame.origin.y = MAX(bottomPoint.y, self.view.frame.size.height - footerFrame.size.height) ;
    }
    
    wakeupButton.frame = footerFrame;
    
}


#pragma mark - Handle player events
- (void)startPlayCells{
    //Active session
    [[AVManager sharedManager] registerActiveAudioSession];
    
    NSInteger currentPlayingCellIndex = [self seekCurrentCell];
    if (currentPlayingCellIndex < 0) {
        currentPlayingCellIndex = 0;
    }
    if ([AVManager sharedManager].player.playing && [AVManager sharedManager].currentCell) {
        //AVManager has current cell means it is paused
        NSLog(@"AVManager is playing media %ld", (long)currentPlayingCellIndex);
        return;
    }
    
    //get the cell
    if (medias.count > 0) {
        EWMediaViewCell *cell = (EWMediaViewCell *)[tableView_ cellForRowAtIndexPath:[NSIndexPath indexPathForItem:currentPlayingCellIndex inSection:0]];
        if (!cell) {
            cell = (EWMediaViewCell *)[self tableView:tableView_ cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        }
        [[AVManager sharedManager] playForCell:cell];
    }
    
}


- (NSInteger)seekCurrentCell{
    [self initData];
    
    for (NSInteger i=0; i<medias.count; i++) {
        if ([[AVManager sharedManager].media isEqual:medias[i]]) {
            return i;
        }
    }
    
    //if not found, play the first one
    return -1;
}


- (void)playNextCell{
    //check if need to play next
    if (!next){
        NSLog(@"Next is disabled, stop playing next");
        return;
    }
    
    NSInteger currentCellPlaying = [self seekCurrentCell];

    __block EWMediaViewCell *cell;
    NSIndexPath *path;
    NSInteger nextCellIndex = currentCellPlaying + 1;
    
    if (nextCellIndex < medias.count){
        
        //get next cell
        NSLog(@"Play next song (%ld)", (long)nextCellIndex);
        path = [NSIndexPath indexPathForRow:nextCellIndex inSection:0];
        
    }else if(nextCellIndex >= medias.count){
        if ((--loopCount)>0) {
            //play the first if loopCount > 0
            NSLog(@"Looping, %ld loop left", (long)loopCount);
            path = [NSIndexPath indexPathForRow:0 inSection:0];
            
        }else{
            NSLog(@"Loop finished, stop playing");
            //nullify all cell info in avmanager
            cell = nil;
            [AVManager sharedManager].currentCell = nil;
            [AVManager sharedManager].media = nil;
            path = nil;
            return;
        }
        
    }else{
        [NSException raise:@"Unknown state" format:@"Current cell count (%ld) exceeds total medias (%lu)", (long)nextCellIndex, (unsigned long)medias.count];
    }
    
    //delay 3s
    NSLog(@"Delay 3s to play next cell");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMediaPlayInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!next || [AVManager sharedManager].player.playing) {
            return;
        }
        //get cell
        cell = (EWMediaViewCell *)[tableView_ cellForRowAtIndexPath:path];
        if (!cell) {
            NSLog(@"@@@ cell is not visible. %@", path);
            cell = (EWMediaViewCell *)[self tableView:tableView_ cellForRowAtIndexPath:path];
        }
        if (cell) {
            [[AVManager sharedManager] playForCell:cell];
        }else{
            [self playNextCell];
        }
        
    });
    
    //highlight
    if (path) {
        cell = (EWMediaViewCell *)[self tableView:tableView_ cellForRowAtIndexPath:path];
        [tableView_ selectRowAtIndexPath:path animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [tableView_ deselectRowAtIndexPath:path animated:YES];
        });
    }
    
}


#pragma mark - Remote Control Event
- (void)prepareRemoteControlEventsListener{
    
    //register for remote control
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    // Set itself as the first responder
    BOOL success = [self becomeFirstResponder];
    if (success) {
        NSLog(@"APP degelgated %@ remote control events", [self class]);
    }else{
        NSLog(@"@@@ %@ failed to listen remote control events @@@", self.class);
    }
}

- (BOOL)canBecomeFirstResponder{
    return YES;
}

- (void)resignRemoteControlEventsListener{
    
    // Turn off remote control event delivery
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    // Resign as first responder
    BOOL sucess = [self resignFirstResponder];
    
    if (sucess) {
        NSLog(@"%@ resigned as first responder", self.class);
        
    }else{
        NSLog(@"%@ failed to resign first responder", self.class);
    }
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlPlay:{
                NSLog(@"Received remote control: play");
                AVManager *manager = [AVManager sharedManager];
                if (![manager.player play]) {
                    [manager playMedia:manager.media];
                }
            }
                
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                NSLog(@"Received remote control: Previous");
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                NSLog(@"Received remote control: Next");
                break;
                
            case UIEventSubtypeRemoteControlStop:
                NSLog(@"Received remote control Stop");
                [[AVManager sharedManager] stopAllPlaying];
                break;
                
            case UIEventSubtypeRemoteControlPause:
                NSLog(@"Received remote control pause");
                //[[AVManager sharedManager] stopAllPlaying];
                break;
                
            default:
                NSLog(@"Received remote control %ld", (long)receivedEvent.subtype);
                break;
        }
    }
}

#pragma mark - Timer update
- (void)updateTimer{
    NSDate *t = [NSDate date];
    NSString *ts = [t date2timeShort];
    self.timer.text = ts;
    NSTimeInterval time = [t timeIntervalSinceDate:self.task.time];
    
    if (time < 0) {
        time = 0;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"ss"];
    NSString *string = [formatter stringFromDate:t];
    self.seconds.text = [NSString stringWithFormat:@"%@\"", string];
    timePast++;
    self.timeDescription.text = [NSString stringWithFormat:@"%ld minutes past", (unsigned long)time/60];
    
    self.AM.text = [t date2am];
}


@end




