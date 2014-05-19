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

EWPerson *currentUser;

@interface EWPersonStore(){
    NSDate *timeEveryoneChecked;
}

@end

@implementation EWPersonStore
//@synthesize model, context;
//@synthesize currentUser;

+(EWPersonStore *)sharedInstance{
//    BOOL mainThread = [NSThread isMainThread];
//    if (!mainThread) {
//        NSLog(@"**** Person Store not on main thread ****");
//    }
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
-(EWPerson *)createPersonWIthParseObject:(PFUser *)user{
    EWPerson *newUser = (EWPerson *)[user managedObject];
    newUser.username = user.username;
    newUser.profilePic = [UIImage imageNamed:@"profile"];
    newUser.name = @"New User";
    
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
        //create one
        PFQuery *q = [PFUser query];
        [q whereKey:@"username" equalTo:ID];
        PFUser *user = [q findObjects][0];
        person = (EWPerson *)[self createPersonWIthParseObject:user];
        NSLog(@"User %@ data has CREATED", person.name);
    }else{
        person = (EWPerson *)result[0];
        NSLog(@"User %@ data has fetched", person.name);
    }
    

    return person;
}

- (NSArray *)everyone{

    //fetch
    NSArray *allPerson = [EWPerson findAll];
    //NSLog(@"Get a list of people: %@", [allPerson valueForKey:@"name"]);
//    //check
//    for (EWPerson *person in allPerson) {
//        if ([person isFault]) {
//            NSLog(@"Person %@ is faulted, fetching from server", person.name);
//            [[EWDataStore currentContext] refreshObject:person mergeChanges:YES];
//        }
//    }
    //return
    return allPerson;
    
}

- (EWPerson *)anyone{
    NSArray *everyone = [self everyone];
    NSInteger i = arc4random_uniform((uint16_t)everyone.count);
    EWPerson *one = everyone[i];
    return one;
}

- (void)checkRelations{
    //friends
    for (EWPerson *friend in currentUser.friends) {
        NSLog(@"You have friend %@", friend.name);
    }
    
    //media
    for (EWMediaItem *media in currentUser.medias) {
        NSLog(@"You are the author of media %@", media);
    }
}

//Danger Zone
- (void)purgeUserData{
    NSLog(@"Cleaning all cache and server data");
    //[context deleteObject:currentUser];
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
    //currentUser = nil;
    
    //cache clear
    //[[EWDataStore sharedInstance].coreDataStore resetCache];
    
    //alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clean Data" message:@"All data has been cleaned." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    //logout
    [EWUserManagement logout];
    

}

#pragma mark - Notification
- (void)userLoggedIn:(NSNotification *)notif{
    EWPerson *me = notif.userInfo[kUserLoggedInUserKey];
    currentUser = me;
}

- (void)userLoggedOut:(NSNotification *)notif{
    currentUser = nil;
}

@end
