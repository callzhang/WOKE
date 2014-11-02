//
//  EWPostWakeUpViewController.m
//  EarlyWorm
//
//  Created by letv on 14-2-17.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWPostWakeUpViewController.h"

#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWServer.h"
#import "EWCollectionPersonCell.h"
#import "EWTaskItem.h"
#import <QuartzCore/QuartzCore.h>
#import "EWAppDelegate.h"
#import "EWRecordingViewController.h"
#import "EWTaskManager.h"

#import "EWUIUtil.h"
#import "EWAlarmManager.h"
NSString * const selectAllCellId = @"selectAllCellId";
@interface EWPostWakeUpViewController ()
{
    //__weak IBOutlet UIImageView * backGroundImage;
    
//    __weak IBOutlet UILabel * timeLabel;
//    __weak IBOutlet UILabel * unitLabel;
//    __weak IBOutlet UIView *timerView;
    
//    __weak IBOutlet UILabel *markTitle;
    __weak IBOutlet UILabel * markALabel;
    __weak IBOutlet UILabel * markBLabel;
    //__weak IBOutlet UIImageView * barImageView;
    
    NSInteger time;
}

@property(nonatomic,strong)NSMutableSet * selectedPersonSet;

//init views and data
-(void)initData;

//click action
-(IBAction)wakeEm:(id)sender;
-(IBAction)buzzEm:(id)sender;
-(IBAction)cancel:(id)sender;

@end

@implementation EWPostWakeUpViewController

@synthesize personArray;
@synthesize taskItem;
@synthesize selectedPersonSet;

-(void)dealloc
{
    personArray = nil;
    taskItem = nil;
    personArray = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        personArray = [NSArray new];
        selectedPersonSet = [NSMutableSet new];
        time = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UICollectionViewFlowLayout *flowLayout=[[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    if (!iPhone5)
    {
        collectionView.frame = CGRectMake(34, 242, 253, 171);
        
        //markBLabel.frame = CGRectMake(0, 205, 320, 36);
        //barImageView.frame = CGRectMake(0, 413, 320, 67);
    }
    
    //Collection view
    //[collectionView registerClass:[EWCollectionPersonCell class] forCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier];
    UINib *nib = [UINib nibWithNibName:@"EWCollectionPersonCell" bundle:nil];
    [collectionView registerNib:nib forCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier];
    [collectionView registerNib:nib forCellWithReuseIdentifier:selectAllCellId];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundColor = [UIColor clearColor];
    [collectionView setContentInset:UIEdgeInsetsMake(20, 20, 150, 20)];
    //    [collectionView setAllowsMultipleSelection:YES];
    
    [EWUIUtil applyAlphaGradientForView:collectionView withEndPoints:@[@0.1, @0.8]];
    
    
    buzzButton.layer.cornerRadius = 4.0;
    buzzButton.layer.masksToBounds= YES;
    buzzButton.layer.borderWidth = 1;
    buzzButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
    buzzButton.layer.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    buzzButton.imageEdgeInsets = UIEdgeInsetsMake(10, 5, 10, 5);
    
    voiceMessageButton.layer.cornerRadius = 4.0;
    voiceMessageButton.layer.masksToBounds= YES;
    voiceMessageButton.layer.borderWidth = 1;
    voiceMessageButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
    voiceMessageButton.layer.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    voiceMessageButton.imageEdgeInsets = UIEdgeInsetsMake(10, 5, 10, 5);

    //data
    [self initData];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //[self initData];
    //[collectionView reloadData];
}

#pragma mark -
#pragma mark - init views and data

-(void)initData
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    //take the cached value or a new value
    [[EWPersonManager sharedInstance] getEveryoneInBackgroundWithCompletion:^{
        NSArray *allPerson = [EWPerson findAllWithPredicate:[NSPredicate predicateWithFormat:@"score > 0"] inContext:mainContext];
        personArray = [allPerson sortedArrayUsingComparator:^NSComparisonResult(EWPerson *obj1, EWPerson *obj2) {
            NSDate *time1 = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:obj1]?:[[NSDate date] timeByAddingMinutes:60];
            NSDate *time2 = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:obj2]?:[[NSDate date] timeByAddingMinutes:60];
            if ([time1 isEarlierThan:time2]) {
                return NSOrderedAscending;
            }else if ([time2 isEarlierThan:time1]){
                return NSOrderedDescending;
            }else{
                return NSOrderedSame;
            }
        }];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        //refresh
        [collectionView reloadData];
    }];
}


