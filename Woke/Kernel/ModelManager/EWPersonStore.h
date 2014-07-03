//
//  EWPersonStore.h
//  EarlyWorm
//
//  Created by Lei on 8/16/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWDataStore.h"
#import "EWPerson.h"

#define kDefaultUsername                 @"New User"

extern EWPerson *me;

@class EWMediaStore, EWPerson;

@interface EWPersonStore : NSObject

/**
 Possible people that are relevant, fetched from server(TODO)
 */
@property (nonatomic, strong) NSArray *everyone;
@property EWPerson *currentUser;
+ (EWPerson *)me;
+ (EWPersonStore *)sharedInstance;
- (EWPerson *)createPersonWithParseObject:(PFUser *)user;
- (EWPerson *)getPersonByObjectID:(NSString *)ID;
- (EWPerson *)getPersonByID:(NSString *)ID;


- (EWPerson *)anyone;

//friend
- (void)requestFriend:(EWPerson *)user;
- (void)acceptFriend:(EWPerson *)user;
- (void)unfriend:(EWPerson *)user;

- (void)purgeUserData;
@end
