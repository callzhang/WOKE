//
//  EWSocialGraphManager.m
//  Woke
//
//  Created by Lei on 4/16/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWSocialGraphManager.h"
#import "EWPerson.h"

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

- (EWSocialGraph *)socialGraphForPerson:(EWPerson *)person{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"owner == %@", person.username];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWSocialGraph"];
    request.predicate = predicate;
    NSArray *graph = [[EWDataStore currentContext] executeFetchRequestAndWait:request error:NULL];
    
    if (graph.count > 1) {
        NSLog(@"*** More than one graph for user %@ found, please check!", person.username);
    }else if (graph.count == 1){
        return graph[0];
    }else{
        //need to create the graph
        EWSocialGraph *sg = [self createSocialGraphForPerson:person];
        return sg;
    }
    return nil;
}


- (EWSocialGraph *)createSocialGraphForPerson:(EWPerson *)person{
    EWSocialGraph *sg = [NSEntityDescription insertNewObjectForEntityForName:@"EWSocialGraph" inManagedObjectContext:[EWDataStore currentContext]];
    //assign id
    [sg assignObjectId];
    //owner string
    sg.owner = person.username;
    //save
    [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
        //[NSException raise:@"Failed in creating social graph" format:@"error: %@",error.description];
        NSLog(@"Failed in creating social graph: %@", error.description );
    }];
    NSLog(@"Created new social graph for user %@", person.name);
    return sg;
}

@end
