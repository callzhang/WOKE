//
//  EWPerson.m
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//j

#import "EWPerson.h"
#import "EWPersonStore.h"

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

@end
