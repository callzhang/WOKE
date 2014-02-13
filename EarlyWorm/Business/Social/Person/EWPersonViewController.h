//
//  EWPersonViewController.h
//  EarlyWorm
//
//  Created by Lei on 9/5/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EWPerson;
@class EWTaskItem;
@class ShinobiChart;
@class EWStatisticsManager;

@interface EWPersonViewController : EWViewController<UIAlertViewDelegate> {
    NSArray *tasks;
    EWStatisticsManager *stats;
}
//PersonInfoView
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *statement;
@property (weak, nonatomic) IBOutlet UIButton *friends;
@property (weak, nonatomic) IBOutlet UIButton *aveTime;
@property (weak, nonatomic) IBOutlet UIButton *achievements;
@property (weak, nonatomic) IBOutlet UITableView *taskTableView;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (IBAction)extProfile:(id)sender;
- (IBAction)close:(id)sender;
- (IBAction)login:(id)sender;

@property (nonatomic) EWPerson *person;
@end
