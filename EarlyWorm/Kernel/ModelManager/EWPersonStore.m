//
//  EWPersonStore.m
//  EarlyWorm
//
//  Created by Lei on 8/16/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWPersonStore.h"
#import "EWMediaStore.h"
#import "EWPerson.h"
#import "EWIO.h"
#import "EWDatabaseDefault.h"
#import "EWAlarmManager.h"
#import "EWTaskStore.h"
#import "NSDate+Extend.h"
#import "StackMob.h"
#import "EWAppDelegate.h"
#import "EWLogInViewController.h"

@implementation EWPersonStore
//@synthesize model, context;
@synthesize currentUser;

+(EWPersonStore *)sharedInstance{
    static EWPersonStore *sharedPersonStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPersonStore_ = [[EWPersonStore alloc] init];
    });
        
    
    return sharedPersonStore_;
}

//=======This method doesn't seem to be called========
-(EWPerson *)createPersonWIthUsername:(NSString *)username{
    NSManagedObjectContext *context = [[[SMClient defaultClient] coreDataStore] contextForCurrentThread];
    EWPerson *newUser = [[EWPerson alloc] initNewUserInContext:context];
    [newUser setValue:username forKey:[newUser primaryKeyField]];
    
    [context saveOnSuccess:^{
        NSLog(@"User %@ created!", username);
    } onFailure:^(NSError *error){
        [NSException raise:@"Unable to create user" format:@"Reason: %@", error.description];
    }];

    return newUser;
}

- (EWPerson *)currentUser{
    /*
    if (!currentUser) {
        if ([[SMClient defaultClient] isLoggedIn]) {
            [[SMClient defaultClient] getLoggedInUserOnSuccess:^(NSDictionary *result){
                // Result contains a dictionary representation of the user object
                NSLog(@"Current logged in user: %@",result);
                currentUser = [EWPersonStore.sharedInstance getPersonByID:result[@"username"]];
            } onFailure:^(NSError *err){
                // Error
                NSLog(@"Failed to get logged in user: %@", err.description);
                //quick login
                [[EWLogInViewController sharedInstance] viewDidLoad];
            }];
        }
    }
    */
    return currentUser;
}

-(EWPerson *)getPersonByID:(NSString *)ID{
    NSFetchRequest *userFetch = [[NSFetchRequest alloc] initWithEntityName:@"EWPerson"];
    userFetch.predicate = [NSPredicate predicateWithFormat:@"username == %@", ID];
    userFetch.relationshipKeyPathsForPrefetching = @[@"alarms", @"tasks"];
    NSManagedObjectContext *context = [[[SMClient defaultClient] coreDataStore] contextForCurrentThread];
    userFetch.returnsObjectsAsFaults = NO;
    NSError *err;
    NSArray *result = [context executeFetchRequestAndWait:userFetch error:&err];
    if ([result count] != 1) {
        // There should only be one result
        [NSException raise:@"More than one user fetched" format:@"Check username:%@",ID];
    };
    
    return (EWPerson *)result[0];
}

- (NSArray *)everyone{
    NSFetchRequest *userFetch = [[NSFetchRequest alloc] initWithEntityName:@"EWPerson"];
    NSManagedObjectContext *context = [[[SMClient defaultClient] coreDataStore] contextForCurrentThread];
    return [context executeFetchRequestAndWait:userFetch error:NULL];
}

@end
