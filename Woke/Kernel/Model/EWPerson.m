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

-(BOOL)isMyFriend
{
    
    if ([self.friends containsObject:me]) {
        return YES;
    }
    return NO;
//    __block BOOL  isMyFriend = false;
//    [self.friends enumerateObjectsUsingBlock:^(EWPerson * person , BOOL * stop){
//        
//        if([person.name isEqualToString:[EWPersonStore me].username])
//        {
//            *stop = YES;
//            isMyFriend = true;
//        }
//        
//     }
//     ];
//    
//    
//    return isMyFriend;
}

//-(BOOL)isEqual:(id)object
//{
//    EWPerson *person = (EWPerson *)object;
//    if ([person.name isEqualToString:self.name]) {
//        return true;
//    }
//    return false;
//    
//}
@end
