#import "_EWMedia.h"

#define kMediaTypeVoice     @"voice"

@class EWGroupTask, EWPerson, EWMediaFile;
@interface EWMedia : _EWMedia


//new
- (EWMedia *)newMedia;
//delete
- (void)remove;
//search
+ (EWMedia *)getMediaByID:(NSString *)mediaID;
//validate
- (BOOL)validate;
//ACL
- (void)createACL;
@end
