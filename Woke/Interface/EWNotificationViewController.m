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

#define kNotificationCellIdentifier     @"NotificationCellIdentifier"

@interface EWNotificationViewController (){
    NSMutableArray *notifications;
}

@end

@implementation EWNotificationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kNotificationCompleted object:nil];
    
    // Data source
    notifications = [[EWNotificationManager allNotifications] mutableCopy];
    //[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kNotificationCellIdentifier];
    
    //tableview
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(45, 0, 200, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //toolbar
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(OnDone)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *refreshBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
    
    [self.toolbar setItems:@[doneBtn, spacer, refreshBtn] animated:YES];

}

- (void)refresh{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        notifications = [[EWNotificationManager allNotifications] mutableCopy];
    });
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self.tableView reloadData];
    
}

- (BOOL)prefersStatusBarHidden{
    return YES;
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


#pragma mark - TableView
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kNotificationCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kNotificationCellIdentifier];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    //data
    EWNotification *notice = notifications[indexPath.row];
    if (!notice.completed) {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
    }else{
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    BOOL showPic = YES;
    
    //action
    if ([notice.type isEqualToString:kNotificationTypeFriendAccepted]) {
        cell.textLabel.text = @"Friend request accepted";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ has accepted your friends request!", notice.sender];
    }else if ([notice.type isEqualToString:kNotificationTypeFriendRequest]){
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Friend request from %@", notice.sender];
        cell.textLabel.text = @"Friend request received";
    }else if ([notice.type isEqualToString:kNotificationTypeNextTaskHasMedia]){
        cell.textLabel.text = @"Voice received!";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"You have a new voice for tomorrow morning."];
    }else if ([notice.type isEqualToString:kNotificationTypeNotice]){
        cell.textLabel.text = @"Notification";
        cell.detailTextLabel.text = notice.userInfo[@"title"];
        cell.detailTextLabel.text = notice.userInfo[@"content"];
        showPic = NO;
    }else if ([notice.type isEqualToString:kNotificationTypeTimer]){
        cell.textLabel.text = @"It's time to wake up!";
        cell.detailTextLabel.text = @"";
        showPic = NO;
    }else{
        NSLog(@"*** Received unknown type of notification!");
    }
    
    //get sender pic
    if (showPic) {
        cell.imageView.image = [UIImage imageNamed:@"profile"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            EWPerson *p = [[EWPersonStore sharedInstance] getPersonByID:notice.sender];
            UIImage *pic = p.profilePic;
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.imageView.image = pic;
                cell.imageView.alpha = 0;
                [UIView animateWithDuration:0.3 animations:^{
                    cell.imageView.alpha = 1;
                }];
            });
        });
    }else{
        cell.imageView.image = nil;
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    EWNotification *notice = notifications[indexPath.row];
    [EWNotificationManager handleNotification:notice.ewnotification_id];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return notifications.count;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat alpha = indexPath.row%2?0.05:0.06;
    cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:alpha];
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
