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
#import "EWIO.h"
#import "EWAlarmManager.h"
#import "EWTaskStore.h"
#import "NSDate+Extend.h"
#import "StackMob.h"
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
-(EWPerson *)createPersonWIthUsername:(NSString *)username{
    //NSManagedObjectContext *context = [[[SMClient defaultClient] coreDataStore] contextForCurrentThread];
    EWPerson *newUser = [[EWPerson alloc] initNewUserInContext:[EWDataStore currentContext]];
    [newUser setValue:username forKey:[newUser primaryKeyField]];
    
    [[EWDataStore currentContext] saveOnSuccess:^{
        NSLog(@"User %@ created!", username);
    } onFailure:^(NSError *error){
        [NSException raise:@"Unable to create user" format:@"Reason: %@", error.description];
    }];

    return newUser;
}

-(EWPerson *)getPersonByID:(NSString *)ID{
    if(!ID) return nil;
    
    NSFetchRequest *userFetch = [[NSFetchRequest alloc] initWithEntityName:@"EWPerson"];
    userFetch.predicate = [NSPredicate predicateWithFormat:@"username == %@", ID];
    userFetch.relationshipKeyPathsForPrefetching = @[@"alarms", @"tasks", @"friends"];//doesn't work for SM
    userFetch.returnsObjectsAsFaults = NO;
    NSError *err;
    NSArray *result = [[EWDataStore currentContext] executeFetchRequestAndWait:userFetch error:&err];
    if ([result count] > 1) {
        // There should only be one result
        [NSException raise:@"Failed to fetch user" format:@"%lu user fetched. Check username:%@", (unsigned long)result.count, ID];
    }else if (result.count == 0){
        result = [[EWDataStore currentContext] executeFetchRequestAndWait:userFetch returnManagedObjectIDs:NO options:[EWDataStore optionFetchNetworkElseCache] error:NULL];
        if (result.count != 1) {
            EWAlert(@"Failed to fetch user. Please try again.");
        }else{
            NSLog(@"Fetched remote user: %@", ID);
        }
    }
    
    EWPerson *user = (EWPerson *)result[0];
    NSLog(@"User %@ data has fetched", user.name);
    if ([user isFault]) {
        //[NSException raise:@"user fatched is fault" format:@"check your code"];
        NSLog(@"user is faulted, try to get faults filled");
        [[EWDataStore currentContext] refreshObject:currentUser mergeChanges:YES];
        NSLog(@"There are %lu alarms and %lu tasks", (unsigned long)user.alarms.count, (unsigned long)user.tasks.count);
    }
    return user;
}

- (NSArray *)everyone{
    NSFetchRequest *userFetch = [[NSFetchRequest alloc] initWithEntityName:@"EWPerson"];
    userFetch.fetchLimit = 50;
    //option
    SMRequestOptions *options;
    if (![timeEveryoneChecked isOutDated] && timeEveryoneChecked != nil) {
        options = [EWDataStore optionFetchCacheElseNetwork];
    }else{
        options = [EWDataStore optionFetchNetworkElseCache];
        timeEveryoneChecked = [NSDate date];
    }
    //fetch
    NSArray *allPerson = [[EWDataStore currentContext] executeFetchRequestAndWait:userFetch returnManagedObjectIDs:NO options:options error:NULL];
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

- (void)checkRelations{
    //friends
    for (EWPerson *friend in currentUser.friends) {
        NSLog(@"You have friend %@", friend.name);
    }
    
    //media
    for (EWMediaItem *media in currentUser.medias) {
        NSLog(@"You are the author of media %@", media.title);
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
    
    [[EWDataStore currentContext] saveOnSuccess:^{
        //person
        //currentUser = nil;
        
        //cache clear
        //[[EWDataStore sharedInstance].coreDataStore resetCache];
        
        //alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clean Data" message:@"All data has been cleaned." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        //logout
        [[SMClient defaultClient] logoutOnSuccess:^(NSDictionary *result) {
            //facebook logout
            [[FBSession activeSession] closeAndClearTokenInformation];
            [EWUserManagement login];
        } onFailure:^(NSError *error) {
            [NSException raise:@"Error log out" format:@"Reason: %@", error.description];
        }];
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error in save after clean" format:@"Reason: %@", error.description];
    }];
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
