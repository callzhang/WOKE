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

- (void)remove {
    DDLogInfo(@"Notification of type %@ deleted", self.type);
    [self deleteEntity];
    [EWSync save];
}
@end
