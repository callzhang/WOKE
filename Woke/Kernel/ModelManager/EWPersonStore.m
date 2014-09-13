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
#import "EWTaskStore.h"
#import "NSDate+Extend.h"
#import "EWAppDelegate.h"
#import "EWLogInViewController.h"
#import "EWDataStore.h"
#import "EWUserManagement.h"
#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWStatisticsManager.h"


//===========the global shortcut to currentUser ===========
EWPerson *me;
//=========================================================

@interface EWPersonStore(){
    NSDate *timeEveryoneChecked;
}

@end

@implementation EWPersonStore
@synthesize currentUser;
@synthesize everyone;

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
    me = user;
    currentUser = user;
    [me addObserver:self forKeyPath:@"score" options:NSKeyValueObservingOptionNew context:nil];
    [me addObserver:self forKeyPath:@"lastLocation" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - CREATE USER
-(EWPerson *)createPersonWithParseObject:(PFUser *)user{
    EWPerson *newUser = (EWPerson *)[user managedObjectInContext:mainContext];
    newUser.username = user.username;
    newUser.profilePic = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", arc4random_uniform(15)]];//TODO: new user profile
    newUser.name = kDefaultUsername;
    newUser.preference = kUserDefaults;
    newUser.cachedInfo = [NSDictionary new];
    if ([user isEqual:[PFUser currentUser]]) {
        newUser.score = @100;
    }
    newUser.updatedAt = [NSDate date];
    //no need to save here
    return newUser;
}

-(EWPerson *)getPersonByServerID:(NSString *)ID{
    NSParameterAssert([NSThread isMainThread]);
    //ID is username
    if(!ID) return nil;
    EWPerson *person = [EWPerson findFirstByAttribute:kParseObjectID withValue:ID];
    
    if (!person){
        //First find user on server
        PFUser *user;
        if ([[PFUser currentUser].objectId isEqualToString:ID]) {
            user = [PFUser currentUser];
        }else{
            user = (PFUser *)[EWDataStore getCachedParseObjectForID:ID];
            if (!user) {
                NSError *err;
                user = (PFUser *)[EWDataStore getParseObjectWithClass:@"EWPerson" WithID:ID withError:&err];
                if (err || !user) {
                    NSLog(@"Failed to find user with ID %@. Reason:%@", ID, err.description);
                    return nil;
                }
            }
            
        }
        
        
        if (user.isNew) {
            person = [self createPersonWithParseObject:user];
            NSLog(@"New user %@ data has CREATED", person.name);
        }else{
            person = (EWPerson *)[user managedObjectInContext:mainContext];
            NSLog(@"Person %@ created from PO", user[@"name"]);
        }
        
    }
    
    return person;
}

- (void)refreshPersonInBackgroundWithCompletion:(void (^)(void))block{
    
}


//check my relation, used for new installation with existing user
+ (void)updateMe{
    NSDate *lastCheckedMe = [[NSUserDefaults standardUserDefaults] valueForKey:kLastCheckedMe];
    BOOL good = [EWPersonStore validatePerson:me];
    if (!good || !lastCheckedMe || lastCheckedMe.timeElapsed > kCheckMeInternal) {
        if (!good) {
            NSLog(@"Failed to validate me, refreshing from server");
        }else if (!lastCheckedMe) {
            NSLog(@"Didn't find lastCheckedMe date, start to refresh my relation in background");
        }else{
            NSLog(@"lastCheckedMe date is %@, which exceed the check interval %d, start to refresh my relation in background", lastCheckedMe.date2detailDateString, kCheckMeInternal);
        }

        [me refreshRelatedInBackground];
        [EWPersonStore updateCachedFriends];
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kLastCheckedMe];
    }
}



