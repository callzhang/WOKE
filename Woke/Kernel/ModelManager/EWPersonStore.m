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

#define everyoneCheckTimeOut            600
#define numberOfRelevantUsers           @100 //number of relevant users returned
#define radiusOfRelevantUsers           @-1  //search radius in kilometers for relevant users

EWPerson *me;

@interface EWPersonStore(){
    NSDate *timeEveryoneChecked;
}

@end

@implementation EWPersonStore
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

#pragma mark - CREATE USER
-(EWPerson *)createPersonWithParseObject:(PFUser *)user{
    EWPerson *newUser = (EWPerson *)[user managedObject];
    newUser.username = user.username;
    newUser.profilePic = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", arc4random_uniform(15)]];
    newUser.name = kDefaultUsername;
    newUser.preference = kUserDefaults;
    newUser.cachedInfo = [NSDictionary new];
    
    //[EWDataStore updateParseObjectFromManagedObject:newUser];
    
    [EWDataStore save];

    return newUser;
}

-(EWPerson *)getPersonByID:(NSString *)ID{
    //ID is username
    if(!ID) return nil;
    EWPerson *person = [EWPerson findFirstByAttribute:@"username" withValue:ID];
    
    if (!person){
        //First find user on server
        PFUser *user = [PFUser currentUser];
        NSParameterAssert([user.username isEqualToString:ID]);
        person = (EWPerson *)[user managedObject];
        NSLog(@"Current user %@ data has CREATED", person.name);
    }else{
        NSLog(@"Current user %@ data has FETCHED", person.name);
    }
    
    if (person.isMe) {
        person.score = 100;
    }

    return person;
}

//Current User MO at background thread
+ (EWPerson *)me{
    if ([NSThread isMainThread]) {
        return me;
    }else{
        return [EWDataStore objectForCurrentContext:me];
    }
}

- (NSArray *)everyone{
    if (everyone && [[NSDate date] timeIntervalSinceDate:timeEveryoneChecked] < everyoneCheckTimeOut) {
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
    
    if (!error) {
        
        for (NSString *parseId in list) {
            PFQuery *query = [PFUser query];
            PFUser *user = (PFUser*)[query getObjectWithId:parseId];
            EWPerson *person = (EWPerson *)user.managedObject;
            float score = 99 - [list indexOfObject:parseId];
            person.score = score;
            [allPerson addObject:person];
        }
        [EWPersonStore me].score = 100;
        NSLog(@"Received everyone list: %@", [allPerson valueForKey:@"name"]);
        //return
        everyone = [allPerson copy];
        timeEveryoneChecked = [NSDate date];
        [[EWDataStore currentContext] saveToPersistentStoreAndWait];
    }else{
        NSLog(@"Failed to get friends list: %@", error.description);
    }
    return everyone;
}

- (EWPerson *)anyone{
    
    NSInteger i = arc4random_uniform((uint16_t)self.everyone.count);
    EWPerson *one = self.everyone[i];
    return one;
}


//Danger Zone
- (void)purgeUserData{
    NSLog(@"Cleaning all cache and server data");
    //[context deleteObject:me];
    //[context saveAndWait:NULL];
    //Alarm
    [EWAlarmManager.sharedInstance deleteAllAlarms];
    //task
    [EWTaskStore.sharedInstance deleteAllTasks];
    //media
    //[EWMediaStore.sharedInstance deleteAllMedias];
    //check
    [EWTaskStore.sharedInstance checkScheduledNotifications];
    
    [EWDataStore save];
    //person
    //me = nil;
    
    //cache clear
    //[[EWDataStore sharedInstance].coreDataStore resetCache];
    
    //alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clean Data" message:@"All data has been cleaned." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    //logout
    //[EWUserManagement logout];
    

}

#pragma mark - Notification
- (void)userLoggedIn:(NSNotification *)notif{
    EWPerson *user = notif.userInfo[kUserLoggedInUserKey];
    if (![me isEqual:user]) {
        me = user;
    }
    
}

- (void)userLoggedOut:(NSNotification *)notif{
    me = nil;
}

@end
