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

@interface EWMediaViewCell : UITableViewCell
//controller
@property (retain, nonatomic) id controller;
@property (retain, nonatomic) UITableView *tableView;

//interface
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *description;
@property (weak, nonatomic) IBOutlet UISlider *progressBar;
@property (weak, nonatomic) IBOutlet UIButton *like;

//action
- (IBAction)mediaPlay:(id)sender;
- (IBAction)profile:(id)sender;

//content
@property (weak, nonatomic) EWMediaItem *media;
@end
