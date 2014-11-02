//
//  EWSharedSession.m
//  Woke
//
//  Created by Lei Zhang on 10/26/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWSession.h"

@implementation EWSession
+ (EWSession *)sharedSession {
    //make sure core data stuff is always on main thread
    //NSParameterAssert([NSThread isMainThread]);
    static EWSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        session = [[EWSession alloc] init];
    });
    
    return session;
}

+ (NSManagedObjectContext *)mainContext{
    return [EWSession sharedSession].context;
}
@end
