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
@property (retain, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIPopoverController *imagePopover;
@property (nonatomic) NSMutableArray *medias;
@property (nonatomic) EWPerson *person;
@property (nonatomic) EWTaskItem *task;

- (void)playMedia:(id)sender atIndex:(NSIndexPath *)indexPath;

@end
