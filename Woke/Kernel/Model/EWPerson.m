//
//  EWPerson.m
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//j

#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWAlarm.h"

@implementation EWPerson
@dynamic lastLocation;
@dynamic profilePic;
@dynamic bgImage;
@dynamic preference;
@dynamic cachedInfo;
@dynamic images;


#pragma mark - Helper methods
- (BOOL)isMe {
    BOOL isme = NO;
    if ([EWSession sharedSession].currentUser) {
        isme = [self.username isEqualToString:[EWSession sharedSession].currentUser.username];
    }
    return isme;
}

-(BOOL)isFriend {
    BOOL myFriend = self.friendPending;
    BOOL friended = self.friendWaiting;
    
    if (myFriend && friended) {
        return YES;
    }
    return NO;
}

//request pending
- (BOOL)friendPending {
    return [[EWSession sharedSession].currentUser.cachedInfo[kCachedFriends] containsObject:self.objectId];
}

//wait for friend acceptance
- (BOOL)friendWaiting {
    return [self.cachedInfo[kCachedFriends] containsObject:[EWSession sharedSession].currentUser.objectId];
}

- (NSString *)genderObjectiveCaseString {
    NSString *str = [self.gender isEqualToString:@"male"]?@"him":@"her";
    return str;
}

#pragma mark - My Stuffs
+ (NSArray *)myActivities {
    NSArray *activities = [EWSession sharedSession].currentUser.activities.allObjects;
    return [activities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.updatedAt ascending:NO]]];
}

+ (NSArray *)myUnreadNotifications {
    NSArray *notifications = [self myNotifications];
    NSArray *unread = [notifications filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"completed == nil"]];
    return unread;
}

+ (NSArray *)myNotifications {
    NSArray *notifications = [[EWSession sharedSession].currentUser.notifications allObjects];
    NSSortDescriptor *sortCompelet = [NSSortDescriptor sortDescriptorWithKey:@"completed" ascending:NO];
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
    NSSortDescriptor *sortImportance = [NSSortDescriptor sortDescriptorWithKey:@"importance" ascending:NO];
    notifications = [notifications sortedArrayUsingDescriptors:@[sortCompelet,sortImportance, sortDate]];
    return notifications;
}

+ (NSArray *)myAlarms {
    NSParameterAssert([NSThread isMainThread]);
    return [self alarmsForUser:[EWSession sharedSession].currentUser];
}

+ (EWAlarm *)myNextAlarm {
    float interval;
    EWAlarm *next;
    for (EWAlarm *alarm in [self myAlarms]) {
        float timeLeft = alarm.time.timeIntervalSinceNow;
        if (alarm.state) {
            if (interval == 0 || timeLeft < interval) {
                interval = timeLeft;
                next = alarm;
            }
        }
    }
    return next;
}

+ (NSArray *)alarmsForUser:(EWPerson *)user{
    NSMutableArray *alarms = [[user.alarms allObjects] mutableCopy];
    
    NSComparator alarmComparator = ^NSComparisonResult(id obj1, id obj2) {
        NSInteger wkd1 = [(EWAlarm *)obj1 time].weekdayNumber;
        NSInteger wkd2 = [(EWAlarm *)obj2 time].weekdayNumber;
        if (wkd1 > wkd2) {
            return NSOrderedDescending;
        }else if (wkd1 < wkd2){
            return NSOrderedAscending;
        }else{
            return NSOrderedSame;
        }
    };
    
    //sort
    NSArray *sortedAlarms = [alarms sortedArrayUsingComparator:alarmComparator];
    
    return sortedAlarms;
}

+ (void)requestFriend:(EWPerson *)person{
    [EWPersonManager getFriendsForPerson:[EWSession sharedSession].currentUser];
    [[EWSession sharedSession].currentUser addFriendsObject:person];
    [EWPerson updateCachedFriends];
    [EWNotificationManager sendFriendRequestNotificationToUser:person];
    
    [EWSync save];
}

+ (void)acceptFriend:(EWPerson *)person{
    [EWPersonManager getFriendsForPerson:[EWSession sharedSession].currentUser];
    [[EWSession sharedSession].currentUser addFriendsObject:person];
    [EWPerson updateCachedFriends];
    [EWNotificationManager sendFriendAcceptNotificationToUser:person];
    
    //update cache
    [EWStatisticsManager updateCacheWithFriendsAdded:@[person.serverID]];
    
    [EWSync save];
}

