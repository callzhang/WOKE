//
//  EWNotification.m
//  Woke
//
//  Created by Lei on 4/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWNotification.h"
#import "EWPerson.h"
#import "EWMedia.h"

@implementation EWNotification
@dynamic userInfo;
@dynamic lastLocation;
@dynamic importance;

+ (EWNotification *)newNotification {
    NSParameterAssert([NSThread isMainThread]);
    EWNotification *notice = [EWNotification createEntity];
    notice.updatedAt = [NSDate date];
    notice.owner = [EWSession sharedSession].currentUser;
    notice.importance = 0;
    return notice;
}

+ (EWNotification *)newNotificationForMedia:(EWMedia *)media{
    if (!media) {
        return nil;
    }
    
    EWNotification *note = [self newNotification];
    note.type = kNotificationTypeNextTaskHasMedia;
    note.userInfo = @{@"media": media.objectId};
    note.sender = media.author.objectId;
    [EWSync save];
    return note;
}

+ (NSArray *)myNotifications{
    NSArray *notifications = [self allNotifications];
    NSArray *unread = [notifications filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == nil"]];
    return unread;
}

+ (NSArray *)allNotifications{
    NSArray *notifications = [[EWSession sharedSession].currentUser.notifications allObjects];
    NSSortDescriptor *sortCompelet = [NSSortDescriptor sortDescriptorWithKey:@"completed" ascending:NO];
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
    NSSortDescriptor *sortImportance = [NSSortDescriptor sortDescriptorWithKey:@"importance" ascending:NO];
    notifications = [notifications sortedArrayUsingDescriptors:@[sortCompelet,sortImportance, sortDate]];
    return notifications;
}

+ (void)deleteNotification:(EWNotification *)notice{
    [notice deleteEntity];
    [EWSync save];
    NSLog(@"Notification of type %@ deleted", notice.type);
    
}
@end
