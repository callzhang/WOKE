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

#define everyoneCheckTimeOut            3600 //1hr
#define numberOfRelevantUsers           @100 //number of relevant users returned
#define radiusOfRelevantUsers           @-1  //search radius in kilometers for relevant users
#define kDefaultUsername                    @"New User"
#define kEveryoneLastFetched                @"everyone_last_fetched"
#define kEveryone                           @"everyone"
#define kLastCheckedMe                      @"last_checked_me"
#define kCheckMeInternal                    3600 * 24 * 10 //10 days

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
+ (void)updateMe;

- (EWPerson *)anyone;

//friend
- (void)requestFriend:(EWPerson *)user;
- (void)acceptFriend:(EWPerson *)user;
- (void)unfriend:(EWPerson *)user;

- (void)purgeUserData;
@end
