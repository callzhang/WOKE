//
//  EWSharedSession.h
//  Woke
//
//  Created by Lei Zhang on 10/26/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"
#import "NSManagedObject+MagicalFinders.h"


@interface EWSession : NSObject

@property BOOL isSchedulingAlarm;
@property EWPerson *currentUser;
@property (nonatomic) NSManagedObjectContext *context;

+ (EWSession *)sharedSession;
+ (NSManagedObjectContext *)mainContext;

@end
