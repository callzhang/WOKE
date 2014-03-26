//
//  WakeUpViewController.h
//  EarlyWorm
//
//  Created by Lei Zhang on 7/28/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWPerson, EWMediaItem, EWTaskItem;

@interface EWWakeUpViewController : EWViewController <UIPopoverControllerDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *timer;
@property (weak, nonatomic) IBOutlet UIView *header;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) EWPerson *person;
@property (nonatomic) EWTaskItem *task;

- (EWWakeUpViewController *)initWithTask:(EWTaskItem *)task;
//- (void)playMedia:(id)sender atIndex:(NSIndexPath *)indexPath;
//- (void)startPlayCells;
@end
