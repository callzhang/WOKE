//
//  EWAlarmsViewController.m.h
//  EarlyWorm
//
//  Created by shenslu on 13-7-11.
//  Copyright (c) 2013年 Shens. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "EWAlarmPageView.h"
#import "EWCollectionPersonCell.h"
#import "EWPopupMenu.h"

#define kCollectionViewCellAlert    1001
#define kOptionsAlert               1002
#define kMenuTag                    1003
#define kAlarmPageTag               1004
#define kCollectionViewTag          1005

@import CoreData;

@class EWPerson;
@interface EWAlarmsViewController : EWViewController <UIScrollViewDelegate, EWAlarmItemEditProtocal,  UIAlertViewDelegate, UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegate,NSFetchedResultsControllerDelegate>
{
    NSMutableArray * _alarmPages; //alarm page container
    NSTimer *timer1;
    NSTimer *timer2;

}

@property (nonatomic) NSArray *alarms;
@property (nonatomic) NSArray *tasks;
@property (nonatomic) NSArray *people;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageView;
@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (weak, nonatomic) IBOutlet UIButton *actionBtn;
@property (weak, nonatomic) IBOutlet UIImageView *background;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *alarmloadingIndicator;
@property (weak, nonatomic) IBOutlet UIView *youIndicator;
@property (weak, nonatomic) IBOutlet UILabel *you;
@property (weak, nonatomic) IBOutlet UIButton *youBtn;




//action
- (void)loadScrollViewWithPage:(NSInteger)page;
- (void)scrollViewDidScroll:(UIScrollView *)sender;
// Scroll view move the page defined by page view
- (IBAction)changePage:(id)sender;
- (IBAction)scheduleInitialAlarms:(id)sender;
- (IBAction)mainActions:(id)sender;
- (IBAction)youBtn:(id)sender;

@end
