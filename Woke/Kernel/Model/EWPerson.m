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
@dynamic score;
@dynamic cachedInfo;


#pragma mark - Helper methods
- (BOOL)isMe{
    BOOL isme = NO;
    if ([EWPersonStore me]) {
        isme = [self.username isEqualToString:[EWPersonStore me].username];
    }
    return isme;
}


@end
