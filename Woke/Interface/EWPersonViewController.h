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

@interface EWPersonViewController : UIViewController<UIAlertViewDelegate, UIActionSheetDelegate> {
    //NSArray *tasks;
    EWStatisticsManager *stats;
    NSArray *profileItemsArray;
   

}
//@property (assign,nonatomic)BOOL canSeeFriendsDetail;
@property (strong, nonatomic) IBOutlet UIButton *addFriendButton;
//PersonInfoView
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *statement;
@property (weak, nonatomic) IBOutlet UISegmentedControl *tabView;
@property (weak, nonatomic) IBOutlet UITableView *taskTableView;

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIButton *addFriend;
@property (weak, nonatomic) EWPerson *person;

- (IBAction)extProfile:(id)sender;
- (IBAction)login:(id)sender;
- (IBAction)tabTapped:(UISegmentedControl *)sender;

- (EWPersonViewController *)initWithPerson:(EWPerson *)person;
//- (void)refresh;

@end
