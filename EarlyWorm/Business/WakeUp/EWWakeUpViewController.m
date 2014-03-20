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
    //NSManagedObjectContext *context;
    NSInteger currentCell;
    NSMutableArray *medias;
    NSMutableDictionary *buzzers;
    NSMutableArray *listOfBuzzAndMedia; //list with time
    BOOL loopAllCells;
    CGRect headerFrame;
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
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
        
        //notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextCell) name:kAudioPlayerDidFinishPlaying object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kNewBuzzNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kNewMediaNotification object:nil];
    }
    return self;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //first time loop
    loopAllCells = YES;
    
    //origin header frame
    headerFrame = header.frame;
    
    //context
    //context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
    
    [self initData];
    [self initView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //[self initData];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [tableView_ reloadData];
    //play
    [self startPlayCells];
}

- (void)initData {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    //depend on whether passed in with task or person, the media will populaeed accordingly
    if (task) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            medias = [[task.medias allObjects] mutableCopy];
            buzzers = [task.buzzers mutableCopy];
            listOfBuzzAndMedia = [NSMutableArray arrayWithArray:medias];
            [listOfBuzzAndMedia addObjectsFromArray:[buzzers allKeys]];
            
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [tableView_ reloadData];
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                
            });
        });
    }else{
        NSLog(@"Task didn't pass into view controller");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            medias = [[[EWMediaStore sharedInstance] mediasForPerson:person] mutableCopy];
            dispatch_async(dispatch_get_main_queue(), ^{
                [tableView_ reloadData];
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            });
        });
        
        
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
    
    UIButton * postWakeUpVCBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frame =[UIScreen mainScreen].bounds;
    frame.origin.y = frame.size.height - 80;
    frame.size.height = 80;
    postWakeUpVCBtn.frame = frame;
    [postWakeUpVCBtn setBackgroundImage:[UIImage imageNamed:@"wake_view_bar"] forState:UIControlStateNormal];
    [postWakeUpVCBtn setTitle:@"Wake Up!" forState:UIControlStateNormal];
    //[postWakeUpVCBtn setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.5]];
    //[postWakeUpVCBtn setContentEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    [postWakeUpVCBtn addTarget:self action:@selector(presentPostWakeUpVC) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:postWakeUpVCBtn];
    //tableView_.tableFooterView = postWakeUpVCBtn;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_shakeManager unregister];
}


- (void)refresh{
    [self initData];
    [tableView_ reloadData];
}


-(void)presentPostWakeUpVC
{
    //stop music
    [[AVManager sharedManager] stopAllPlaying];
    NSLog(@"%s",__func__);
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        EWPostWakeUpViewController * postWakeUpVC = [[EWPostWakeUpViewController alloc] initWithNibName:@"EWPostWakeUpViewController" bundle:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self presentViewController:postWakeUpVC animated:YES completion:^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                
            }];
        });
    });
}

- (void)setTask:(EWTaskItem *)t{
    task = t;
    [self initData];
}

#pragma mark - Functions

- (void)startPlayCells{
    currentCell = 0;
    EWMediaViewCell *cell = (EWMediaViewCell *)[tableView_ cellForRowAtIndexPath:[NSIndexPath indexPathForItem:currentCell inSection:0]];
    if (cell) {
        [[AVManager sharedManager] playForCell:cell];
    }
    
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
    
    
    //Use reusable cell or create a new cell
    EWMediaViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    //EWMediaViewCell *cell = [[EWMediaViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    //get media item
    EWMediaItem *mi = [medias objectAtIndex:indexPath.row];
    
    //title
    cell.title.text = mi.author.name;
    if (mi.message) {
        cell.description.text = mi.message;
    }else{
        cell.description.text = @"No description for this autio";
    }
    
    //type
    if ([mi.type isEqualToString:kMediaType]) {
        //media
        cell.mediaBar.type = kMediaType;
    }else if ([mi.type isEqualToString:kBuzzType]){
        //buzz
        cell.mediaBar.type = kBuzzType;
    }else{
        cell.mediaBar.type = kMediaType;
    }
    
    //date
    cell.date.text = [mi.createddate date2String];
    
    //set image
    cell.profilePic.image = mi.author.profilePic;
    
    //control
    cell.controller = self;
    
    //mediafile
    cell.media = mi;
    
    
    return cell;
}


//remove item
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        EWMediaItem *mi = [medias objectAtIndex:indexPath.row];
        //remove from data source
        [medias removeObject:mi];
        
        //remove from view with animation
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        //remove from task relation
        if (task) {
            [task removeMediasObject:mi];
        [context saveOnSuccess:^{
            [self initData];//refresh
            [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
        } onFailure:^(NSError *error) {
            [NSException raise:@"Unable to delete the row" format:@"Reason: %@", error.description];
        }];
        }else{
            /*
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWTaskItem"];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ IN medias && (owner == %@ || pastOwner == %@)", mi, currentUser, currentUser];
            request.predicate = predicate;
            [context executeFetchRequest:request onSuccess:^(NSArray *results) {
                if (results.count==1) {
                    NSLog(@"get task: %d", results.count);
                    EWTaskItem *t = results[0];
                    [t removeMediasObject:mi];
                    [context saveOnSuccess:^{
                        //
                    } onFailure:^(NSError *error) {
                        //
                    }];

                }else{
                    EWAlert(@"Can't locate the task, operation abord");
                }
                [tableView_ reloadData];
            } onFailure:^(NSError *error) {
                NSLog(@"%@", error);
            }];*/
            for (EWTaskItem *t in mi.tasks) {
                if (t.owner == currentUser || t.pastOwner == currentUser) {
                    NSLog(@"Found task to delete: %@", task.ewtaskitem_id);
                    [t removeMediasObject:mi];
                    [context saveOnSuccess:^{
                        [self initData];//refresh
                        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
                        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                        hud.mode = MBProgressHUDModeCustomView;
                        hud.labelText = @"Sent";
                        [hud hide:YES afterDelay:1.5];
                    } onFailure:^(NSError *error) {
                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
                        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                        hud.mode = MBProgressHUDModeCustomView;
                        hud.labelText = @"Failed";
                        [hud hide:YES afterDelay:1.5];
                    }];
                }
            }
        }
    }
    if (editingStyle==UITableViewCellEditingStyleInsert) {
        //do something
    }
}

//when click one item in table, push view to detail page
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Media clicked");
    [[AVManager sharedManager] playForCell:[tableView cellForRowAtIndexPath:indexPath]];
    loopAllCells = NO;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView.contentOffset.y > -120) {
        CGRect newFrame = headerFrame;
        newFrame.origin.y = headerFrame.origin.y - (120 + scrollView.contentOffset.y);
        header.frame = headerFrame;
        [self.view setNeedsDisplay];
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

#pragma mark - Notification actions
- (void)nextVoice:(NSNotification *)notification{
    NSString *song = [notification userInfo][@"track"];
    NSLog(@"Received song %@ finish notification", song);
    
}

- (void)playNextCell{
    NSLog(@"Play next song");
    if (currentCell < medias.count) {
        EWMediaViewCell *cell = (EWMediaViewCell *)[tableView_ cellForRowAtIndexPath:[NSIndexPath indexPathForRow:++currentCell inSection:0]];
        if (!cell) {
            loopAllCells = NO;
        }else{
            
            [[AVManager sharedManager] playForCell:cell];
        }
    }
}

@end