#pragma mark -
#pragma mark - get buzzing time & unit -

- (void)setTaskItem:(EWTaskItem *)t{
    taskItem = t;
    NSLog(@"Time interval is %@", [taskItem.time timeLeft]);
}

#pragma mark -
#pragma mark - IBAction -

-(IBAction)wakeEm:(id)sender{
    if ([selectedPersonSet count] != 0){
        EWRecordingViewController *controller = [[EWRecordingViewController alloc] initWithPeople:selectedPersonSet];
        [self presentViewControllerWithBlurBackground:controller];
    }
    else{
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Reminder" message:@"Please select wakiees you want to wake up" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
}

- (IBAction)buzzEm:(id)sender{
    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    if ([selectedPersonSet count] != 0)
    {
        
        for (EWPerson *person in selectedPersonSet) {
            
            //======== buzz ========
            double delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [EWServer buzz:@[person]];
            });
        }
        
        [rootViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    }
    else
    {
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Reminder" message:@"Please select wakiees you want to buzz" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
}


-(IBAction)cancel:(id)sender
{

    [rootViewController dismissBlurViewControllerWithCompletionHandler:^{
        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    }];
}

#pragma mark - UIToolbar




#pragma mark - collection view delegate & dataSource -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [personArray count]+1;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)cView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EWCollectionPersonCell * cell ;
    
    if (indexPath.row == [personArray count]) {
        //last one, select all
        cell = [cView  dequeueReusableCellWithReuseIdentifier:selectAllCellId forIndexPath:indexPath];
        [cell applyHexagonMask];
        cell.image.alpha = 0.1;
        cell.initial.text = @"ALL";
        cell.initial.alpha = 1;
        cell.name.text = @"";
        cell.info.text = @"";
        
        return cell;
    }

    cell.showName = YES;
    
    cell = [cView  dequeueReusableCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier forIndexPath:indexPath];
    [cell applyHexagonMask];

    //person
    EWPerson * person = [personArray objectAtIndex:indexPath.row];
    cell.person = person;
    return cell;
}

-(void)collectionView:(UICollectionView *)cView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [personArray count]) {
        [self selectAllCell];
        return;
    }
    
    EWCollectionPersonCell *cell = (EWCollectionPersonCell *)[cView cellForItemAtIndexPath:indexPath];
    EWPerson * person = [personArray objectAtIndex:indexPath.row];
    if ([selectedPersonSet containsObject:person])
    {
        //取消被选中状态
        [selectedPersonSet removeObject:person];
        cell.selection.hidden = YES;
    }
    else
    {
        //选中
        [selectedPersonSet addObject:person];
        cell.selection.hidden = NO;
    }
    
    //[collectionView reloadData];
    [collectionView setNeedsDisplay];
    
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kCollectionViewCellWidth, kCollectionViewCellHeight);
}

//reload data

-(void)reloadData
{
    NSLog(@"%s",__func__);
    
    [collectionView reloadData];
}
-(void)selectAllCell
{
    BOOL selectAll = YES;
    if (selectedPersonSet.count == personArray.count) {
        //all selected, deselect all
        selectAll = NO;
    }
    for (int i =0 ; i < [personArray count]; i++) {
        NSIndexPath *selectedPath = [NSIndexPath indexPathForRow:i inSection:0];
        EWCollectionPersonCell *cell = (EWCollectionPersonCell *)[collectionView cellForItemAtIndexPath:selectedPath];
        EWPerson * person = [personArray objectAtIndex:selectedPath.row];
        
        if (selectAll)
        {
            [selectedPersonSet addObject:person];
            cell.selection.hidden = NO;
        }
        else {
            [selectedPersonSet removeObject:person];
            cell.selection.hidden = YES;
        }
    }
}

#pragma mark - memorying warning -

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
