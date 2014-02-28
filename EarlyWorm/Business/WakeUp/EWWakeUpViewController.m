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
//#import "EWImageStore.h"
#import "ImageViewController.h"
#import "AVManager.h"
#import "NSDate+Extend.h"
#import "MBProgressHUD.h"

//test
#import "EWPostWakeUpViewController.h"

@interface EWWakeUpViewController (){
    //NSManagedObjectContext *context;
    NSInteger currentCellToPlay;
    NSMutableArray *cellArray;
}
@property (nonatomic, strong) EWShakeManager *shakeManager;
@end

// ShakeManager 代理定义，实现在底部
@interface EWWakeUpViewController (EWShakeManager) <EWShakeManagerDelegate>
@end

@implementation EWWakeUpViewController
@synthesize tableView = tableView_;
@synthesize shakeManager = _shakeManager;
@synthesize imagePopover;
@synthesize medias, person, task;

- (id)init {
    self = [super init];
    if (self) {
        self.navigationItem.title = @"WakeUpView";
        //[self.navigationItem setLeftBarButtonItem:self.editButtonItem];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
        
        
        //notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextCell) name:kAudioPlayerDidFinishPlaying object:nil];
    }
    return self;
}

- (EWWakeUpViewController *)initWithTask:(EWTaskItem *)t{
    self = [self init];
    self.task = t;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //media
    medias = [[NSMutableArray alloc] init];
    //context
    context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
    
    [self initData];
    [self initView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self initData];
}

- (void)initData {
    //song index
    currentCellToPlay = 0;
    cellArray = [[NSMutableArray alloc] init];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    //depend on whether passed in with task or person, the media will populaeed accordingly
    if (task) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWMediaItem"];
            request.predicate = [NSPredicate predicateWithFormat:@"ANY tasks == %@", task];
            request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"createddate" ascending:NO]];
            NSError *err;
            medias = [[context executeFetchRequestAndWait:request error:&err] mutableCopy];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [task addMedias:[NSSet setWithArray:medias]];
                [context saveOnSuccess:^{
                    //
                } onFailure:^(NSError *error) {
                    [NSException raise:@"Unable to update task" format:@"Reason: %@", error.description];
                }];
                [self.tableView reloadData];
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                
            });
        });
    }else{
        medias = [[[EWMediaStore sharedInstance] mediasForPerson:person] mutableCopy];
        NSLog(@"Task didn't pass into view controller");
        [self.tableView reloadData];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }
    //_shakeManager = [[EWShakeManager alloc] init];
    //_shakeManager.delegate = self;
    //[_shakeManager register];
    
    
}

- (void)initView {
    //table view
    tableView_ = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView_.dataSource = self;
    tableView_.delegate = self;
    tableView_.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView_.backgroundColor = [UIColor clearColor];
    tableView_.backgroundView = nil;
    [self.view addSubview:tableView_];
    
    //load MediaViewCell
    UINib *nib = [UINib nibWithNibName:@"EWMediaViewCell" bundle:nil];
    //register the nib
    [self.tableView registerNib:nib forCellReuseIdentifier:@"EWMediaViewCell"];
    //nav btn
    self.navigationController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
    //self.navigationController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Wake Up" style:UIBarButtonItemStylePlain target:self action:@selector(presentPostWakeUpVC)];
    
    UIButton * postWakeUpVCBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    postWakeUpVCBtn.frame = CGRectMake(50, 380, 220, 30);
    [postWakeUpVCBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [postWakeUpVCBtn setTitle:@"PostWakeUpViewController" forState:UIControlStateNormal];
    [postWakeUpVCBtn addTarget:self action:@selector(presentPostWakeUpVC) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:postWakeUpVCBtn];
    
    
}

//testing postWakeUpViewController

-(void)presentPostWakeUpVC
{
    NSLog(@"%s",__func__);
    
    EWPostWakeUpViewController * postWakeUpVC = [[EWPostWakeUpViewController alloc] initWithNibName:@"EWPostWakeUpViewController" bundle:nil];
    
    [self presentViewController:postWakeUpVC animated:YES completion:^{
        //
    }];
}


//refrash data after edited
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)setTask:(EWTaskItem *)t{
    task = t;
    [self initData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_shakeManager unregister];
}

#pragma mark - Functions

- (void)playMedia:(id)sender atIndex:(NSIndexPath *)indexPath {
    
}

- (void)OnCancel{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [[AVManager sharedManager] stopAllPlaying];
    }];
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
    
    static NSString *identifier = @"EWMediaViewCell";
    
    //Use reusable cell or create a new cell
    EWMediaViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[EWMediaViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    //get media item
    EWMediaItem *mi = [medias objectAtIndex:indexPath.row];
    
    //text
    cell.title.text = mi.author.name;
    if (mi.message) {
        cell.description.text = mi.message;
    }else{
        cell.description.text = @"No description for this autio";
    }
    
    
    //date
    cell.date.text = [mi.createddate date2detailDateString];
    
    //set image
    cell.profilePic.image = mi.author.profilePic;
    
    //control
    cell.controller = self;
    cell.tableView = self.tableView;
    
    //mediafile
    cell.media = mi;
    
    //save
    cellArray[indexPath.row] = cell;
    
    
    //play
    
    if (indexPath.row == 0) {
        if (currentCellToPlay == 0 ) {
            [cell mediaPlay:nil];
            currentCellToPlay ++;
        }
        
    }
    
    
    return cell;
}


//remove item
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        EWMediaItem *mi = [medias objectAtIndex:indexPath.row];
        //remove from data source
        [medias removeObject:mi];
        
        //[currentUser removeMediasObject:mi];
        //remove from view with animation
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        //save in bg
        //[context deleteObject:mi];//do not delete the media
        //remove from task relation
        [task removeMediasObject:mi];
        [context saveOnSuccess:^{
            [self initData];//refresh
        } onFailure:^(NSError *error) {
            [NSException raise:@"Unable to delete the row" format:@"Reason: %@", error.description];
        }];
        
    }
    if (editingStyle==UITableViewCellEditingStyleInsert) {
        //do something
    }
}

//when click one item in table, push view to detail page
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 120;
}


//dismiss popover when tap outside
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [imagePopover dismissPopoverAnimated:YES];
    imagePopover = nil;
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

#pragma mark - Notification actions
- (void)nextVoice:(NSNotification *)notification{
    NSString *song = [notification userInfo][@"track"];
    NSLog(@"Received song %@ finish notification", song);
    
}

- (void)playNextCell{
    NSLog(@"Play next song");
    if (currentCellToPlay < medias.count) {
        EWMediaViewCell *cell = cellArray[currentCellToPlay];
        [cell mediaPlay:nil];
        currentCellToPlay++;
    }
}

@end
