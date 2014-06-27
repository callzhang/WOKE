//
//  EWPostWakeUpViewController.m
//  EarlyWorm
//
//  Created by letv on 14-2-17.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWPostWakeUpViewController.h"

#import "EWPerson.h"
#import "EWPersonStore.h"
#import "EWServer.h"
#import "EWCollectionPersonCell.h"
#import "EWTaskItem.h"
#import <QuartzCore/QuartzCore.h>
#import "EWAppDelegate.h"
#import "EWRecordingViewController.h"

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
-(void)initViews;
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
        personArray = [[NSArray alloc] init];
        selectedPersonSet = [[NSMutableSet alloc]initWithCapacity:0];
        time = 0;
        
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initViews];
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initData];
        [collectionView reloadData];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
}

#pragma mark -
#pragma mark - init views and data

-(void)initViews
{
    
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
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundColor = [UIColor clearColor];
    //collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    [collectionView setContentInset:UIEdgeInsetsMake(20, 20, 50, 20)];

    buzzButton.layer.cornerRadius = 5.0;
    buzzButton.layer.masksToBounds= YES;
    buzzButton.layer.borderWidth =1;
    buzzButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    voiceMessageButton.layer.cornerRadius = 10.0;
    voiceMessageButton.layer.masksToBounds= YES;
    voiceMessageButton.layer.borderWidth =1;
    voiceMessageButton.layer.borderColor = [UIColor whiteColor].CGColor;
}

-(void)initData
{

    /*此处应将再上一个controller完成赋值，目前只是举个例子*/
    personArray = [[EWPersonStore sharedInstance] everyone];
    
//    timeLabel.text = [self getTime];
//    unitLabel.text = [self getUnit];
}

#pragma mark -
#pragma mark - get buzzing time & unit -

- (void)setTaskItem:(EWTaskItem *)t{
    taskItem = t;
    time = [[NSDate date] timeIntervalSinceDate:t.time];
    NSLog(@"Time interval is %ld", (long)time);
}


-(NSString *)getTime
{
    
    NSString * timeStr;
    if (time < 60 && time >= 0)
    {
        timeStr = [NSString stringWithFormat:@"%ld",(long)time];
    }
    else if (time >= 60 && time < 3600)
    {
        if (time%60 == 0)
        {
            timeStr = [NSString stringWithFormat:@"%f",time/60.0];
        }
        else
        {
            if (time/60.0 > 10.0)
            {
                timeStr = [NSString stringWithFormat:@"%f",time/60.0];
            }
            timeStr = [NSString stringWithFormat:@"%.1f",time/60.0];
        }
    }
    else
    {
        if (time%3600 == 0)
        {
            timeStr = [NSString stringWithFormat:@"%f",time/3600.0];
        }
        else
        {
            if (time/3600.0 > 10.0)
            {
                timeStr = [NSString stringWithFormat:@"%f",time/3600.0];
            }
            timeStr = [NSString stringWithFormat:@"%.1f",time/3600.0];
        }
    }
    
    return timeStr;
}
-(NSString *)getUnit
{
    
    if (time < 60 && time >= 0)
    {
        if (time == 0 || time == 1)
        {
            return @"second";
        }
        return @"seconds";
    }
    else if( time >= 60 && time < 3600)
    {
        if (time == 60)
        {
            return @"minute";
        }
        return @"minutes";
    }
    else
    {
        if (time == 3600)
        {
            return @"hour";
        }
        return @"hours";
    }
    
    return nil; 
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
        
        [rootViewController dismissViewControllerAnimated:YES completion:NULL];
    }
    else
    {
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Reminder" message:@"Please select wakiees you want to buzz" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
    }
}


-(IBAction)cancel:(id)sender
{

    [rootViewController dismissViewControllerAnimated:YES completion:^{
        [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    }];
}

#pragma mark - UIToolbar




#pragma mark - collection view delegate & dataSource -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [personArray count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)cView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    EWCollectionPersonCell * cell = [cView  dequeueReusableCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier forIndexPath:indexPath];
    [cell applyHexagonMask];
    
    //person
    EWPerson * person = [personArray objectAtIndex:indexPath.row];
    cell.profilePic.image = person.profilePic;
    cell.name = person.name;
    cell.initial.text = person.name.initial;
    return cell;
}

-(void)collectionView:(UICollectionView *)cView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    EWCollectionPersonCell *cell = (EWCollectionPersonCell *)[cView cellForItemAtIndexPath:indexPath];
    EWPerson * person = [personArray objectAtIndex:indexPath.row];
    if ([selectedPersonSet containsObject:person])
    {
        //取消被选中状态
        [selectedPersonSet removeObject:person];
        cell.selectionView.hidden = YES;
    }
    else
    {
        //选中
        [selectedPersonSet addObject:person];
        cell.selectionView.hidden = NO;
    }
    
    //[collectionView reloadData];
    [collectionView setNeedsDisplay];
    
    NSLog(@"%@",person.name);
    
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

#pragma mark -
#pragma mark - memorying warning -

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
