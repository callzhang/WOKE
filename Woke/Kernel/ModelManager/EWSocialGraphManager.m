//
//  EWSocialGraphManager.m
//  Woke
//
//  Created by Lei on 4/16/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWSocialGraphManager.h"
#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWUserManagement.h"
#import "APAddressBook.h"
#import "APContact.h"

@interface EWSocialGraphManager()
@property (nonatomic, strong) APAddressBook *addressBook;
@end

@implementation EWSocialGraphManager

+ (EWSocialGraphManager *)sharedInstance{
    static EWSocialGraphManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!manager) {
            manager = [[EWSocialGraphManager alloc] init];
        }
    });
    
    return manager;
}

- (APAddressBook *)addressBook {
    if (!_addressBook) {
        _addressBook = [[APAddressBook alloc] init];
    }
    
    return _addressBook;
}

- (EWSocialGraph *)mySocialGraph{
    EWSocialGraph *sg = [EWSession sharedSession].currentUser.socialGraph;
    if (!sg) {
        sg = [self  createSocialGraphForPerson:[EWSession sharedSession].currentUser];
    }
    return sg;
}

- (EWSocialGraph *)socialGraphForPerson:(EWPerson *)person{
    if (person.socialGraph) {
        return person.socialGraph;
    }
    
    if (person.isMe) {
        //first check from PFUser
        PFObject *sg = [PFUser currentUser][EWPersonRelationships.socialGraph];
        if (sg) {
            EWSocialGraph *socialGraph = [sg managedObjectInContext:mainContext];
        }
        //need to create one for self
        EWSocialGraph *graph = [self createSocialGraphForPerson:person];
        return graph;
    }

    
    return person.socialGraph;
}

- (EWSocialGraph *)createSocialGraphForPerson:(EWPerson *)person{
    EWSocialGraph *sg = [EWSocialGraph createEntityInContext:person.managedObjectContext];
    sg.updatedAt = [NSDate date];

    //data
    sg.owner = person;
    //save
    //[EWSync save];
    NSLog(@"Created new social graph for user %@", person.name);
    return sg;
}

- (BOOL)hasAddressBookAccess {
    return [APAddressBook access] == APAddressBookAccessGranted;
}

- (void)testFindWithUsersCompletion:(void (^)(NSArray *users))completion {
    [self loadAddressBookCompletion:^(NSArray *contacts, NSError *error) {
        NSArray *emails = [contacts bk_map:^id(APContact *obj) {
            return obj.emails;
        }];
        
        NSMutableArray *allEmails = [NSMutableArray array];
        for (NSArray *obj in emails) {
            [allEmails addObjectsFromArray:obj];
        }
        
        [self getUsersFromParse:allEmails completion:^(NSArray *contacts, NSError *error) {
            DDLogInfo(@"contacts:%@", contacts);
            completion(contacts);
        }];
    }];
}

- (void)loadAddressBookCompletion:(void (^)(NSArray *contacts, NSError *error))completion {
    [self.addressBook loadContactsOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSArray *contacts, NSError *error) {
        DDLogInfo(@"got contacts: %@", contacts);
        NSArray *mapContacts = [contacts bk_map:^id(APContact *obj) {
            NSDictionary *contact = @{
                                      @"firstName": obj.firstName,
                                      @"middleName": obj.middleName,
                                      @"lastName": obj.lastName,
                                      @"emails": obj.emails,
                                      @"recordID": obj.recordID,
                                      @"socialProfiles": obj.socialProfiles,
                                      @"phones": obj.phones,
                                      @"phonesWithLabels": obj.phonesWithLabels
                                      };
            
            return contact;
        }];
        
        self.mySocialGraph.addressBookFriends = mapContacts;
        
        [EWSync save];
        
        if (completion) {
            completion(contacts, error);
        }
    }];
}

- (void)getUsersFromParse:(NSArray *)emails completion:(void (^)(NSArray *contacts, NSError *error))completion {
    [PFCloud callFunctionInBackground:@"findUsersWithEmails" withParameters:@{@"emails": emails} block:^(id object, NSError *error) {
        if (completion) {
            completion(object, error);
        }
    }];
}

@end
