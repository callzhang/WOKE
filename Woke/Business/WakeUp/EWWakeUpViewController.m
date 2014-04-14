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

//test
#import "EWPostWakeUpViewController.h"

#define cellIdentifier                  @"EWMediaViewCell"
#define WAKEUP_VIEW_HEADER_HEIGHT       180


@interface EWWakeUpViewController (){
    
    NSMutableArray *medias;
    BOOL next;
    NSInteger loopCount;
    CGRect headerFrame;
    UIButton * postWakeUpVCBtn;
}
@property (nonatomic, strong) EWShakeManager *shakeManager;
@end

// ShakeManager 代理定义，实现在底部
@interface EWWakeUpViewController (EWShakeManager) <EWShakeManagerDelegate>
@end

@implementation EWWakeUpViewController
@synthesize tableView = tableView_;
@synthesize title, timer, header;
@synthesize shakeManager = _shakeManager;
@synthesize person, task;


- (EWWakeUpViewController *)initWithTask:(EWTaskItem *)t{
    self = [self initWithNibName:nil bundle:nil];
    self.task = t;
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //self.navigationItem.title = @"WakeUpView";
        
        //[self.navigationItem setLeftBarButtonItem:self.editButtonItem];
        //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
        
        //notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextCell) name:kAudioPlayerDidFinishPlaying object:nil];
    }
    return self;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //first time loop
    next = YES;
    loopCount = 3;
    
    //origin header frame
    headerFrame = header.frame;
    
    //HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self initData];
    [self initView];
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self scrollViewDidScroll:tableView_];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //position the content
    [self scrollViewDidScroll:tableView_];
    [self.view setNeedsDisplay];
    
    //notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAudioPlayerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewBuzzNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewMediaNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextCell) name:kAudioPlayerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kNewBuzzNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kNewMediaNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    
    //responder to remote control
    [self prepareRemoteControlEventsListener];
    
    NSLog(@"WakeUp view did appear, preparing to play audio");
    if ([AVManager sharedManager].player.playing) {
        //start seeking progress bar
        NSInteger i = [self seekCurrentCell];
        NSLog(@"Player is already playing %ld", (long)i);
        
        //assign cell so the progress can be updated to cell
        EWMediaViewCell *cell = (EWMediaViewCell *)[tableView_ cellForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        [AVManager sharedManager].currentCell = cell;
        
    }else{
        //play
        [self startPlayCells];
    }
    
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self resignRemoteControlEventsListener];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAudioPlayerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewBuzzNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewMediaNotification object:nil];
    
    NSLog(@"WakeUpViewController popped out of view: remote control event listner stopped. Observers removed.");
}

- (void)initData {
    //depend on whether passed in with task or person, the media will populaeed accordingly
    if (task) {
        timer.text = [task.time date2String];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"lastmoddate" ascending:YES];
        medias = [[task.medias allObjects] mutableCopy];
        [medias sortUsingDescriptors:@[sort]];
        [tableView_ reloadData];
        
    }else{
        NSLog(@"Task didn't pass into view controller");
        medias = [[[EWMediaStore sharedInstance] mediasForPerson:person] mutableCopy];
        [tableView_ reloadData];
    }
    
    
    
    //_shakeManager = [[EWShakeManager alloc] init];
    //_shakeManager.delegate = self;
    //[_shakeManager register];
    
    
}

- (void)initView {
    //background
    UIImageView *img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
    [self.view addSubview:img];
    [self.view sendSubviewToBack:img];
    
    //header
    
    
    //table view
    tableView_.dataSource = self;
    tableView_.delegate = self;
    tableView_.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView_.backgroundColor = [UIColor clearColor];
    tableView_.backgroundView = nil;
    tableView_.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView_.contentInset = UIEdgeInsetsMake(120, 0, 80, 0);//the distance of the content to the frame of tableview
    [self.view addSubview:tableView_];
    
    //load MediaViewCell
    UINib *nib = [UINib nibWithNibName:@"EWMediaViewCell" bundle:nil];
    //register the nib
    [tableView_ registerNib:nib forCellReuseIdentifier:cellIdentifier];
    //nav btn
    self.navigationController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
    //self.navigationController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Wake Up" style:UIBarButtonItemStylePlain target:self action:@selector(presentPostWakeUpVC)];
    
    postWakeUpVCBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frame =[UIScreen mainScreen].bounds;
    frame.origin.y = frame.size.height ;
    frame.size.height = 80;
    postWakeUpVCBtn.frame = frame;
    [postWakeUpVCBtn setBackgroundImage:[UIImage imageNamed:@"wake_view_bar"] forState:UIControlStateNormal];
    [postWakeUpVCBtn setTitle:@"Wake Up!" forState:UIControlStateNormal];
    //[postWakeUpVCBtn setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.5]];
    //[postWakeUpVCBtn setContentEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    [postWakeUpVCBtn addTarget:self action:@selector(presentPostWakeUpVC) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:postWakeUpVCBtn];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_shakeManager unregister];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAudioPlayerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewBuzzNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNewMediaNotification object:nil];
    
    NSLog(@"WakeUpViewController deallocated. Observers removed.");
}


- (void)refresh{
    [self initData];
    [tableView_ reloadData];
}




- (void)setTask:(EWTaskItem *)t{
    task = t;
    medias = [[task.medias allObjects] mutableCopy];
    [self initData];
}

#pragma mark - Functions


- (void)OnCancel{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [[AVManager sharedManager] stopAllPlaying];
    }];
}

