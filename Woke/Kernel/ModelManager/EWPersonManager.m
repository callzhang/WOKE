//
//  EWPersonStore.m
//  EarlyWorm
//
//  Created by Lei on 8/16/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWPersonManager.h"
#import "EWMediaManager.h"
#import "EWMedia.h"
#import "EWPerson.h"
#import "EWUtil.h"
#import "EWAlarmManager.h"
//#import "EWTaskManager.h"
#import "NSDate+Extend.h"
#import "EWAppDelegate.h"
#import "EWLogInViewController.h"
#import "EWDataStore.h"
#import "EWUserManagement.h"
#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWStatisticsManager.h"


@implementation EWPersonManager
@synthesize everyone;
@synthesize isFetchingEveryone = _isFetchingEveryone;
@synthesize timeEveryoneChecked;

+(EWPersonManager *)sharedInstance{
    static EWPersonManager *sharedPersonStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPersonStore_ = [[EWPersonManager alloc] init];
        //listern to user log in events
        [[NSNotificationCenter defaultCenter] addObserver:sharedPersonStore_ selector:@selector(userLoggedIn:) name:kPersonLoggedIn object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:sharedPersonStore_ selector:@selector(userLoggedOut:) name:kPersonLoggedOut object:nil];
    });
    
    return sharedPersonStore_;
}

#pragma mark - ME
//Current User MO at background thread
- (void)setCurrentUser:(EWPerson *)user{
    [EWSession sharedSession].currentUser = user;
    [[EWSession sharedSession].currentUser addObserver:self forKeyPath:@"score" options:NSKeyValueObservingOptionNew context:nil];
    [[EWSession sharedSession].currentUser addObserver:self forKeyPath:@"lastLocation" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - CREATE USER
-(EWPerson *)getPersonByServerID:(NSString *)ID{
    NSParameterAssert([NSThread isMainThread]);
    if(!ID) return nil;
    EWPerson *person = (EWPerson *)[EWSync managedObjectWithClass:@"EWPerson" withID:ID];
    
    return person;
}

#pragma mark - Everyone server code

- (BOOL)isFetchingEveryone{
    @synchronized(self){
        return _isFetchingEveryone;
    }
}

- (void)setIsFetchingEveryone:(BOOL)isFetchingEveryone{
    @synchronized(self){
        _isFetchingEveryone = isFetchingEveryone;
    }
}

- (NSArray *)everyone{
    NSParameterAssert([NSThread isMainThread]);
    
    //fetch from sever
    [self getEveryoneInContext:mainContext];
    
    NSArray *allPerson = [EWPerson findAllWithPredicate:[NSPredicate predicateWithFormat:@"score > 0"] inContext:mainContext];
    everyone = [allPerson sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]]];
    return everyone;
    
}

- (void)getEveryoneInBackgroundWithCompletion:(void (^)(void))block{
    NSParameterAssert([NSThread isMainThread]);
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        [self getEveryoneInContext:localContext];
    }completion:^(BOOL success, NSError *error) {
        NSArray *allPerson = [EWPerson findAllWithPredicate:[NSPredicate predicateWithFormat:@"score > 0"] inContext:mainContext];
        everyone = [allPerson sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]]];
        if (block) {
            block();
        }
    }];
}

- (void)getEveryoneInContext:(NSManagedObjectContext *)context{
    
    //cache
    if ((everyone.count > 0 && timeEveryoneChecked && timeEveryoneChecked.timeElapsed < everyoneCheckTimeOut) || self.isFetchingEveryone) {
        return;
    }
    self.isFetchingEveryone = YES;
    timeEveryoneChecked = [NSDate date];
    
    
    NSMutableArray *allPerson = [NSMutableArray new];
    
    EWPerson *localMe = [[EWSession sharedSession].currentUser inContext:context];
    NSString *parseObjectId = [localMe valueForKey:kParseObjectID];
    NSError *error;
    
    //check my location
    if (!localMe.lastLocation) {
        //get a fake coordinate
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        localMe.lastLocation = loc;
        
    }
    
    NSArray *list = [PFCloud callFunction:@"getRelevantUsers"
                           withParameters:@{@"objectId": parseObjectId,
                                            @"topk" : numberOfRelevantUsers,
                                            @"radius" : radiusOfRelevantUsers,
                                            @"location": @{@"latitude": @([EWSession sharedSession].currentUser.lastLocation.coordinate.latitude),
                                                           @"longitude": @([EWSession sharedSession].currentUser.lastLocation.coordinate.longitude)}}
                                    error:&error];
    
    if (error && list.count == 0) {
        NSLog(@"*** Failed to get relavent user list: %@", error.description);
        //get cached person
        error = nil;
        list = localMe.cachedInfo[kEveryone];
    }else{
        //update cache
        NSMutableDictionary *cachedInfo = [localMe.cachedInfo mutableCopy];
        cachedInfo[kEveryone] = list;
        cachedInfo[kEveryoneLastFetched] = [NSDate date];
        localMe.cachedInfo = cachedInfo;
    }
    
    //fetch
    error = nil;
    PFQuery *query = [PFUser query];
    [query whereKey:kParseObjectID containedIn:list];
    [query includeKey:@"friends"];
    NSArray *people = [EWSync findServerObjectWithQuery:query error:&error];
    
    if (error) {
        NSLog(@"*** Failed to fetch everyone: %@", error);
        self.isFetchingEveryone = NO;
        return;
    }
    
    //make sure the rest of people's score is revert back to 0
    NSArray *otherLocalPerson = [EWPerson findAllWithPredicate:[NSPredicate predicateWithFormat:@"(NOT %K IN %@) AND score > 0 AND %K != %@", kParseObjectID, [people valueForKey:kParseObjectID], kParseObjectID, [EWSession sharedSession].currentUser.objectId] inContext:context];
    for (EWPerson *person in otherLocalPerson) {
        person.score = 0;
    }
    
    //change the returned people's score;
    for (PFUser *user in people) {
        EWPerson *person = (EWPerson *)[user managedObjectInContext:context];
        [NSThread sleepForTimeInterval:0.1];//throttle down the new user creation speed
        float score = 99 - [people indexOfObject:user] - arc4random_uniform(3);//add random for testing
		if (person.score && person.score.floatValue != score) {
			person.score = [NSNumber numberWithFloat:score];
			[allPerson addObject:person];
		}
    }
    
    //batch save to local
    [allPerson addObjectsFromArray:otherLocalPerson];
    [EWSync saveAllToLocal:allPerson];
    
    //still need to save me
    localMe.score = @100;
    
    NSLog(@"Received everyone list: %@", [allPerson valueForKey:@"name"]);
    self.isFetchingEveryone = NO;
}

- (void)setEveryone:(NSArray *)e{
    everyone = e;
}


- (EWPerson *)anyone{
    
    NSInteger i = arc4random_uniform((uint16_t)self.everyone.count);
    EWPerson *one = self.everyone[i];
    return one;
}



#pragma mark - Notification
//TODO: [ZITAO] move to account manager.
- (void)userLoggedIn:(NSNotification *)notif{
    EWPerson *user = notif.object;
    if (![[EWSession sharedSession].currentUser isEqual:user]) {
        self.currentUser = user;
    }
    
}

- (void)userLoggedOut:(NSNotification *)notif{
    self.currentUser = nil;
}




@end
