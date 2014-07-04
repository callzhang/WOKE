//
//  EWNotificationViewController.m
//  Woke
//
//  Created by Lee on 5/1/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWNotificationViewController.h"
#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWPerson.h"
#import "EWPersonStore.h"
#import "EWNotificationCell.h"

#define kNotificationCellIdentifier     @"NotificationCellIdentifier"

@interface EWNotificationViewController (){
    NSMutableArray *notifications;
}

@end

@implementation EWNotificationViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:kNotificationCompleted object:nil];
    
    // Data source
    notifications = [[EWNotificationManager allNotifications] mutableCopy];
    
    

    
    //tableview
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(45, 0, 200, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    //toolbar
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(OnDone)];

    
    UIBarButtonItem *refreshBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
    [EWUIUtil addTransparantNavigationBarToViewController:self withLeftItem:doneBtn rightItem:refreshBtn];
    
    [self.toolbar setItems:@[doneBtn, spacer, refreshBtn] animated:YES];
    
    UINib *nib = [UINib nibWithNibName:@"EWNotificationCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kNotificationCellIdentifier];

}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)reload{
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI event
- (void)OnDone{
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
}


//- (void)changeMode{
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        if (allNotification) {
//            notifications = [[EWNotificationManager myNotifications] mutableCopy];
//            allBtn.title = @"Unread";
//        }else{
//            notifications = [[EWNotificationManager allNotifications] mutableCopy];
//            allBtn.title = @"All";
//        }
//        allNotification = !allNotification;
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            
//            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//            [self.tableView reloadData];
//            
//        });
//    });
//    
//}

- (void)refresh{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:@"EWNotification"];
    [query whereKey:kParseObjectID notContainedIn:[me.notifications valueForKey:kParseObjectID]];
    [query whereKey:@"owner" equalTo:[PFUser currentUser]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        for (PFObject *PO in objects) {
            EWNotification *notification = (EWNotification *)PO.managedObject;
            NSLog(@"Found new notification %@(%@)", notification.type, notification.objectId);
            notification.owner = [EWPersonStore me];
        }
        notifications = [[EWNotificationManager allNotifications] mutableCopy];
        [self.tableView reloadData];
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
    
}

#pragma mark - TableView
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    EWNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:kNotificationCellIdentifier];
    
    EWNotification *notification = notifications[indexPath.row];
    if (!cell.notification || cell.notification != notification) {
        cell.notification = notification;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    //EWNotificationCell *cell = (EWNotificationCell*)[self tableView:_tableView cellForRowAtIndexPath:indexPath];
    //NSInteger h = cell.height;
    EWNotification *n = notifications[indexPath.row];
    NSString *title = n.userInfo[@"title"];
    NSInteger row = title.length / 30;
    NSInteger h = 63 + row * 20;
    return h;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    EWNotification *notice = notifications[indexPath.row];
    [EWNotificationManager handleNotification:notice.objectId];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return notifications.count;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    //CGFloat alpha = indexPath.row%2?0.05:0.06;
    cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        EWNotification *notice = notifications[indexPath.row];
        [notifications removeObject:notice];
        //remove from view with animation
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [EWNotificationManager deleteNotification:notice];
    }
}

@end
