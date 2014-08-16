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
+ (EWPerson *)me{
    if ([NSThread isMainThread]) {
        return me;
    }else{
        return [EWDataStore objectForCurrentContext:me];
    }
}

- (EWPerson *)currentUser{
    return currentUser;
}

- (void)setCurrentUser:(EWPerson *)user{
    me = user;
    currentUser = user;
    [me addObserver:self forKeyPath:@"score" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - CREATE USER
-(EWPerson *)createPersonWithParseObject:(PFUser *)user{
    EWPerson *newUser = (EWPerson *)[user managedObject];
    newUser.username = user.username;
    newUser.profilePic = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", arc4random_uniform(15)]];
    newUser.name = kDefaultUsername;
    newUser.preference = kUserDefaults;
    newUser.cachedInfo = [NSDictionary new];
    if ([user isEqual:[PFUser currentUser]]) {
        newUser.score = @100;
    }
    
    //skip uploading because there will have more info to upload
    
    [EWDataStore save];

    return newUser;
}

-(EWPerson *)getPersonByObjectID:(NSString *)ID{
    //ID is username
    if(!ID) return nil;
    EWPerson *person = [EWPerson findFirstByAttribute:@"objectId" withValue:ID];
    
    if (!person){
        //First find user on server
        PFUser *user;
        if ([[PFUser currentUser].objectId isEqualToString:ID]) {
            user = [PFUser currentUser];
        }else{
            PFQuery *query = [PFUser query];
            [query whereKey:kParseObjectID equalTo:ID];
            [query includeKey:@"friends"];
            NSError *error;
            user = [query findObjects:&error].firstObject;
            if (error || !user) {
                NSLog(@"Failed to find user with ID %@. Reason:%@", ID, error.description);
                return nil;
            }
        }
        
        
        if (user.isNew) {
            person = [self createPersonWithParseObject:user];
            NSLog(@"New user %@ data has CREATED", person.name);
        }else{
            person = (EWPerson *)[user managedObject];
            NSLog(@"Person created from PO");
            //assign user
            for (PFUser *friendPO in user[@"friends"]) {
                EWPerson *friend = (EWPerson *)friendPO.managedObject;
                [person addFriendsObject:friend];
            }
        }
        
    }else{
        NSLog(@"Me %@ data has FETCHED", person.name);
    }
    
    
    return person;
}

//DEPRECIATED
-(EWPerson *)getPersonByID:(NSString *)ID{
    //ID is username
    if(!ID) return nil;
    EWPerson *person = [EWPerson findFirstByAttribute:@"username" withValue:ID];
    
    if (!person){
        //First find user on server
        PFUser *user;
        if ([[PFUser currentUser].username isEqualToString:ID]) {
            user = [PFUser currentUser];
        }else{
            PFQuery *query = [PFUser query];
            [query whereKey:kUsername equalTo:ID];
            NSError *error;
            user = [query findObjects:&error].firstObject;
            if (error) {
                NSLog(@"Failed to find user with ID %@. Reason:%@", ID, error.description);
            }
        }
        
        if (user.isNew) {
            person = [self createPersonWithParseObject:user];
            NSLog(@"Current user %@ data has CREATED", person.name);
        }else{
            person = (EWPerson *)[user managedObject];
            NSLog(@"Person created from PO");
        }
        
        
    }else{
        NSLog(@"Me %@ data has FETCHED", person.name);
    }
    

    return person;
}

//check my relation, used for new installation with existing user
+ (void)updateMe{
    NSDate *lastCheckedMe = [[NSUserDefaults standardUserDefaults] valueForKey:kLastCheckedMe];
    if (!lastCheckedMe || [[NSDate date] timeIntervalSinceDate:lastCheckedMe] > kCheckMeInternal) {
        if (!lastCheckedMe) {
            NSLog(@"Didn't find lastCheckedMe date, start to refresh my relation in background");
        }else{
            NSLog(@"lastCheckedMe date is %@, which exceed the check interval %d, start to refresh my relation in background", lastCheckedMe.date2detailDateString, kCheckMeInternal);
        }
        [me refreshInBackgroundWithCompletion:^{
            [EWPersonStore updateCachedFriends];
        }];
        [me refreshRelatedInBackground];
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kLastCheckedMe];
    }
}



- (NSArray *)everyone{
    if (everyone && [[NSDate date] timeIntervalSinceDate:timeEveryoneChecked] < everyoneCheckTimeOut && everyone.count != 0) {
        return everyone;
    }
    //fetch from sever
    NSMutableArray *allPerson = [NSMutableArray new];
    NSString *parseObjectId = [me valueForKey:kParseObjectID];
    NSError *error;
    NSArray *list = [PFCloud callFunction:@"getRelevantUsers"
           withParameters:@{@"objectId": parseObjectId,
                            @"topk" : numberOfRelevantUsers,
                            @"radius" : radiusOfRelevantUsers}
                    error:&error];
    
    if (error && list.count == 0) {
        NSLog(@"*** Failed to get friends list: %@", error.description);
        //get cached person
        error = nil;
        list = me.cachedInfo[kEveryone];
    }else{
        //cache
        NSMutableDictionary *cachedInfo = [me.cachedInfo mutableCopy];
        cachedInfo[kEveryone] = list;
        cachedInfo[kEveryoneLastFetched] = [NSDate date];
        me.cachedInfo = cachedInfo;
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
        return nil;
    }
    
    //make sure the everyone is saved on main thread
    [[NSManagedObjectContext defaultContext] performBlockAndWait:^{
        
        for (PFUser *user in people) {
            EWPerson *person = (EWPerson *)user.managedObject;
            float score = 99 - [people indexOfObject:user];
            person.score = [NSNumber numberWithFloat:score];
            [allPerson addObject:person];
            [EWDataStore saveToLocal:person];
        }
        
        [EWPersonStore me].score = @100;
        NSLog(@"Received everyone list: %@", [allPerson valueForKey:@"name"]);
        
        everyone = [allPerson copy];
        timeEveryoneChecked = [NSDate date];
        
        [EWDataStore save];
    }];
    
    return everyone;
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
    EWPerson *user = notif.userInfo[kUserLoggedInUserKey];
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
        NSNumber *score = change[NSKeyValueChangeNewKey];
        if ([score integerValue] != 100) {
            NSLog(@"My score resotred to 100");
            me.score = @100;
        }
    }else if ([keyPath isEqualToString:@"profilePic"]){
        if (![object valueForKey:@"profilePic"]) {
            EWAlert(@"Profile picture missing");
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
    EWPerson *backPerson = [EWDataStore objectForCurrentContext:person];
    NSArray *friends = backPerson.cachedInfo[kCachedFriends];
    if (!friends || friends.count != backPerson.friends.count) {
        //friend need update
        PFQuery *q = [PFQuery queryWithClassName:backPerson.entity.serverClassName];
        [q includeKey:@"friends"];
        [q whereKey:kParseObjectID equalTo:backPerson.serverID];
        PFObject *user = [q getFirstObject];
        NSArray *friendsPO = user[@"friends"];
        if (friendsPO.count == 0) return;//prevent 0 friend corrupt data
        NSMutableSet *friendsMO = [NSMutableSet new];
        for (PFObject *f in friendsPO) {
            if ([f isKindOfClass:[NSNull class]]) {
                continue;
            }
            NSManagedObject *mo = f.managedObject;
            [friendsMO addObject:mo];
        }
        backPerson.friends = [friendsMO copy];
        if ([backPerson.serverID isEqualToString: PFUser.currentUser.objectId ]) {
            [EWPersonStore updateCachedFriends];
        }
        [EWDataStore save];
    }
}

+ (void)updateCachedFriends{
    EWPerson *backPerson = (EWPerson *)PFUser.currentUser.managedObject;
    NSSet *friends = [backPerson.friends valueForKey:kParseObjectID];
    NSMutableDictionary *cache = me.cachedInfo.mutableCopy;
    cache[kCachedFriends] = friends.allObjects;
    backPerson.cachedInfo = [cache copy];
    [EWDataStore save];
}


#pragma mark - Validation
+ (BOOL)validatePerson:(EWPerson *)person{
    if (!person.isMe) {
        NSLog(@"Skip updating other PFUser: %@", person.name);
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
        NSLog(@"Username is missing!");
    }
    
    if(person.friends.count == 0){
        NSLog(@"*** Please check if your friend count is indeed 0. If not, something is seriously wrong. Check the process that arrived to this code and try to fix this problem.");
        
    }
    
    if (needRefreshFacebook) {
        [EWUserManagement updateFacebookInfo];
    }
    
    return good;
}

@end