-(void)presentPostWakeUpVC
{
    //stop music
    [[AVManager sharedManager] stopAllPlaying];
    
    //set wakeup time
    task.completed = [NSDate date];
    [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
        NSLog(@"Failed to save wakeup time for task");
    }];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self scrollViewDidScroll:self.tableView];//prevent header move
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        EWPostWakeUpViewController * postWakeUpVC = [[EWPostWakeUpViewController alloc] initWithNibName:nil bundle:nil];
        postWakeUpVC.taskItem = task;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [self presentViewControllerWithBlurBackground:postWakeUpVC];
        });
    });
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
    EWMediaItem *mi = [medias objectAtIndex:indexPath.row];
    
    //title
    cell.name.text = mi.author.name;
    if (mi.message) {
        cell.description.text = mi.message;
    }else{
        cell.description.text = @"No description for this autio";
    }
    
    //date
    cell.date.text = [mi.createddate date2String];
    
    //set image
    cell.profilePic.image = mi.author.profilePic;
    
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
            [self playNextCell];
        }
        
        //remove from data source
        [medias removeObject:mi];
        
        //remove from view with animation
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        //remove from task relation
        if (task) {
            [task removeMediasObject:mi];
            [EWMediaStore sharedInstance];
            [[EWDataStore currentContext] saveOnSuccess:^{
                [self initData];//refresh
                [rootViewController.view showSuccessNotification:@"Deleted"];
            } onFailure:^(NSError *error) {
                [rootViewController.view showNotification:@"Failed to delete" WithStyle:hudStyleFailed];
            }];
        }else{
            
            for (EWTaskItem *t in mi.tasks) {
                if (t.owner == currentUser || t.pastOwner == currentUser) {
                    NSLog(@"Found task to delete: %@", task.ewtaskitem_id);
                    [t removeMediasObject:mi];
                    [[EWDataStore currentContext] saveOnSuccess:^{
                        [self initData];//refresh
                        [rootViewController.view showSuccessNotification:@"Deleted"];
                    } onFailure:^(NSError *error) {
                        [rootViewController.view showNotification:@"Failed" WithStyle:hudStyleFailed];
                    }];
                }
            }
        }
        
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


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    
    //header
    //NSInteger tableOffsetY = scrollView.contentOffset.y;
    CGRect newFrame = headerFrame;
    newFrame.origin.y = MAX(headerFrame.origin.y - (120 + scrollView.contentOffset.y), -70);
    header.frame = newFrame;
    
    
    
    //footer
    CGRect footerFrame = postWakeUpVCBtn.frame;
    if (scrollView.contentSize.height < 1) {
        //init phrase
        footerFrame.origin.y = self.view.frame.size.height - footerFrame.size.height;
    }else{
        NSInteger footerOffset = scrollView.contentSize.height + scrollView.contentInset.top - (scrollView.contentOffset.y + scrollView.frame.size.height);
        footerFrame.origin.y = MAX(scrollView.frame.size.height + footerOffset, self.view.frame.size.height - footerFrame.size.height) ;
    }
    
    postWakeUpVCBtn.frame = footerFrame;
    
}

#pragma mark - Handle player events
- (void)startPlayCells{
    NSInteger currentPlayingCellIndex = [self seekCurrentCell];
    if (currentPlayingCellIndex < 0) {
        currentPlayingCellIndex = 0;
    }
    if ([AVManager sharedManager].player.playing) {
        //AVManager has current cell means it is paused
        NSLog(@"AVManager is playing media %d", currentPlayingCellIndex);
        return;
    }
    
    //get the cell
    EWMediaViewCell *cell = (EWMediaViewCell *)[tableView_ cellForRowAtIndexPath:[NSIndexPath indexPathForItem:currentPlayingCellIndex inSection:0]];
    if (cell) {
        [[AVManager sharedManager] playForCell:cell];
    }else if(medias.count > 0){
        cell = (EWMediaViewCell *)[self tableView:tableView_ cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
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

    EWMediaViewCell *cell;
    
    currentCellPlaying++;
    
    if (currentCellPlaying < medias.count){
        
        //get next cell
        NSLog(@"Play next song (%ld)", (long)currentCellPlaying);
        NSIndexPath *path = [NSIndexPath indexPathForRow:currentCellPlaying inSection:0];
        cell = (EWMediaViewCell *)[self tableView:tableView_ cellForRowAtIndexPath:path];
        if (!cell) {
            cell = (EWMediaViewCell *)[tableView_ cellForRowAtIndexPath:path];
        }
        
        
    }else if(currentCellPlaying >= medias.count){
        if ((--loopCount)>0) {
            //play the first if loopCount > 0
            NSLog(@"Looping, play (0)");
            cell = (EWMediaViewCell *)[tableView_ cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            
        }else{
            NSLog(@"Loop finished, stop playing");
            //nullify all cell info in avmanager
            [AVManager sharedManager].currentCell = nil;
            [AVManager sharedManager].media = nil;
            next = NO;
        }
        
    }else{
        [NSException raise:@"Unknown state" format:@"Current cell count (%ld) exceeds total medias (%lu)", (long)currentCellPlaying, (unsigned long)medias.count];
    }
    
    //delay 5s
    if ([cell.media.type isEqualToString: kMediaTypeVoice]) {
        NSLog(@"Delay 5s to play next cell");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMediaPlayInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[AVManager sharedManager] playForCell:cell];
        });
    }else if ([cell.media.type isEqualToString: kMediaTypeBuzz]){
        [[AVManager sharedManager] playForCell:cell];
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
                NSLog(@"Received remote control %ld", receivedEvent.subtype);
                break;
        }
    }
}


@end







@implementation EWWakeUpViewController (EWShakeManager)

- (UIView *)currentView {
    return self.view;
}

- (void)EWShakeManagerDidShaked {
    // TODO: Shake 之后做什么：
    // 解锁
}


@end
