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

- (EWActivity *)createWithMedia:(EWMedia *)media;
- (EWActivity *)createWithPerson:(EWPerson *)person friended:(BOOL)friended;
+ (NSArray *)myActivities;
@end
