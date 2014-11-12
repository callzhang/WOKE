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
#import "EWPersonManager.h"
#import "EWMedia.h"
#import "EWMediaManager.h"
//#import "EWTaskItem.h"
//#import "EWTaskManager.h"
#import "EWPersonViewController.h"
#import "EWAppDelegate.h"
#import "EWWakeUpManager.h"
#import "EWServer.h"
#import "EWStatisticsManager.h"

#define kNextTaskHasMediaAlert      1011
#define kFriendRequestAlert         1012
#define kFriendAcceptedAlert        1013
#define kTimerEventAlert            1014
#define kSystemNoticeAlert          1015

#define nNotificationToDisplay      9


@interface EWNotificationManager()
@property EWPerson *person;
@property EWTaskItem *task;
@property EWMedia *media;
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



#pragma mark - CREATE
+ (void)handleNotification:(NSString *)notificationID{
    EWNotification *notification = [EWNotificationManager getNotificationByID:notificationID];
    if (!notification) {
        DDLogError(@"@@@ Cannot find notification %@", notificationID);
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
        EWPerson *person = [[EWPersonManager sharedInstance] getPersonByServerID:personID];
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
        EWPerson *person = [[EWPersonManager sharedInstance] getPersonByServerID:personID];
        //EWPerson *person = notification.owner;
        [EWNotificationManager sharedInstance].person = person;
        
        //update cache
        [EWStatisticsManager updateCacheWithFriendsAdded:@[person.serverID]];
        
        //alert
        if (notification.completed) {
            EWPersonViewController *controller = [[EWPersonViewController alloc] initWithPerson:person];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
            [rootViewController presentWithBlur:navController withCompletion:^{
                //
            }];
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Friend accepted"
                                                            message:[NSString stringWithFormat:@"%@ has accepted your friend request. View profile?", person.name]
                                                           delegate:[EWNotificationManager sharedInstance]
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
            alert.tag = kFriendAcceptedAlert;
            [alert show];
        }
        
        
        
    } else if ([notification.type isEqualToString:kNotificationTypeSystemNotice]) {
        //UserInfo
        //->Title
        //->Content
        //->Link
        NSString *title = notification.userInfo[@"title"];
        NSString *body = notification.userInfo[@"content"];
        //NSString *link = notification.userInfo[@"link"];
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
    
    EWNotification *notification = (EWNotification *)[EWSync managedObjectWithClass:@"EWNotification" withID:notificationID];
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
                [[EWSession sharedSession].currentUser addFriendsObject:self.person];
                [self.person addFriendsObject:[EWSession sharedSession].currentUser];
                [EWNotificationManager sendFriendAcceptNotificationToUser:self.person];
                [rootViewController.view showSuccessNotification:@"Accepted"];
                break;
            }
            case 2:{ //profile
                EWPersonViewController *controller = [[EWPersonViewController alloc] initWithPerson:self.person];
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
                [rootViewController presentWithBlur:navController withCompletion:^{
                    //
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
                EWPersonViewController *controller = [[EWPersonViewController alloc] initWithPerson:self.person];
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
                [rootViewController presentWithBlur:navController withCompletion:^{
                    //
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
    [EWSync save];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCompleted object:notice];
    
    self.notification = nil;
    self.person = nil;
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
                       withParameters:@{@"sender": [EWSession sharedSession].currentUser.objectId,
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
                       withParameters:@{@"sender": [EWSession sharedSession].currentUser.objectId, @"owner": person.objectId}
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
