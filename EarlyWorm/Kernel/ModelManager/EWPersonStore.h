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

extern EWPerson *currentUser;

@class EWMediaStore, EWPerson;

@interface EWPersonStore : NSObject

//@property (retain, nonatomic) EWPerson *currentUser;

+ (EWPersonStore *)sharedInstance;
- (EWPerson *)createPersonWIthUsername:(NSString *)username;
- (EWPerson *)getPersonByID:(NSString *)ID;
- (NSArray *)everyone;
- (void)purgeUserData;
- (void)checkRelations;
@end
