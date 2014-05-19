//
//  EWAlarmScheduleViewController.h
//  EarlyWorm
//
//  Created by Lei on 10/18/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWAlarmScheduleViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UINavigationBarDelegate>{
    //UITableView *_tableView;
    NSArray *alarms;
    NSArray *tasks;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *navigationBar;
@end
