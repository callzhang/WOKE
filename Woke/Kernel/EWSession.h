//
//  EWSharedSession.h
//  Woke
//
//  Created by Lei Zhang on 10/26/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"

@interface EWSession : NSObject

@property BOOL isSchedulingAlarm;
@property EWPerson *currentUser;

+ (EWSession *)sharedSession;


@end
