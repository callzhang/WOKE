//
//  EWPerson.m
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

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
    if (me) {
        isme = [self.username isEqualToString:me.username];
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
    return [me.cachedInfo[kCachedFriends] containsObject:self.objectId];
}

//wait for friend acceptance
- (BOOL)friendWaiting{
    return [self.cachedInfo[kCachedFriends] containsObject:me.objectId];
}

- (NSString *)genderObjectiveCaseString{
    NSString *str = [self.gender isEqualToString:@"male"]?@"him":@"her";
    return str;
}

@end
