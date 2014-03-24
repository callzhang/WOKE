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

@interface EWPostWakeUpViewController ()
{
    IBOutlet UIImageView * backGroundImage;
    
    IBOutlet UIButton * wakeThemBtn;
    IBOutlet UIButton * doneBtn;
    
    IBOutlet UILabel * timeLabel;
    IBOutlet UILabel * unitLabel;
    
    IBOutlet UILabel * markALabel;
    IBOutlet UILabel * markBLabel;
    
    IBOutlet UIImageView * barImageView;
    
    NSInteger time;
}

@property(nonatomic,strong)NSMutableSet * selectedPersonSet;

//init views and data
-(void)initViews;
-(void)initData;

//click action
-(IBAction)wakeAllAction:(id)sender;
-(IBAction)doneAction:(id)sender;

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
    [self initData];
}

#pragma mark -
#pragma mark - init views and data

-(void)initViews
{
    NSLog(@"%s",__func__);
    
    UICollectionViewFlowLayout *flowLayout=[[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    if (!iPhone5)
    {
        collectionView.frame = CGRectMake(34, 242, 253, 171);
        
        wakeThemBtn.frame = CGRectMake(20, 427, 127, 39);
        doneBtn.frame = CGRectMake(173, 427, 127, 39);
        
        markALabel.hidden = YES;
        
        markBLabel.frame = CGRectMake(0, 205, 320, 36);
        barImageView.frame = CGRectMake(0, 413, 320, 67);
    }
    
    //Collection view
    [collectionView registerClass:[EWCollectionPersonCell class] forCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundColor = [UIColor clearColor];
    //collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    [collectionView setContentInset:UIEdgeInsetsMake(20, 20, 20, 20)];
    
    //bar area at the button
    wakeThemBtn.layer.cornerRadius = 5;
    wakeThemBtn.layer.borderWidth = 1.0f;
    wakeThemBtn.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.8f].CGColor;
    wakeThemBtn.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
    doneBtn.layer.cornerRadius = 5;
    doneBtn.layer.borderWidth = 1.0f;
    doneBtn.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.8f].CGColor;
    doneBtn.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
    barImageView.layer.shadowColor = [UIColor blackColor].CGColor;
    barImageView.layer.shadowOffset = CGSizeMake(0, -3);
    barImageView.layer.shadowOpacity = 1.0f;
    
    
    UIView * timerView = [[UIView alloc] initWithFrame:CGRectMake(100, 95, 110, 110)];
    timerView.layer.cornerRadius = 55;
    timerView.backgroundColor = [UIColor whiteColor];
    timerView.layer.borderWidth = 1.0f;
    timerView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.8f].CGColor;
    timerView.backgroundColor = [UIColor whiteColor];
    timerView.alpha = 0.4;
    [self.view addSubview:timerView];
}

-(void)initData
{
    NSLog(@"%s",__func__);

    /*此处应将再上一个controller完成赋值，目前只是举个例子*/
    personArray = [[EWPersonStore sharedInstance] everyone];
    
    //获取唤醒时间及单位
    
    /*此处写入两段时间的差值.例如：time = time1 - time2;*/
    // coding ...
    
    timeLabel.text = [self getTime];
    unitLabel.text = [self getUnit];
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
    NSLog(@"%s",__func__);
    NSString * timeStr;
    if (time < 60 && time >= 0)
    {
        timeStr = [NSString stringWithFormat:@"%ld",(long)time];
        return timeStr;
    }
    else if (time >= 60 && time < 3600)
    {
        if (time%60 == 0)
        {
            timeStr = [NSString stringWithFormat:@"%f",time/60.0];
            return timeStr;
        }
        else
        {
            if (time/60.0 > 10.0)
            {
                timeStr = [NSString stringWithFormat:@"%f",time/60.0];
                return timeStr;
            }
            timeStr = [NSString stringWithFormat:@"%.1f",time/60.0];
            return timeStr;
        }
    }
    else
    {
        if (time%3600 == 0)
        {
            timeStr = [NSString stringWithFormat:@"%f",time/3600.0];
            return timeStr;
        }
        else
        {
            if (time/3600.0 > 10.0)
            {
                timeStr = [NSString stringWithFormat:@"%f",time/3600.0];
                return timeStr;
            }
            timeStr = [NSString stringWithFormat:@"%.1f",time/3600.0];
            return timeStr;
        }
    }
    
    return nil;
}
-(NSString *)getUnit
{
    NSLog(@"%s",__func__);
    
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

-(IBAction)wakeAllAction:(id)sender
{
    NSLog(@"%s",__func__);
    
    if ([selectedPersonSet count] != 0)
    {
        
        for (EWPerson *person in selectedPersonSet) {
            
            //======== buzz ========
            double delayInSeconds = 3.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [EWServer buzz:@[person]];
            });
            
            //======= end of buzz ======
        }
        
        [rootViewController dismissViewControllerAnimated:YES completion:^{
            //
        }];
    }
    else
    {
        NSLog(@"no person selected");
        
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"提醒" message:@"请选择要被唤醒的朋友" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alertView show];
    }
}


-(IBAction)doneAction:(id)sender
{
    NSLog(@"%s",__func__);
    
    [rootViewController dismissViewControllerAnimated:YES completion:^{
        //
    }];
}


#pragma mark -
#pragma mark - collection view delegate & dataSource -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [personArray count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)cView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    EWCollectionPersonCell * cell = [cView  dequeueReusableCellWithReuseIdentifier:kCollectionViewCellPersonIdenfifier forIndexPath:indexPath];
    if (!cell) {
        NSLog(@"Collection view cell needs init");
        
    }
    //person
    EWPerson * person = [personArray objectAtIndex:indexPath.row];
    cell.profilePic.image = person.profilePic;
    cell.name.text = person.name;
    
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
        cell.maskView.hidden = YES;
    }
    else
    {
        //选中
        [selectedPersonSet addObject:person];
        cell.maskView.hidden = NO;
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
