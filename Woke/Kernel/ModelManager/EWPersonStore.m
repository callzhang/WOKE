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
    
    //[EWDataStore updateParseObjectFromManagedObject:newUser];
    
    [EWDataStore save];

    return newUser;
}

-(EWPerson *)getPersonByID:(NSString *)ID{
    //ID is username
    if(!ID) return nil;
    EWPerson *person;
    NSFetchRequest *userFetch = [[NSFetchRequest alloc] initWithEntityName:@"EWPerson"];
    userFetch.predicate = [NSPredicate predicateWithFormat:@"username == %@", ID];
    userFetch.relationshipKeyPathsForPrefetching = @[@"alarms", @"tasks", @"friends"];
    userFetch.returnsObjectsAsFaults = NO;
    NSError *err;
    NSArray *result = [[EWDataStore currentContext] executeFetchRequest:userFetch error:&err];
    
    if (result.count == 0){
        //First find user on server
        PFUser *user = [PFUser currentUser];
        NSParameterAssert([user.username isEqualToString:ID]);
        person = (EWPerson *)[user managedObject];
        NSLog(@"User %@ data has CREATED", person.name);
    }else{
        person = (EWPerson *)result[0];
        NSLog(@"User %@ data has fetched", person.name);
    }
    

    return person;
}

- (NSArray *)everyone{
    if (everyone && [[NSDate date] timeIntervalSinceDate:timeEveryoneChecked] < everyoneCheckTimeOut) {
        return everyone;
    }
    //fetch
    PFQuery *query = [PFUser query];
    NSArray *allUser = [query findObjects];
    NSMutableArray *allPerson = [NSMutableArray new];
    for (PFUser *user in allUser) {
        [allPerson addObject:user.managedObject];
    }
    //return
    everyone = [allPerson copy];
    timeEveryoneChecked = [NSDate date];
    
    
    return everyone;
}

- (EWPerson *)anyone{
    
    NSInteger i = arc4random_uniform((uint16_t)self.everyone.count);
    EWPerson *one = self.everyone[i];
    return one;
}

- (void)checkRelations{
    //friends
    for (EWPerson *friend in me.friends) {
        NSLog(@"You have friend %@", friend.name);
    }
    
    //media
    for (EWMediaItem *media in me.medias) {
        NSLog(@"You are the author of media %@", media);
    }
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
