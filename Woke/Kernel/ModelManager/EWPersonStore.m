//
//  EWPersonStore.m
//  EarlyWorm
//
//  Created by Lei on 8/16/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWPersonStore.h"
#import "EWMediaStore.h"
#import "EWMediaItem.h"
#import "EWPerson.h"
#import "EWUtil.h"
#import "EWAlarmManager.h"
#import "EWTaskManager.h"
#import "NSDate+Extend.h"
#import "EWAppDelegate.h"
#import "EWLogInViewController.h"
#import "EWDataStore.h"
#import "EWUserManagement.h"
#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWStatisticsManager.h"


@implementation EWPersonStore
@synthesize everyone;
@synthesize isFetchingEveryone = _isFetchingEveryone;
@synthesize timeEveryoneChecked;

+(EWPersonStore *)sharedInstance{
    static EWPersonStore *sharedPersonStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPersonStore_ = [[EWPersonStore alloc] init];
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
-(EWPerson *)findOrCreatePersonWithParseObject:(PFUser *)user{
    EWPerson *newUser = (EWPerson *)[user managedObjectInContext:mainContext];
    if (user.isNew) {
        newUser.username = user.username;
        newUser.profilePic = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", arc4random_uniform(15)]];//TODO: new user profile
        newUser.name = kDefaultUsername;
        newUser.preference = kUserDefaults;
        newUser.cachedInfo = [NSDictionary new];
        if ([user isEqual:[PFUser currentUser]]) {
            newUser.score = @100;
        }
        newUser.updatedAt = [NSDate date];
    }
    
    //no need to save here
    return newUser;
}

-(EWPerson *)getPersonByServerID:(NSString *)ID{
    NSParameterAssert([NSThread isMainThread]);
    if(!ID) return nil;
    EWPerson *person = (EWPerson *)[EWSync managedObjectWithClass:@"EWPerson" withID:ID];
    
    return person;
}


//check my relation, used for new installation with existing user
+ (void)updateMe{
    NSDate *lastCheckedMe = [[NSUserDefaults standardUserDefaults] valueForKey:kLastCheckedMe];
    BOOL good = [EWPersonStore validatePerson:[EWSession sharedSession].currentUser];
    if (!good || !lastCheckedMe || lastCheckedMe.timeElapsed > kCheckMeInternal) {
        if (!good) {
            NSLog(@"Failed to validate me, refreshing from server");
        }else if (!lastCheckedMe) {
            NSLog(@"Didn't find lastCheckedMe date, start to refresh my relation in background");
        }else{
            NSLog(@"lastCheckedMe date is %@, which exceed the check interval %d, start to refresh my relation in background", lastCheckedMe.date2detailDateString, kCheckMeInternal);
        }
        
        [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
            EWPerson *localMe = [[EWSession sharedSession].currentUser inContext:localContext];
            [localMe refreshRelatedWithCompletion:^{
                
                [EWPersonStore updateCachedFriends];
                [EWUserManagement updateFacebookInfo];
            }];
            //TODO: we need a better sync method
            //1. query for medias
            
            
            //2. check
        }];
        
        
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kLastCheckedMe];
    }
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
- (void)userLoggedIn:(NSNotification *)notif{
    EWPerson *user = notif.object;
    if (![[EWSession sharedSession].currentUser isEqual:user]) {
        self.currentUser = user;
    }
    
}

- (void)userLoggedOut:(NSNotification *)notif{
    self.currentUser = nil;
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isEqual:[EWSession sharedSession].currentUser]) {
        if ([keyPath isEqualToString:@"score"]) {
            NSNumber *score = change[NSKeyValueChangeNewKey];
            if ([score isKindOfClass:[NSNull class]] || [score integerValue] != 100) {
                DDLogError(@"My score resotred to 100");
                [EWSession sharedSession].currentUser.score = @100;
            }
        }else if ([keyPath isEqualToString:@"profilePic"]){
            if (![object valueForKey:@"profilePic"]) {
                EWAlert(@"*** Profile picture missing");
            }
            
        }else if ([keyPath isEqualToString:@"lastLocation"]){
            NSLog(@"Last location updated, start grab everyone");
            [self getEveryoneInBackgroundWithCompletion:NULL];
        }
        
    }
}

#pragma mark - Friend
+ (void)requestFriend:(EWPerson *)person{
    [EWPersonStore getFriendsForPerson:[EWSession sharedSession].currentUser];
    [[EWSession sharedSession].currentUser addFriendsObject:person];
    [EWPersonStore updateCachedFriends];
    [EWNotificationManager sendFriendRequestNotificationToUser:person];
    
    [EWSync save];

}

