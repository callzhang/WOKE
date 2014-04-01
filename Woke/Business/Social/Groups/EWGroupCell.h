//
//  EWGroupCell.h
//  EarlyWorm
//
//  Created by Lei on 10/19/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWGroupStore;
@class EWGroup;
@interface EWGroupCell : UITableViewCell
@property (retain, nonatomic) EWGroup * group;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *wakeupTime;
@property (weak, nonatomic) IBOutlet UILabel *description;
@property (weak, nonatomic) IBOutlet UIImageView *groupPic;
@property (weak, nonatomic) IBOutlet UIButton *moreInfo;
@end
