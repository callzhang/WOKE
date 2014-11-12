#import "_EWMedia.h"

#define kMediaTypeVoice     @"voice"

@interface EWMedia : _EWMedia


//new
+ (EWMedia *)newMedia;
//delete
- (void)remove;
//search
+ (EWMedia *)getMediaByID:(NSString *)mediaID;
//validate
- (BOOL)validate;
//ACL
- (void)createACL;
//download
- (void)downloadMediaFile;

//data
- (NSData *)audio;
- (NSString *)audioKey;
@end
