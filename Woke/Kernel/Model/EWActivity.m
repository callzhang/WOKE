#import "EWActivity.h"
#import "EWSession.h"

const struct EWActivityTypes EWActivityTypes = {
    .media = @"media",
    .friendship = @"friendship"
};

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
        EWPerson *owner = (EWPerson *)[ownerPO managedObjectInContext:mainContext];
        self.owner = owner;
        if (!self.owner) {
            good = NO;
        }
    }
    if (!self.type) {
        self.type = selfPO[EWActivityAttributes.type];
        if (!self.type) {
            good = NO;
        }
    }
    
    //TODO: check more values
    
    return good;
}

- (EWActivity *)createWithMedia:(EWMedia *)media {
    EWActivity *activity = [EWActivity newActivity];
    activity.type = EWActivityTypes.media;
    [activity addMediasObject:media];
    
    return activity;
}


- (EWActivity *)createWithPerson:(EWPerson *)person friended:(BOOL)friended {
    EWActivity *activity = [EWActivity newActivity];
    activity.type = EWActivityTypes.friendship;
    activity.friendedValue = friended;
    activity.friendID = person.objectId;
    
    return activity;
}


@end
