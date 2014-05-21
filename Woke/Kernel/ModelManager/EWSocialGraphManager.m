//
//  EWSocialGraphManager.m
//  Woke
//
//  Created by Lei on 4/16/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWSocialGraphManager.h"
#import "EWPerson.h"
#import "EWPersonStore.h"
#import "EWUserManagement.h"

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

+ (EWSocialGraph *)mySocialGraph{
    EWPerson *me = [EWUserManagement currentUser];
    EWSocialGraph *sg = me.socialGraph;
    if (!sg) {
        sg = [[EWSocialGraphManager sharedInstance] createSocialGraphForPerson:me];
    }
    return sg;
}

- (EWSocialGraph *)socialGraphForPerson:(EWPerson *)person{
    if (person.socialGraph) {
        return person.socialGraph;
    }
    
    if ([person.username isEqualToString:currentUser.username]) {
        //need to create one for self
        EWSocialGraph *graph = [self createSocialGraphForPerson:person];
        return graph;
    }
    
    //refresh from server again
    [person refresh];
    
    return person.socialGraph;
}


- (EWSocialGraph *)createSocialGraphForPerson:(EWPerson *)person{
    EWSocialGraph *sg = [EWSocialGraph createEntity];

    //data
    sg.owner = person;
    //save
    //[EWDataStore save];
    NSLog(@"Created new social graph for user %@", person.name);
    return sg;
}

@end