+ (void)acceptFriend:(EWPerson *)person{
    [EWPersonStore getFriendsForPerson:[EWSession sharedSession].currentUser];
    [[EWSession sharedSession].currentUser addFriendsObject:person];
    [EWPersonStore updateCachedFriends];
    [EWNotificationManager sendFriendAcceptNotificationToUser:person];
    
    //update cache
    [EWStatisticsManager updateCacheWithFriendsAdded:@[person.serverID]];
    
    [EWSync save];
}

+ (void)unfriend:(EWPerson *)person{
    [EWPersonStore getFriendsForPerson:[EWSession sharedSession].currentUser];
    [[EWSession sharedSession].currentUser removeFriendsObject:person];
    [EWPersonStore updateCachedFriends];
    //TODO: unfriend
    //[EWServer unfriend:user];
    [EWSync save];
}

+ (void)getFriendsForPerson:(EWPerson *)person{
    NSArray *friendsCached = person.cachedInfo[kCachedFriends]?:[NSArray new];
    NSSet *friends = person.friends;
    BOOL friendsNeedUpdate = person.isMe && friendsCached.count !=person.friends.count;
    if (!friends || friendsNeedUpdate) {
        
        DDLogInfo(@"Friends mismatch, fetch from server");
        
        //friend need update
        PFQuery *q = [PFQuery queryWithClassName:person.serverClassName];
        [q includeKey:@"friends"];
        [q whereKey:kParseObjectID equalTo:person.serverID];
        PFObject *user = [[EWSync findServerObjectWithQuery:q] firstObject];
        NSArray *friendsPO = user[@"friends"];
        if (friendsPO.count == 0) return;//prevent 0 friend corrupt data
        NSMutableSet *friendsMO = [NSMutableSet new];
        for (PFObject *f in friendsPO) {
            if ([f isKindOfClass:[NSNull class]]) {
                continue;
            }
            EWPerson *mo = (EWPerson *)[f managedObjectInContext:person.managedObjectContext];
            [friendsMO addObject:mo];
        }
        person.friends = [friendsMO copy];
        if ([person.serverID isEqualToString: PFUser.currentUser.objectId ]) {
            [EWPersonStore updateCachedFriends];
        }
    }
}

+ (void)updateCachedFriends{
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWPerson *localMe = [[EWSession sharedSession].currentUser inContext:localContext];
        NSSet *friends = [localMe.friends valueForKey:kParseObjectID];
        NSMutableDictionary *cache = localMe.cachedInfo.mutableCopy;
        cache[kCachedFriends] = friends.allObjects;
        localMe.cachedInfo = [cache copy];
    }];
}


#pragma mark - Validation
+ (BOOL)validatePerson:(EWPerson *)person{
    if (!person.isMe) {
        //skip check other user
        return YES;
    }
    
    BOOL good = YES;
    BOOL needRefreshFacebook = NO;
    if(!person.name){
        NSString *name = [PFUser currentUser][@"name"];
        if (name) {
            person.name = name;
        }else{
            needRefreshFacebook = YES;
        }
    }
    if(!person.profilePic){
        PFFile *pic = [PFUser currentUser][@"profilePic"];
        UIImage *img = [UIImage imageWithData:pic.getData];
        if (img) {
            person.profilePic = img;
        }else{
            needRefreshFacebook = YES;
        }
    }
    if(!person.username){
        person.username = [PFUser currentUser].username;
        DDLogError(@"Username is missing!");
    }
    
    if (person.alarms.count == 7 && person.tasks.count == 7*nWeeksToScheduleTask) {
        good = YES;
    }else if (person.alarms.count == 0 && person.tasks.count == 0){
        good = YES;
    
    }else{
        good = NO;
        DDLogError(@"The person failed validation: alarms: %ld, tasks: %ld", (long)person.alarms.count, (long)person.tasks.count);
    }
    
    if (needRefreshFacebook) {
        [EWUserManagement updateFacebookInfo];
    }
    
    //preference
    if (!person.preference) {
        person.preference = kUserDefaults;
    }
    
    //friends
    NSArray *friendsID = person.cachedInfo[kFriended];
    if (person.friends.count != friendsID.count) {
        [EWPersonStore getFriendsForPerson:person];
    }
    
    return good;
}

@end
