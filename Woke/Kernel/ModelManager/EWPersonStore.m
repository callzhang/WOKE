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

#define everyoneCheckTimeOut            600
#define numberOfRelevantUsers           @100 //number of relevant users returned
#define radiusOfRelevantUsers           @-1  //search radius in kilometers for relevant users

//===========the global shortcut to currentUser ===========
EWPerson *me;
//=========================================================

@interface EWPersonStore(){
    NSDate *timeEveryoneChecked;
}

@end

@implementation EWPersonStore
@synthesize everyone;
@synthesize currentUser;

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

-(EWPerson *)getPersonByID:(NSString *)ID{
    //ID is username
    if(!ID) return nil;
    EWPerson *person = [EWPerson findFirstByAttribute:@"username" withValue:ID];
    
    if (!person){
        //First find user on server
        PFUser *user = [PFUser currentUser];
        NSParameterAssert([user.username isEqualToString:ID]);
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
    
    if (error && list.count == 0) {
        NSLog(@"*** Failed to get friends list: %@", error.description);
        //get ramdom person
        PFQuery *q = [PFQuery queryWithClassName:@"EWPerson"];
        q.limit = 100;
        error = nil;
        list = [q findObjects:&error];
        if (error) {
            NSLog(@"*** Failed to get anyone: %@", error.description);
        }
    }
    
    for (NSString *parseId in list) {
        PFQuery *query = [PFUser query];
        PFUser *user = (PFUser*)[query getObjectWithId:parseId];
        EWPerson *person = (EWPerson *)user.managedObject;
        float score = 99 - [list indexOfObject:parseId];
        person.score = [NSNumber numberWithFloat:score];
        [allPerson addObject:person];
    }
    
    [EWPersonStore me].score = @100;
    NSLog(@"Received everyone list: %@", [allPerson valueForKey:@"name"]);
    //return
    everyone = [allPerson copy];
    timeEveryoneChecked = [NSDate date];
    [[EWDataStore currentContext] saveToPersistentStoreAndWait];
    
    
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
    [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];

    //Alarm
    [EWAlarmManager.sharedInstance deleteAllAlarms];
    //task
    [EWTaskStore.sharedInstance deleteAllTasks];
    //media
    //[EWMediaStore.sharedInstance deleteAllMedias];
    //check
    [EWTaskStore.sharedInstance checkScheduledNotifications];
    
    [MBProgressHUD hideAllHUDsForView:rootViewController.view animated:YES];
    
    [EWDataStore save];
    //person
    //me = nil;
    
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
    }
}

#pragma mark - Friend
- (void)requestFriend:(EWPerson *)user{
    [me addFriendsObject:user];
    [EWNotificationManager sharedInstance];
}

@end
