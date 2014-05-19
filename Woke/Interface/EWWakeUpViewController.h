//
//  WakeUpViewController.h
//  EarlyWorm
//
//  Created by Lei Zhang on 7/28/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWPerson, EWMediaItem, EWTaskItem;

@interface EWWakeUpViewController : UIViewController <UIPopoverControllerDelegate, UITableViewDelegate, UITableViewDataSource>
//@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *timer;
@property (weak, nonatomic) IBOutlet UILabel *AM;
@property (weak, nonatomic) IBOutlet UIView *header;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *alphaView;
@property (weak, nonatomic) IBOutlet UILabel *seconds;

@property (nonatomic, weak) EWPerson *person;
@property (nonatomic, weak) EWTaskItem *task;

- (EWWakeUpViewController *)initWithTask:(EWTaskItem *)task;
//- (void)playMedia:(id)sender atIndex:(NSIndexPath *)indexPath;
- (void)startPlayCells;

/**
 Search for cell that has media that has the audioKey that metches the playing URL in AVManager.
 Returns the index of current playing cell.
 */
- (NSInteger)seekCurrentCell;
@end
