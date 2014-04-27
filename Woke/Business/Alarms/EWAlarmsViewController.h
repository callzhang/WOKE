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

@import CoreData;

@class EWPerson;
@interface EWAlarmsViewController : EWViewController <UIScrollViewDelegate, EWAlarmItemEditProtocal,  UIAlertViewDelegate, UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,NSFetchedResultsControllerDelegate>
{
    NSMutableArray * _alarmPages; //alarm page container
    NSTimer *timer1;
    NSTimer *timer2;

}

@property (nonatomic) NSArray *alarms;
@property (nonatomic) NSArray *tasks;
@property (nonatomic) NSArray *people;

@property(nonatomic,retain)EWPopupMenu *meun;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageView;
@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (weak, nonatomic) IBOutlet UIButton *actionBtn;



//action
- (void)loadScrollViewWithPage:(NSInteger)page;
- (void)scrollViewDidScroll:(UIScrollView *)sender;
// Scroll view move the page defined by page view
- (IBAction)changePage:(id)sender;
- (IBAction)scheduleInitialAlarms:(id)sender;
//- (IBAction)profile:(id)sender;
- (IBAction)mainActions:(id)sender;


@end
