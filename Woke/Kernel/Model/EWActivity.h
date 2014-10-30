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
@end
