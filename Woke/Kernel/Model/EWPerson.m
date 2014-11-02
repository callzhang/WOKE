//
//  EWPerson.m
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//j

#import "EWPerson.h"
#import "EWPersonManager.h"

@implementation EWPerson
@dynamic lastLocation;
@dynamic profilePic;
@dynamic bgImage;
@dynamic preference;
@dynamic cachedInfo;
@dynamic images;


#pragma mark - Helper methods
- (BOOL)isMe{
    BOOL isme = NO;
    if ([EWSession sharedSession].currentUser) {
        isme = [self.username isEqualToString:[EWSession sharedSession].currentUser.username];
    }
    return isme;
}

-(BOOL)isFriend
{
    BOOL myFriend = self.friendPending;
    BOOL friended = self.friendWaiting;
    
    if (myFriend && friended) {
        return YES;
    }
    return NO;
}

//request pending
- (BOOL)friendPending{
    return [[EWSession sharedSession].currentUser.cachedInfo[kCachedFriends] containsObject:self.objectId];
}

//wait for friend acceptance
- (BOOL)friendWaiting{
    return [self.cachedInfo[kCachedFriends] containsObject:[EWSession sharedSession].currentUser.objectId];
}

- (NSString *)genderObjectiveCaseString{
    NSString *str = [self.gender isEqualToString:@"male"]?@"him":@"her";
    return str;
}

+ (NSArray *)myActivities {
    NSArray *activities = [EWSession sharedSession].currentUser.activities.allObjects;
    return [activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.updatedAt ascending:NO]]];
}

+ (NSArray *)myUnreadNotifications{
    NSArray *notifications = [self myNotifications];
    NSArray *unread = [notifications filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == nil"]];
    return unread;
}

+ (NSArray *)myNotifications{
    NSArray *notifications = [[EWSession sharedSession].currentUser.notifications allObjects];
    NSSortDescriptor *sortCompelet = [NSSortDescriptor sortDescriptorWithKey:@"completed" ascending:NO];
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
    NSSortDescriptor *sortImportance = [NSSortDescriptor sortDescriptorWithKey:@"importance" ascending:NO];
    notifications = [notifications sortedArrayUsingDescriptors:@[sortCompelet,sortImportance, sortDate]];
    return notifications;
}
@end
