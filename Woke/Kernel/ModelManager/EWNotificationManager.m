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

#define kNextTaskHasMediaAlert      1011
#define kFriendRequestAlert         1012
#define kFriendAcceptedAlert        1013
#define kTimerEventAlert            1014
#define kSystemNoticeAlert          1015


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
    NSArray *notifications = [EWNotificationManager allNotifications];
    NSArray *unread = [notifications filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == nil"]];
    return unread;
}

+ (NSArray *)allNotifications{
    NSArray *notifications = [currentUser.notifications allObjects];
    
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"lastmoddate" ascending:NO];
    NSSortDescriptor *sortImportance = [NSSortDescriptor sortDescriptorWithKey:@"importance" ascending:NO];
    notifications = [notifications sortedArrayUsingDescriptors:@[sortImportance, sortDate]];
    
    return notifications;
}

+ (EWNotification *)newNotification{
    EWNotification *notice = [NSEntityDescription insertNewObjectForEntityForName:@"EWNotification" inManagedObjectContext:[EWDataStore currentContext]];
    [notice assignObjectId];
    notice.sender = currentUser.username;
    notice.importance = 0;
    return notice;
}


+ (void)handleNotification:(NSString *)notificationID{
    EWNotification *notification = [EWNotificationManager getNotificationByID:notificationID];
    NSDictionary *userInfo = notification.userInfo;
    [EWNotificationManager sharedInstance].notification = notification;
    
    if ([notification.type isEqualToString:kNotificationTypeNextTaskHasMedia]) {
        
        [[[UIAlertView alloc] initWithTitle:@"New Voice"
                                    message:@"You got a new voice for your next morning!"
                                   delegate:[EWNotificationManager sharedInstance]
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil] show];
        
    } else if ([notification.type isEqualToString:kNotificationTypeFriendRequest]) {
        
        NSString *personID = notification.sender;
        EWPerson *person = [[EWPersonStore sharedInstance] getPersonByID:personID];
        [EWNotificationManager sharedInstance].person = person;
        
        //TODO: add image to alert
        //alert
        UIAlertView *alert;
        alert = [[UIAlertView alloc] initWithTitle:@"Friendship request"
                                           message:[NSString stringWithFormat:@"%@ wants to be your friend. Accept?", person.name]
                                          delegate:[EWNotificationManager sharedInstance] cancelButtonTitle:@"No"
                                 otherButtonTitles:@"Yes", @"Profile", nil];
        alert.tag = kFriendRequestAlert;
        [alert show];
        
    } else if ([notification.type isEqualToString:kNotificationTypeFriendAccepted]) {
        
        NSString *personID = notification.sender;
        EWPerson *person = [[EWPersonStore sharedInstance] getPersonByID:personID];
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
        if (!task.completed && [[NSDate date] timeIntervalSinceDate:task.time] < kMaxWakeTime && [task.time isEarlierThan:[NSDate date]]) {
            if (![EWWakeUpManager isRootPresentingWakeUpView]) {
                [EWWakeUpManager handleAlarmTimerEvent];
            }
            
            //delete notification?
            
            
        }else{
            [[[UIAlertView alloc] initWithTitle:@"Past alarm"
                                        message:@"The alarm has passed"
                                       delegate:[EWNotificationManager sharedInstance]
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
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
                                    message:[NSString stringWithFormat:@"%@\n(%@)", body, link]
                                   delegate:[EWNotificationManager sharedInstance]
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil] show];
        
    }else{
        
        NSLog(@"@@@ unknown type of notification");
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
                [self finishedNotification:self.notification];
                break;
                
            case 1:{ //accepted
                [currentUser addFriendsObject:self.person];
                [self.person addFriendsObject:currentUser];
                [self finishedNotification:self.notification];
                break;
            }
            case 2:{ //profile
                [rootViewController dismissBlurViewControllerWithCompletionHandler:^{
                    EWPersonViewController *controller = [[EWPersonViewController alloc] initWithPerson:self.person];
                    [rootViewController presentViewControllerWithBlurBackground:controller];
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
                    [rootViewController presentViewControllerWithBlurBackground:controller];
                }];
            }
                break;
                
            default:
                break;
        }
        
        [self finishedNotification:self.notification];
    }else{
        
        [self finishedNotification:self.notification];
    }
    
}

- (void)finishedNotification:(EWNotification *)notice{
    //archieve
    notice.completed = [NSDate date];
    if ([notice.type isEqualToString:kNotificationTypeTimer]) {
        //delete
        [EWNotificationManager deleteNotification:notice];
    }
    [[EWDataStore currentContext] saveOnSuccess:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCompleted object:notice];
    }onFailure:NULL];
    
    self.notification = nil;
    self.person = nil;
}

+ (void)deleteNotification:(EWNotification *)notice{
    EWNotification *notification = [EWDataStore objectForCurrentContext:notice];
    [[EWDataStore currentContext] deleteObject:notification];
    [[EWDataStore currentContext] saveAndWait:NULL];
    NSLog(@"Notification of type %@ deleted", notification.type);
    
}

@end
