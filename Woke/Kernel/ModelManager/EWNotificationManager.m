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
#import "EWWakeUpManager.h"
#import "EWServer.h"

#define kNextTaskHasMediaAlert      1011
#define kFriendRequestAlert         1012
#define kFriendAcceptedAlert        1013
#define kTimerEventAlert            1014
#define kSystemNoticeAlert          1015

#define nNotificationToDisplay      9


@interface EWNotificationManager()
@property EWPerson *person;
@property EWTaskItem *task;
@property EWMediaItem *media;
@property (nonatomic)  EWNotification *notification;
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
    NSArray *notifications = [EWNotificationManager allNotifications];
    NSArray *unread = [notifications filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == nil"]];
    return unread;
}

+ (NSArray *)allNotifications{
    NSArray *notifications = [me.notifications allObjects];
    
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
    NSSortDescriptor *sortImportance = [NSSortDescriptor sortDescriptorWithKey:@"importance" ascending:NO];
    notifications = [notifications sortedArrayUsingDescriptors:@[sortImportance, sortDate]];
    return notifications;
}

#pragma mark - CREATE
+ (EWNotification *)newNotification{
    EWNotification *notice = [EWNotification createEntity];
    notice.owner = me;
    notice.importance = 0;
    return notice;
}
//
//+ (EWNotification *)newFriendRequestNotification:(EWPerson *)person{
//    EWNotification *notice = [EWNotificationManager newNotification];
//    notice.receiver = person.objectId;
//    notice.type = kNotificationTypeFriendRequest;
//    [EWNotificationManager sendNotification:notice];
//}


+ (void)handleNotification:(NSString *)notificationID{
    EWNotification *notification = [EWNotificationManager getNotificationByID:notificationID];
    if (!notification) {
        NSLog(@"@@@ Cannot find notification %@", notificationID);
        return;
    }
    NSDictionary *userInfo = notification.userInfo;
    [EWNotificationManager sharedInstance].notification = notification;
    
    if ([notification.type isEqualToString:kNotificationTypeNextTaskHasMedia]) {
        
        [[[UIAlertView alloc] initWithTitle:@"New Voice"
                                    message:@"You've got a new voice for your next morning!"
                                   delegate:[EWNotificationManager sharedInstance]
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil] show];
        
    } else if ([notification.type isEqualToString:kNotificationTypeFriendRequest]) {
        
        //NSString *personID = notification.sender;
        //EWPerson *person = notification.owner;
        
        NSString *personID = notification.sender;
        EWPerson *person = [[EWPersonStore sharedInstance] getPersonByObjectID:personID];
        [EWNotificationManager sharedInstance].person = person;
        
        //TODO: add image to alert
        //alert
        UIAlertView *alert;
        alert = [[UIAlertView alloc] initWithTitle:@"Friendship request"
                                           message:[NSString stringWithFormat:@"%@ wants to be your friend.", person.name]
                                          delegate:[EWNotificationManager sharedInstance]
                                 cancelButtonTitle:@"Don't accept"
                                 otherButtonTitles:@"Accept", @"Profile", nil];
        alert.tag = kFriendRequestAlert;
        [alert show];
        
    } else if ([notification.type isEqualToString:kNotificationTypeFriendAccepted]) {
        
        NSString *personID = notification.sender;
        EWPerson *person = [[EWPersonStore sharedInstance] getPersonByObjectID:personID];
        //EWPerson *person = notification.owner;
        [EWNotificationManager sharedInstance].person = person;
        
        //alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Friend accepted"
                                                        message:[NSString stringWithFormat:@"%@ has accepted your friend request. View profile?", person.name]
                                                       delegate:[EWNotificationManager sharedInstance]
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        alert.tag = kFriendAcceptedAlert;
        [alert show];
        
    } else if ([notification.type isEqualToString:kNotificationTypeTimer]) {
        
        NSString *taskID = userInfo[kPushTaskKey];
        if (!taskID) return;
        EWTaskItem *task = [[EWTaskStore sharedInstance] getTaskByID:taskID];
        [EWNotificationManager sharedInstance].task = task;
        //it's now between alarm timer and before max wake time
        if (!task.completed) {
            if ([[NSDate date] timeIntervalSinceDate:task.time] < kMaxWakeTime) {
                //valid task
                if (![EWWakeUpManager isRootPresentingWakeUpView]) {
                    [EWWakeUpManager handleAlarmTimerEvent:nil];
                }
            } else {
                //passed
                [[[UIAlertView alloc] initWithTitle:@"Past alarm"
                                            message:@"The alarm has passed, try to wake up earlier next timee to find out what people sent to you."
                                           delegate:[EWNotificationManager sharedInstance]
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                //complete task
                task.completed = [NSDate date];
                [EWDataStore save];
                //completed task
                [[EWNotificationManager sharedInstance] finishedNotification:notification];
            }
            
            
        }else{
            //completed task
            [[EWNotificationManager sharedInstance] finishedNotification:notification];
        }
        
    } else if ([notification.type isEqualToString:kNotificationTypeNotice]) {
        //UserInfo
        //->Title
        //->Content
        //->Link
        NSString *title = notification.userInfo[@"title"];
        NSString *body = notification.userInfo[@"content"];
        NSString *link = notification.userInfo[@"link"];
        [[[UIAlertView alloc] initWithTitle:title
                                    message:[NSString stringWithFormat:@"%@\n", body]
                                   delegate:[EWNotificationManager sharedInstance]
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: @"More", nil] show];
        
    }else{
        
        NSLog(@"@@@ unknown type of notification");
    }
}

+ (EWNotification *)getNotificationByID:(NSString *)notificationID{
    
    EWNotification *notification = [EWNotification findFirstByAttribute:kParseObjectID withValue:notificationID];
    if (!notification) {
        //get from server
        PFQuery *q = [PFQuery queryWithClassName:@"EWNotification"];
        [q whereKey:kParseObjectID equalTo:notificationID];
        notification = (EWNotification *)[[q getFirstObject] managedObject];
        [notification refresh];
    }
    return notification;
}


+ (void)clickedNotification:(EWNotification *)notice{
    [EWNotificationManager handleNotification:notice.objectId];
}


#pragma mark - Handle alert
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (alertView.tag == kFriendRequestAlert) {
        
        switch (buttonIndex) {
            case 0: //Cancel
                
                break;
                
            case 1:{ //accepted
                [me addFriendsObject:self.person];
                [self.person addFriendsObject:me];
                [EWNotificationManager sendFriendAcceptNotificationToUser:self.person];
                [rootViewController.view showSuccessNotification:@"Accepted"];
                break;
            }
            case 2:{ //profile
                [rootViewController dismissBlurViewControllerWithCompletionHandler:^{
                    EWPersonViewController *controller = [[EWPersonViewController alloc] initWithPerson:self.person];
                    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
                    [rootViewController presentViewControllerWithBlurBackground:navController];
                }];
                break;
            }
            default:
                break;
        }
        
    }else if (alertView.tag == kFriendAcceptedAlert){
        
        switch (buttonIndex) {
            case 0:
                //Do not view profile, do nothing
                break;
            
            case 1:{//view profile
                [rootViewController dismissBlurViewControllerWithCompletionHandler:^{
                    EWPersonViewController *controller = [[EWPersonViewController alloc] initWithPerson:self.person];
                    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
                    [rootViewController presentViewControllerWithBlurBackground:navController];
                }];
            }
                break;
                
            default:
                break;
        }
        
    }else{
        //
    }
    
    
    [self finishedNotification:self.notification];
    
}

- (void)finishedNotification:(EWNotification *)notice{
    //archieve
    if (!notice.completed) {
        
        notice.completed = [NSDate date];
    }
    if ([notice.type isEqualToString:kNotificationTypeTimer]) {
        //delete
        [EWNotificationManager deleteNotification:notice];
    }
    [EWDataStore save];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCompleted object:notice];
    
    self.notification = nil;
    self.person = nil;
}

