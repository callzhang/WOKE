#import "EWGroup.h"
#import "StackMob.h"

@interface EWGroup ()

// Private interface goes here.

@end


@implementation EWGroup
@dynamic created;
@dynamic createddate;
@dynamic ewgroup_id;
@dynamic imageKey;
@dynamic lastmoddate;
@dynamic name;
@dynamic statement;
@dynamic topic;
@dynamic wakeupTime;
@dynamic admin;
@dynamic member;
@synthesize image;

- (id)init
{
    self = [super init];
    if (self) {
        [self setValue:[self assignObjectId] forKey:[self primaryKeyField]];
    }
    return self;
}


@end