+ (void)unfriend:(EWPerson *)person{
    [EWPersonManager getFriendsForPerson:[EWSession sharedSession].currentUser];
    [[EWSession sharedSession].currentUser removeFriendsObject:person];
    [EWPerson updateCachedFriends];
    //TODO: unfriend
    //[EWServer unfriend:user];
    [EWSync save];
}

- (void)updateMyFriends {
    NSArray *friendsCached = self.cachedInfo[kCachedFriends]?:[NSArray new];
    NSSet *friends = self.friends;
    BOOL friendsNeedUpdate = self.isMe && friendsCached.count !=self.friends.count;
    if (!friends || friendsNeedUpdate) {
        
        DDLogInfo(@"Friends mismatch, fetch from server");
        
        //friend need update
        PFQuery *q = [PFQuery queryWithClassName:self.serverClassName];
        [q includeKey:@"friends"];
        [q whereKey:kParseObjectID equalTo:self.serverID];
        PFObject *user = [[EWSync findServerObjectWithQuery:q] firstObject];
        NSArray *friendsPO = user[@"friends"];
        if (friendsPO.count == 0) return;//prevent 0 friend corrupt data
        NSMutableSet *friendsMO = [NSMutableSet new];
        for (PFObject *f in friendsPO) {
            if ([f isKindOfClass:[NSNull class]]) {
                continue;
            }
            EWPerson *mo = (EWPerson *)[f managedObjectInContext:self.managedObjectContext];
            [friendsMO addObject:mo];
        }
        self.friends = [friendsMO copy];
        if (self.isMe) {
            [EWPerson updateCachedFriends];
        }
    }
}
#pragma mark - Cached Info
+ (void)updateCachedInfoStatementBasedOnMyAlarms {
    for (EWAlarm *alarm in [EWSession sharedSession].currentUser.alarms) {
        [self updateMyCachedInfoForAlarm:alarm];
    }
}

+ (void)updateMyCachedInfoForAlarm:(EWAlarm *)alarm {
    NSMutableDictionary *cache = [EWSession sharedSession].currentUser.cachedInfo.mutableCopy?:[NSMutableDictionary new];
    NSMutableDictionary *timeTable = [cache[kCachedAlarmTimes] mutableCopy]?:[NSMutableDictionary new];
    NSMutableDictionary *statements = [cache[kCachedStatements] mutableCopy]?:[NSMutableDictionary new];
    
    NSString *weekDay = alarm.time.weekday;
    timeTable[weekDay] = alarm.time;
    statements[weekDay] = alarm.statement;
    
    cache[kCachedAlarmTimes] = timeTable;
    cache[kCachedStatements] = statements;
    [EWSession sharedSession].currentUser.cachedInfo = cache;
    [EWSync save];
    DDLogVerbose(@"Updated cached alarm times: %@, statement: %@", timeTable, statements);
}

+ (void)updateCachedFriends {
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWPerson *localMe = [[EWSession sharedSession].currentUser inContext:localContext];
        NSSet *friends = [localMe.friends valueForKey:kParseObjectID];
        NSMutableDictionary *cache = localMe.cachedInfo.mutableCopy;
        cache[kCachedFriends] = friends.allObjects;
        localMe.cachedInfo = [cache copy];
    }];
}
#pragma mark - Parsed
+ (EWPerson *)findOrCreatePersonWithParseObject:(PFUser *)user{
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

//FIXME: took too long, need to optimize, maybe use one server call. 
//check my relation, used for new installation with existing user
+ (void)updateMe{
    NSDate *lastCheckedMe = [[NSUserDefaults standardUserDefaults] valueForKey:kLastCheckedMe];
    BOOL good = [EWPersonManager validatePerson:[EWSession sharedSession].currentUser];
    if (!good || !lastCheckedMe || lastCheckedMe.timeElapsed > kCheckMeInternal) {
        if (!good) {
            DDLogError(@"Failed to validate me, refreshing from server");
        }else if (!lastCheckedMe) {
            DDLogError(@"Didn't find lastCheckedMe date, start to refresh my relation in background");
        }else{
            DDLogError(@"lastCheckedMe date is %@, which exceed the check interval %d, start to refresh my relation in background", lastCheckedMe.date2detailDateString, kCheckMeInternal);
        }
        
        [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
            EWPerson *localMe = [[EWSession sharedSession].currentUser inContext:localContext];
            [localMe refreshRelatedWithCompletion:^{
                
                [EWPersonManager updateCachedFriends];
                [EWUserManagement updateFacebookInfo];
            }];
            //TODO: we need a better sync method
            //1. query for medias
            
            
            //2. check
        }];
        
        
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kLastCheckedMe];
    }
}
@end
