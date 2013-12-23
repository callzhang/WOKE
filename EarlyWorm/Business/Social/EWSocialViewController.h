//
//  EWSocialViewController.h
//  EarlyWorm
//
//  Created by shenslu on 13-7-11.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
@class EWPerson;

typedef enum socialViewList{
    socialViewNews,
    socialViewEveryone,
    socialViewGroups,
} TaskGroupList;

@interface EWSocialViewController : UITableViewController<MBProgressHUDDelegate>{
    TaskGroupList socialList;
    EWPerson *me;
    NSArray *friends;
    NSArray *everyone;
    NSInteger nNews;
    NSInteger nAroundMe;
    NSInteger nGroup;
    NSManagedObjectContext *context;
    
    MBProgressHUD *refreshHUD;
}

//@property (retain, nonatomic) UITableView * tableView;
//@property (strong, nonatomic) NSMutableArray *myTasksList;
@end
