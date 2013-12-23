//
//  EWAlarmsViewController.m.h
//  EarlyWorm
//
//  Created by shenslu on 13-7-11.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWAlarmPageView.h"

@class EWPerson;
@interface EWAlarmsViewController : EWViewController <UIScrollViewDelegate, EWAlarmItemEditProtocal,  UIAlertViewDelegate> {
    NSMutableArray * _alarmPages; //alarm page container
}

@property (nonatomic) EWPerson *me;
@property (nonatomic) NSArray *alarms;
@property (nonatomic) NSArray *tasks;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *rankLabel;

//other
//@property (nonatomic) BOOL initCompleted;

- (IBAction)OnHistoryButtonTapped:(id)sender;
- (void)loadScrollViewWithPage:(NSInteger)page;
- (void)scrollViewDidScroll:(UIScrollView *)sender;
- (IBAction)changePage:(id)sender;
@end