- (NSArray *)everyone{
    NSParameterAssert([NSThread isMainThread]);
    [mainContext saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        [self getEveryoneInContext:localContext];
    }];
    
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
    if (everyone && timeEveryoneChecked.timeElapsed < everyoneCheckTimeOut && everyone.count != 0) {
        return;
    }    //fetch from sever
    NSMutableArray *allPerson = [NSMutableArray new];
    
    EWPerson *localMe = [me inContext:context];
    NSString *parseObjectId = [localMe valueForKey:kParseObjectID];
    NSError *error;
    
    //check my location
    if (!localMe.lastLocation) {
        //NSLog(@"Forfeit getting everyone around because no location on file");
        //return;
        
        //get a temp coordinate
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:40.732019 longitude:-73.992684];
        localMe.lastLocation = loc;
        
    }
    NSArray *list = [PFCloud callFunction:@"getRelevantUsers"
                           withParameters:@{@"objectId": parseObjectId,
                                            @"topk" : numberOfRelevantUsers,
                                            @"radius" : radiusOfRelevantUsers,
                                            @"location": @{@"latitude": @(me.lastLocation.coordinate.latitude),
                                                           @"longitude": @(me.lastLocation.coordinate.longitude)}}
                                    error:&error];
    
    if (error && list.count == 0) {
        NSLog(@"*** Failed to get friends list: %@", error.description);
        //get cached person
        error = nil;
        list = localMe.cachedInfo[kEveryone];
    }else{
        //cache
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
    NSArray *people = [query findObjects:&error];
    
    if (error) {
        NSLog(@"*** Failed to fetch everyone.");
        //TODO
        return;
    }
    
    //make sure the rest of people's score is revert back to 0
    NSArray *otherLocalPerson = [EWPerson findAllWithPredicate:[NSPredicate predicateWithFormat:@"(NOT %K IN %@) AND score > 0 AND %K != %@", kParseObjectID, [people valueForKey:kParseObjectID], kParseObjectID, me.objectId] inContext:context];
    for (EWPerson *person in otherLocalPerson) {
        person.score = 0;
    }
    
    //change the returned people's score;
    for (PFUser *user in people) {
        EWPerson *person = (EWPerson *)[user managedObjectInContext:context];
        float score = 99 - [people indexOfObject:user] - arc4random_uniform(3);//add random for testing
        person.score = [NSNumber numberWithFloat:score];
        [allPerson addObject:person];
    }
    
    //batch save to local
    [allPerson addObjectsFromArray:otherLocalPerson];
    [EWDataStore saveAllToLocal:allPerson];
    
    //still need to save me
    localMe.score = @100;
    
    NSLog(@"Received everyone list: %@", [allPerson valueForKey:@"name"]);
    
    timeEveryoneChecked = [NSDate date];
    
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
    if (![me isEqual:user]) {
        self.currentUser = user;
    }
    
}

- (void)userLoggedOut:(NSNotification *)notif{
    self.currentUser = nil;
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isEqual:me]) {
        if ([keyPath isEqualToString:@"score"]) {
            NSNumber *score = change[NSKeyValueChangeNewKey];
            if ([score isKindOfClass:[NSNull class]] || [score integerValue] != 100) {
                NSLog(@"My score resotred to 100");
                me.score = @100;
            }
        }else if ([keyPath isEqualToString:@"profilePic"]){
            if (![object valueForKey:@"profilePic"]) {
                EWAlert(@"*** Profile picture missing");
            }
            
        }else if ([keyPath isEqualToString:@"lastLocation"]){
            NSLog(@"Last location updated, start grab everyone");
            [self refreshPersonInBackgroundWithCompletion:NULL];
        }
        
    }
}

#pragma mark - Friend
+ (void)requestFriend:(EWPerson *)person{
    [EWPersonStore getFriendsForPerson:me];
    [me addFriendsObject:person];
    [EWPersonStore updateCachedFriends];
    [EWNotificationManager sendFriendRequestNotificationToUser:person];
    
    [EWDataStore save];

}

+ (void)acceptFriend:(EWPerson *)person{
    [EWPersonStore getFriendsForPerson:me];
    [me addFriendsObject:person];
    [EWPersonStore updateCachedFriends];
    [EWNotificationManager sendFriendAcceptNotificationToUser:person];
    
    //update cache
    [EWStatisticsManager updateCacheWithFriendsAdded:@[person.serverID]];
    
    [EWDataStore save];
}

+ (void)unfriend:(EWPerson *)person{
    [EWPersonStore getFriendsForPerson:me];
    [me removeFriendsObject:person];
    [EWPersonStore updateCachedFriends];
    //TODO: unfriend
    //[EWServer unfriend:user];
    [EWDataStore save];
}

+ (void)getFriendsForPerson:(EWPerson *)person{
    NSArray *friends = person.cachedInfo[kCachedFriends];
    if (!friends || friends.count != person.friends.count) {
        //friend need update
        PFQuery *q = [PFQuery queryWithClassName:person.entity.serverClassName];
        [q includeKey:@"friends"];
        [q whereKey:kParseObjectID equalTo:person.serverID];
        PFObject *user = [q getFirstObject];
        NSArray *friendsPO = user[@"friends"];
        if (friendsPO.count == 0) return;//prevent 0 friend corrupt data
        NSMutableSet *friendsMO = [NSMutableSet new];
        for (PFObject *f in friendsPO) {
            if ([f isKindOfClass:[NSNull class]]) {
                continue;
            }
            NSManagedObject *mo = [f managedObjectInContext:person.managedObjectContext];
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
        EWPerson *localMe = [me inContext:localContext];
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
        NSLog(@"!!!Username is missing!");
    }
    
    if (person.alarms.count == 7 && person.tasks.count == 7*nWeeksToScheduleTask) {
        good = YES;
    }else if (person.alarms.count == 0 && person.tasks.count == 0){
        good = YES;
    
    }else{
        good = NO;
        NSLog(@"The person failed validation: alarms: %ld, tasks: %ld", (long)person.alarms.count, (long)person.tasks.count);
    }
    
    if (needRefreshFacebook) {
        [EWUserManagement updateFacebookInfo];
    }
    
    return good;
}

@end
