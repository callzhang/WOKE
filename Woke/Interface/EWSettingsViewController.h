//
//  EWSettingsViewController.h
//  EarlyWorm
//
//  Created by shenslu on 13-7-28.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWPerson.h"
#import "EWRingtoneSelectionViewController.h"
#import "EWViewController.h"
typedef enum {
    settingGroupProfile,
    settingGroupPreference,
    settingGroupAbout
} settingGroupList;

@interface EWSettingsViewController : EWViewController <EWRingtoneSelectionDelegate, UIAlertViewDelegate> {
    UITableView *_tableView;
    settingGroupList settingGroup;
    NSString *cellIdentifier;
    //NSManagedObjectContext *context;
    //NSDictionary *options;
    //preference
    EWRingtoneSelectionViewController *ringtoneVC;
}

@end
