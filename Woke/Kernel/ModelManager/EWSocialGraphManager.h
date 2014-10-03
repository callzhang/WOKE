//
//  EWSocialGraphManager.h
//  Woke
//
//  Created by Lei on 4/16/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWSocialGraph.h"
@class EWPerson;
@interface EWSocialGraphManager : NSObject

+ (EWSocialGraphManager *)sharedInstance;

//Search
- (EWSocialGraph *)mySocialGraph;
- (EWSocialGraph *)socialGraphForPerson:(EWPerson *)person;

//Create
- (EWSocialGraph *)createSocialGraphForPerson:(EWPerson *)person;

- (void)testFindWithUsersCompletion:(void (^)(NSArray *users))completion;
- (BOOL)hasAddressBookAccess;
- (void)loadAddressBookCompletion:(void (^)(NSArray *contacts, NSError *error))completion;
@end
