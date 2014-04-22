//
//  EWNotificationManager.m
//  Woke
//
//  Created by Lei on 4/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWPerson.h"
#import "EWPersonStore.h"
#import "EWMediaItem.h"
#import "EWMediaStore.h"
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "EWPersonViewController.h"
#import "EWAppDelegate.h"

#define kNextTaskHasMediaAlert      1001
#define kFriendRequestAlert         1002
#define kFriendAcceptedAlert        1003
#define kTimerEventAlert            1004
#define kSystemNoticeAlert          1005

@interface EWNotificationManager()
@property (nonatomic, weak) EWPerson *person;
@property (nonatomic, weak) EWTaskItem *task;
@property (nonatomic, weak) EWMediaItem *media;
@property (nonatomic, weak) EWNotification *notification;
@end

@implementation EWNotificationManager

+ (EWNotificationManager *)sharedInstance{
    static EWNotificationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWNotificationManager alloc] init];
    });
    return manager;
}

+ (NSArray *)myNotifications{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"completed == nil"];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWNotification"];
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"lastmoddate" ascending:NO];
    NSSortDescriptor *sortImportance = [NSSortDescriptor sortDescriptorWithKey:@"importance" ascending:NO];
    request.predicate = predicate;
    request.sortDescriptors = @[sortImportance, sortDate];
    NSArray *notifications = [[EWDataStore currentContext] executeFetchRequestAndWait:request error:NULL];
    return notifications;
}


+ (void)handleNotification:(NSString *)notificationID{
    EWNotification *notification = [EWNotificationManager getNotificationByID:notificationID];
    NSDictionary *userInfo = notification.userInfo;
    [EWNotificationManager sharedInstance].notification = notification;
    
    if ([notification.type isEqualToString:kNotificationTypeNextTaskHasMedia]) {
        
        //do nothing
        //just flash the notification icon
        
    } else if ([notification.type isEqualToString:kNotificationTypeFriendRequest]) {
        
        NSString *personID = userInfo[@"requesterID"];
        EWPerson *person = [[EWPersonStore sharedInstance] getPersonByID:personID];
        [EWNotificationManager sharedInstance].person = person;
        
        //TODO: add image to alert
        //alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Friendship request" message:[NSString stringWithFormat:@"%@ wants to be your friend. Accept?", person.name] delegate:[EWNotificationManager sharedInstance] cancelButtonTitle:@"No" otherButtonTitles:@"Later", @"Yes", nil];
        alert.tag = kFriendRequestAlert;
        [EWNotificationManager sharedInstance].person = person;
        
        [alert show];
        
    } else if ([notification.type isEqualToString:kNotificationTypeFriendAccepted]) {
        
        NSString *personID = userInfo[@"personID"];
        EWPerson *person = [[EWPersonStore sharedInstance] getPersonByID:personID];
        
        //alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Friend accepted" message:[NSString stringWithFormat:@"%@ has accepted your friend request. View profile?", person.name] delegate:[EWNotificationManager sharedInstance] cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        alert.tag = kFriendAcceptedAlert;
        [EWNotificationManager sharedInstance].person = person;
        
        [alert show];
        
    } else if ([notification.type isEqualToString:kNotificationTypeTimer]) {
        
        //do nothing when received
        
    } else if ([notification.type isEqualToString:kNotificationTypeNotice]) {
        
        //TODO
        
    }
}

+ (EWNotification *)getNotificationByID:(NSString *)notificationID{
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWNotification"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ewnotification_id == %@", notificationID];
    request.predicate = predicate;
    NSArray *array = [[EWDataStore currentContext] executeFetchRequestAndWait:request error:NULL];
    if (array.count != 1) {
        NSLog(@"Failed to get notification");
    }
    return array[0];
}


+ (void)clickedNotification:(EWNotification *)notice{
    
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (alertView.tag == kFriendRequestAlert) {
        
        switch (buttonIndex) {
            case 0: //Cancel
                [[EWDataStore currentContext] delete:self.notification];
                [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:NULL];
                break;
                
            case 1: //delay
                
                break;
                
            case 2: //accepted
                [currentUser addFriendsObject:self.person];
                [self.person addFriendsObject:currentUser];
                [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:NULL];
            default:
                break;
        }
        
    }else if (alertView.tag == kFriendAcceptedAlert){
        
        switch (buttonIndex) {
            case 0:
                //Do not view profile, do nothing
                break;
            
            case 1:{//view profile
                EWPersonViewController *controller = [[EWPersonViewController alloc] init];
                controller.person = self.person;
                [rootViewController presentViewControllerWithBlurBackground:controller];
            }
                break;
                
            default:
                break;
        }
        
    }
    
}

@end