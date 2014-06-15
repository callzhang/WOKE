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

+ (EWPersonStore *)sharedInstance;
- (EWPerson *)createPersonWithParseObject:(PFUser *)user;
- (EWPerson *)getPersonByID:(NSString *)ID;

/**
 Update person from server in sync mode.
 */
//- (void)updatePerson:(EWPerson *)person withServerUser:(PFUser *)user;


//- (NSArray *)everyone;
- (EWPerson *)anyone;
- (void)purgeUserData;
- (void)checkRelations;
@end
