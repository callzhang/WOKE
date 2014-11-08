#import "_EWActivity.h"


extern const struct EWAlarmAttributes {
    __unsafe_unretained NSString *media;
    __unsafe_unretained NSString *friendship;
} EWActivityType;

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
