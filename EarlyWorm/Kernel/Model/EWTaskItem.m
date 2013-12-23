//
//  EWTaskItem.m
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWTaskItem.h"
#import "EWAlarmItem.h"
#import "EWMediaItem.h"
#import "EWPerson.h"
#import "StackMob.h"

@implementation EWTaskItem

@dynamic added;
@dynamic completed;
@dynamic createddate;
@dynamic ewtaskitem_id;
@dynamic lastmoddate;
@dynamic length;
@dynamic state;
@dynamic statement;
@dynamic success;
@dynamic time;
@dynamic alarm;
@dynamic medias;
@dynamic messages;
@dynamic owner;
@dynamic waker;
@dynamic pastOwner;

- (EWTaskItem *)init{
    self = [super init];
    if (self) {
        [self setValue:[self assignObjectId] forKey:[self primaryKeyField]];
    }
    return self;
}

@end
