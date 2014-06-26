//
//  PersonViewCell.h
//  EarlyWorm
//
//  Created by Lei Zhang on 7/28/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWMediaItem.h"
#import "EWPerson.h"

@class EWMediaSlider, EWMediaItem;

@interface EWMediaViewCell : UITableViewCell
//controller
@property (weak, nonatomic) id controller;

//interface
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *description;
@property (weak, nonatomic) IBOutlet EWMediaSlider *mediaBar;
@property (weak, nonatomic) IBOutlet UIButton *buzzIcon;
@property (weak, nonatomic) IBOutlet UIButton *profilePic;

//action
- (IBAction)play:(id)sender;
- (IBAction)profile:(id)sender;

//content
@property (weak, nonatomic) EWMediaItem *media;
@end
