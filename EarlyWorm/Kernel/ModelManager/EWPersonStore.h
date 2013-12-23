//
//  EWPersonStore.h
//  EarlyWorm
//
//  Created by Lei on 8/16/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWStore.h"

@class EWMediaStore, EWPerson;

@interface EWPersonStore : NSObject

//@property (retain, nonatomic) NSArray * allPerson;
@property (retain, nonatomic) EWPerson *currentUser;

+ (EWPersonStore *)sharedInstance;
- (EWPerson *)createPersonWIthUsername:(NSString *)username;
- (EWPerson *)getPersonByID:(NSString *)ID;
- (NSArray *)everyone;
@end
