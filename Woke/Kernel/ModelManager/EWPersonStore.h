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

//@property (retain, nonatomic) EWPerson *me;
@property (nonatomic, strong) NSArray *everyone;

+ (EWPersonStore *)sharedInstance;
- (EWPerson *)createPersonWithParseObject:(PFUser *)user;
- (EWPerson *)getPersonByID:(NSString *)ID;
/**
 Possible people that are relevant
 */
//- (NSArray *)everyone;
- (EWPerson *)anyone;
- (void)purgeUserData;
- (void)checkRelations;
@end
