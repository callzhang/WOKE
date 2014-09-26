//
//  EWMyFriendsViewController.h
//  Woke
//
//  Created by mq on 14-6-22.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWViewController.h"
@class EWPerson;
@interface EWMyFriendsViewController : UIViewController

-(id)initWithPerson:(EWPerson *)person cellSelect:(BOOL)cellSelect;
-(id)initWithPerson:(EWPerson *)person;
@property EWPerson *person;
@property (strong, nonatomic) IBOutlet UISegmentedControl *tabView;

@property (strong, nonatomic) IBOutlet UICollectionView *friendsCollectionView;
@property (strong, nonatomic) IBOutlet UITableView *friendsTableView;
- (IBAction)tabValueChange:(id)sender;
@end
