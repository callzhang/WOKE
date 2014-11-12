#import "_EWActivity.h"


extern const struct EWActivityTypes {
    __unsafe_unretained NSString *media;
    __unsafe_unretained NSString *friendship;
} EWActivityTypes;

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
@end
