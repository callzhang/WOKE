#import "_EWActivity.h"

extern const struct EWActivityType {
    __unsafe_unretained NSString *media = @"media";
    __unsafe_unretained NSString *friendship = @"friendship";
};

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