+ (void)deleteNotification:(EWNotification *)notice{
    EWNotification *notification = [EWDataStore objectForCurrentContext:notice];
    [[EWDataStore currentContext] deleteObject:notification];
    [EWDataStore save];
    NSLog(@"Notification of type %@ deleted", notification.type);
    
}


#pragma mark - Push
+ (void)sendFriendRequestNotificationToUser:(EWPerson *)person{
    /*
    call the cloud code
    server create a notification object
    notification.type = kNotificationTypeFriendRequest
    notification.sender = me.objectId
    notification.owner = the recerver AND person.notification add this notification
     
     create push:
     title: Friendship request
     body: /name/ is requesting your premission to become your friend.
     userInfo: {User:user.objectId, Type: kNotificationTypeFriendRequest}
     
     */
    
    [PFCloud callFunctionInBackground:@"sendFriendRequestNotificationToUser"
                       withParameters:@{@"sender": me.objectId,
                                        @"owner": person.objectId}
                                block:^(id object, NSError *error)
     {
         if (error) {
             NSLog(@"Failed sending friendship request: %@", error.description);
             EWAlert(@"Network error, please send it later");
         }else{
             [rootViewController.view showSuccessNotification:@"sent"];
         }
     }];
}

+ (void)sendFriendAcceptNotificationToUser:(EWPerson *)person{
    /*
     call the cloud code
     server create a notification object
     notification.type = kNotificationTypeFriendAccepted
     notification.sender = me.objectId
     notification.owner = the recerver AND person.notification add this notification
     
     create push:
     title: Friendship accepted
     body: /name/ has approved your friendship request. Now send her/him a voice greeting!
     userInfo: {User:user.objectId, Type: kNotificationTypeFriendAccepted}
     */
    [PFCloud callFunctionInBackground:@"sendFriendAcceptNotificationToUser"
                       withParameters:@{@"sender": me.objectId, @"owner": person.objectId}
                                block:^(id object, NSError *error)
    {
        if (error) {
            NSLog(@"Failed sending friendship acceptance: %@", error.description);
            EWAlert(@"Network error, please send it later");
        }else{
            [rootViewController.view showSuccessNotification:@"sent"];
        }
        
    }];
}

@end
