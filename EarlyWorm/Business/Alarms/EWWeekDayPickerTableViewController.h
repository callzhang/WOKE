//
//  EWWeekDayPickerTableViewController.h
//  EarlyWorm
//
//  Created by Lei on 9/4/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWWeekDayPickerTableViewController;

@protocol EWWeekdayPickerDelegate <NSObject>

- (void)viewController:(EWWeekDayPickerTableViewController *)viewController didFinishPickDays:(NSString *)days;

@end

@interface EWWeekDayPickerTableViewController : UITableViewController {
    NSArray * _dataSouce;
    NSMutableArray *_selectedDays;
    
}
@property (nonatomic, retain) NSString *repeatString;
@property (nonatomic, weak) id <EWWeekdayPickerDelegate> delegate;

@end
