//
//  EWGroupStore.h
//  EarlyWorm
//
//  Created by Lei on 9/15/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "EWGroup.h"

@interface EWGroupStore : NSObject
@property (nonatomic, retain) NSArray *myGroups; //all my groups
@property (nonatomic) EWGroup *autoGroup;
//@property (nonatomic) NSManagedObjectContext *context;
@property (nonatomic) UIImage *image;

+(EWGroupStore *) sharedInstance;

//add
-(EWGroup *) createGroup;

//delete
//-(void)removeGroup:(EWGroup *)group;

//find
- (EWGroup *)getGroupForTime:(NSDate *)time;

//change
- (void)updateGroup:(EWGroup *)group;

//other
- (EWGroup *)autoGroup; //wakeup together group
@end
