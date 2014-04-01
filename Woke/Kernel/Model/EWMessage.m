//
//  EWMessage.m
//  EarlyWorm
//
//  Created by Lei on 10/11/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWMessage.h"
#import "EWGroup.h"
#import "EWPerson.h"
#import "StackMob.h"

@implementation EWMessage

@dynamic createddate;
@dynamic ewmessage_id;
@dynamic lastmoddate;
@dynamic media;
@dynamic text;
@dynamic time;
@dynamic groupTask;
@dynamic recipient;
@dynamic sender;
@dynamic task;

- (id)init
{
    self = [super init];
    if (self) {
        [self setValue:[self assignObjectId] forKey:[self primaryKeyField]];
    }
    return self;
}
@end
