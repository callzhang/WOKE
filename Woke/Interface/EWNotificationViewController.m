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
    NSArray *notifications;
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
    // Data source
    notifications = [EWNotificationManager myNotifications];
    //[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kNotificationCellIdentifier];
    
    //tableview
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(45, 0, 200, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //toolbar
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(OnDone)];

    
    [self.toolbar setItems:@[doneBtn] animated:YES];

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
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    //data
    EWNotification *notice = notifications[indexPath.row];
    if (!notice.completed) {
        cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    }
    //action
    if ([notice.type isEqualToString:kNotificationTypeFriendAccepted]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ has accepted your friends request!", notice.sender];
        cell.imageView.image = [UIImage imageNamed:@"profile"];
    }else if ([notice.type isEqualToString:kNotificationTypeFriendRequest]){
        cell.textLabel.text = [NSString stringWithFormat:@"Friend request from %@", notice.sender];
        cell.imageView.image = [UIImage imageNamed:@"profile"];
    }else if ([notice.type isEqualToString:kNotificationTypeNextTaskHasMedia]){
        cell.textLabel.text = [NSString stringWithFormat:@"You have a new voice for tomorrow morning."];
    }else if ([notice.type isEqualToString:kNotificationTypeNotice]){
        cell.textLabel.text = notice.userInfo[@"title"];
        cell.detailTextLabel.text = notice.userInfo[@"content"];
    }else if ([notice.type isEqualToString:kNotificationTypeTimer]){
        cell.textLabel.text = @"It's time to wake up!";
        cell.detailTextLabel.text = @"";
    }else{
        NSLog(@"*** Received unknown type of notification!");
    }
    
    //get sender pic
    if (notice.sender) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            EWPerson *p = [[EWPersonStore sharedInstance] getPersonByID:notice.sender];
            UIImage *pic = p.profilePic;
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.imageView.image = pic;
            });
        });
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

@end
