//
//  EWGroupStore.m
//  EarlyWorm
//
//  Created by Lei on 9/15/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWGroupStore.h"
#import "EWPerson.h"
#import "EWPersonStore.h"
#import "EWTaskStore.h"
#import "EWTaskItem.h"
#import "EWAlarmItem.h"
#import "NSDate+Extend.h"
//backend
#import "StackMob.h"

@implementation EWGroupStore
@synthesize autoGroup, myGroups;

+(EWGroupStore *)sharedInstance{
    static EWGroupStore *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWGroupStore alloc] init];
    });
    return sharedStore_;
}

- (id)init{
    self = [super init];
    if (self) {
        //context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
        autoGroup = self.autoGroup;
        myGroups = self.myGroups;
    }
    return self;
}


//my wakeup together group
- (EWGroup *)autoGroup{
    //first search in memory
    if (autoGroup) {
        if (![autoGroup.wakeupTime isOutDated]) {
            return autoGroup;
        }
    }
    
    EWPerson *me = currentUser;
    //Try to find group with topic "autoGroup" for the next day, if none then greate it
    for (EWGroup *group in me.groups) {
        if ([group.topic isEqualToString:autoGroupIndentifier]) {
            if (![group.wakeupTime isOutDated]) {
                return group;
            }
        }
    }
    //create auto group
    EWTaskItem *nextTask = [EWTaskStore.sharedInstance nextTaskAtDayCount:0 ForPerson:me];
    EWGroup *group = [self getGroupForTime:nextTask.time];
    
    //add me to the group if not added
    [group addMemberObject:me];
    
    //[self updateGroup:group];//fetch news
    [me addGroupsObject:group];//add to my group relation
    return group;
}


- (void)updateGroup:(EWGroup *)group{
    //update group and fetch updates
}


-(EWGroup *)createGroup{
    EWGroup *group = [NSEntityDescription insertNewObjectForEntityForName:@"EWGroup" inManagedObjectContext:[EWDataStore currentContext]];
    [[EWDataStore currentContext] saveOnSuccess:^{
        //
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error in creating Group" format:@"Reason: %@",error.description];
    }];
    
    return group;
}


- (EWGroup *)getGroupForTime:(NSDate *)time{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWGroup"];
    request.predicate = [NSPredicate predicateWithFormat:@"wakeupTime >= %@ AND wakeupTime < %@ AND topic == %@", time, [time nextAlarmIntervalTime], @"autoGroup"];
    NSArray *groups = [[EWDataStore currentContext] executeFetchRequestAndWait:request error:NULL];
    EWGroup *group;
    if (groups.count == 0) {
        //need to create the group
        group = [self createGroup];
        //properties for group
        group.topic = autoGroupIndentifier;
        group.name = [NSString stringWithFormat:@"Wake up tomorrow at %@", [time date2String]];
        group.statement = autoGroupStatement;
        group.image = [UIImage imageNamed:@"logoTest.png"];
        group.created = [NSDate date];
        //save
        [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:NULL];
    }else{
        group = groups[0];
    }
    
    return group;
}

@end
