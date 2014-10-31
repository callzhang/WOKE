#import "_EWActivity.h"


NSString *const EWActivityTypeMedia = @"media";
NSString *const EWActivityTypeFriendship = @"friendship";

@interface EWActivity : _EWActivity {}
// add
+ (EWActivity *)newActivity;
// delete
- (void)remove;
// search
//+ (EWActivity *)findActivityWithID:(NSString *)ID;
// valid
- (BOOL)validate;

- (EWActivity *)createMediaActivityWithMedia:(EWMedia *)media;
- (EWActivity *)createFriendshipActivityWithPerson:(EWPerson *)person friended:(BOOL)friended;
+ (NSArray *)myActivities;
@end
