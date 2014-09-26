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
#import "EWUIUtil.h"

#import "EWNotificationCell.h"

#define kNotificationCellIdentifier     @"NotificationCellIdentifier"

@interface EWNotificationViewController (){
    NSMutableArray *notifications;
    UIActivityIndicatorView *loading;
}

@end

@implementation EWNotificationViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:kNotificationCompleted object:nil];
    
    // Data source
    notifications = [[EWNotificationManager allNotifications] mutableCopy];
    
    //tableview
    self.tableView.delegate = self;
    self.tableView.dataSource =self;
    self.tableView.contentInset = UIEdgeInsetsMake(2, 0, 200, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.1];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    [EWUIUtil applyAlphaGradientForView:self.tableView withEndPoints:@[@0.13]];
    UINib *nib = [UINib nibWithNibName:@"EWNotificationCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kNotificationCellIdentifier];
    
    //toolbar
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(onDone)];

    loading = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    loading.hidesWhenStopped = YES;
    UIBarButtonItem *refreshBtn = [[UIBarButtonItem alloc] initWithCustomView:loading];
    [EWUIUtil addTransparantNavigationBarToViewController:self withLeftItem:doneBtn rightItem:refreshBtn];
    
     NSInteger nUnread = [EWNotificationManager myNotifications].count;
    if (nUnread != 0){
        self.title = [NSString stringWithFormat:@"Notifications(%ld)",(unsigned long)nUnread];
    }
    else{
        self.title = @"Notifications";
    }
    //refresh
    if (me.isOutDated) {
        [self refresh];
    }
    
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)reload{
    [self.tableView reloadData];
}

#pragma mark - UI event
- (void)onDone{
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
}

- (void)refresh{
    [loading startAnimating];
    
    PFQuery *query = [PFQuery queryWithClassName:@"EWNotification"];
    [query whereKey:kParseObjectID notContainedIn:[me.notifications valueForKey:kParseObjectID]];
    [query whereKey:@"owner" equalTo:[PFUser currentUser]];
    [EWSync findServerObjectInBackgroundWithQuery:query completion:^(NSArray *objects, NSError *error) {
        for (PFObject *PO in objects) {
            EWNotification *notification = (EWNotification *)[PO managedObjectInContext:mainContext];
            NSLog(@"Found new notification %@(%@)", notification.type, notification.objectId);
            notification.owner = me;
        }
        notifications = [[EWNotificationManager allNotifications] mutableCopy];
        [self.tableView reloadData];
        
        //[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [loading stopAnimating];
    }];
}

#pragma mark - TableView
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:kNotificationCellIdentifier];
    
    EWNotification *notification = notifications[indexPath.row];
    if (cell.notification != notification) {
        cell.notification = notification;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWNotification *notification = notifications[indexPath.row];
    NSString *type = notification.type;
    if ([type isEqualToString:kNotificationTypeSystemNotice]) {
        EWNotificationCell *cell = (EWNotificationCell*)[self tableView:_tableView cellForRowAtIndexPath:indexPath];
        return cell.height;
    }
    else {
        return 70;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EWNotification *notice = notifications[indexPath.row];
    [EWNotificationManager handleNotification:notice.objectId];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return notifications.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0];
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        EWNotification *notice = notifications[indexPath.row];
        [notifications removeObject:notice];
        //remove from view with animation
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [EWNotificationManager deleteNotification:notice];
    }
}

@end
