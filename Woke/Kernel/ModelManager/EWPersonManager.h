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
#define kCheckMeInternal                    3600 * 24 //1 day

@class EWMediaManager, EWPerson;

@interface EWPersonManager : NSObject

/**
 Possible people that are relevant, fetched from server(TODO)
 */
@property (nonatomic) NSArray *everyone;
@property (nonatomic) NSDate *timeEveryoneChecked;
@property BOOL isFetchingEveryone;

+ (EWPersonManager *)sharedInstance;
- (EWPerson *)findOrCreatePersonWithParseObject:(PFUser *)user;
- (EWPerson *)getPersonByServerID:(NSString *)ID;
- (void)getEveryoneInBackgroundWithCompletion:(void (^)(void))block;

/**
 Check from server at login.
 Fetch current state of currentUser with a custom function to server
 Get a json from server that includes all currentUser's value and relation
 Check if any change is needed.
 */
//+ (void)updateMe;

//friend
//TODO: move to EWPerson
+ (void)requestFriend:(EWPerson *)person;
+ (void)acceptFriend:(EWPerson *)person;
+ (void)unfriend:(EWPerson *)person;
+ (void)getFriendsForPerson:(EWPerson *)person;

+ (BOOL)validatePerson:(EWPerson *)person;


@end
