#import "_EWMediaFile.h"

@interface EWMediaFile : _EWMediaFile {}
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) UIImage *thumbnail;
@property (nonatomic, retain) NSString *audioKey;

+ (EWMediaFile *)newMediaFile;
- (void)remove;
+ (EWMediaFile *)findMediaFileByID:(NSString *)ID;
- (BOOL)validate;
@end
