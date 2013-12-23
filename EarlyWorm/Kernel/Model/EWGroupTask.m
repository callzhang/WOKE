//
//  EWGroupTask.m
//  EarlyWorm
//
//  Created by Lei on 10/11/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWGroupTask.h"
#import "EWMediaItem.h"
#import "EWPerson.h"
#import "EWMessage.h"
#import "StackMob.h"

@implementation EWGroupTask

@dynamic added;
@dynamic city;
@dynamic createddate;
@dynamic ewgrouptask_id;
@dynamic lastmoddate;
@dynamic region;
@dynamic time;
@dynamic medias;
@dynamic messages;
@dynamic participents;

- (id)init
{
    self = [super init];
    if (self) {
        [self setValue:[self assignObjectId] forKey:[self primaryKeyField]];
    }
    return self;
}
@end
