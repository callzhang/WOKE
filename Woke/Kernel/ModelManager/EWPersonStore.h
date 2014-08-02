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

#define everyoneCheckTimeOut            600 //10min
#define numberOfRelevantUsers           @100 //number of relevant users returned
#define radiusOfRelevantUsers           @-1  //search radius in kilometers for relevant users
#define kDefaultUsername                    @"New User"
#define kEveryoneLastFetched                @"everyone_last_fetched"
#define kEveryone                           @"everyone"
#define kLastCheckedMe                      @"last_checked_me"
#define kCheckMeInternal                    3600 * 24 * 7 //7 days

#define kCachedFriends                      @"friends"

extern EWPerson *me;

@class EWMediaStore, EWPerson;

@interface EWPersonStore : NSObject

/**
 Possible people that are relevant, fetched from server(TODO)
 */
@property NSArray *everyone;
@property EWPerson *currentUser;
+ (EWPerson *)me;
+ (EWPersonStore *)sharedInstance;
- (EWPerson *)createPersonWithParseObject:(PFUser *)user;
- (EWPerson *)getPersonByObjectID:(NSString *)ID;
- (EWPerson *)getPersonByID:(NSString *)ID;
+ (void)updateMe;

- (EWPerson *)anyone;

//friend
+ (void)requestFriend:(EWPerson *)person;
+ (void)acceptFriend:(EWPerson *)person;
+ (void)unfriend:(EWPerson *)person;
+ (void)getFriendsForPerson:(EWPerson *)person;

+ (BOOL)validatePerson:(EWPerson *)person;


@end
