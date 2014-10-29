#import "EWActivity.h"
#import "EWSession.h"

@interface EWActivity ()

// Private interface goes here.

@end

@implementation EWActivity

+ (EWActivity *)newActivity{
    EWActivity *activity = [[EWActivity alloc] init];
    activity.owner = [EWSession sharedSession].currentUser;
    activity.updatedAt = [NSDate date];
    return activity;
}

- (void)remove{
    [self deleteEntity];
    [EWSync save];
}

- (BOOL)validate{
    BOOL good = YES;
    PFObject *selfPO = self.parseObject;
    if (!self.owner) {
        PFUser *ownerPO = selfPO[EWActivityRelationships.owner];
        EWPerson *owner = [selfPO managedObjectInContext:[EWSession mainContext]];
        self.owner = owner;
        if (!self.owner) {
            good = NO;
        }
    }
    if (!self.type) {
        self.type = selfPO.type;
        if (!self.type) {
            good = NO;
        }
    }
    
    //TODO: check more values
    
    return good;
}


@end
