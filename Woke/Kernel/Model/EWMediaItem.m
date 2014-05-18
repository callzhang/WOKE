//
//  EWMediaItem.m
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWMediaItem.h"
#import "EWAlarmItem.h"
#import "EWPerson.h"
#import "EWTaskItem.h"

#import "EWDataStore.h"

@implementation EWMediaItem
@dynamic played;
@dynamic priority;
@dynamic image;
@dynamic thumbnail;
@synthesize audioKey;

- (NSString *)audioKey{
    NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"audioTempFile"];
    [self.audio writeToFile:path atomically:YES];
    return path;
}

//@synthesize thumbnail;

//- (id)init
//{
//    self = [super init];
//    if (self) {
//        [self setValue:[self assignObjectId] forKey:[self primaryKeyField]];
//    }
//    return self;
//}

//- (UIImage *)image{
//    if (!self.imageKey || [self.imageKey isEqualToString:@""]) {
//        return nil;
//    }
//    
//    if (!image) {
//        image = [UIImage imageWithData:[[EWDataStore sharedInstance] getRemoteDataWithKey:self.audioKey]];
//    }
//    
//    return image;
//}
//
//- (void)setImage:(UIImage *)img{ 
//    
//    //update memory
//    image = img;
//    
//    NSData *picData = UIImagePNGRepresentation(img);
//    //update cache
//    [[EWDataStore sharedInstance] updateCacheForKey:self.imageKey withData:picData];
//    
//    //update server
//    self.imageKey = [SMBinaryDataConversion stringForBinaryData:picData name:@"media.png" contentType:@"image/png"];
//    
//    [[EWDataStore currentContext] save];
//}



- (UIImage *)thumbnail{
    if (!thumbnail && self.image) {
        thumbnail = [self setThumbnailDataFromImage:self.image];
    }
    return thumbnail;
}

//generate thumbnail from image
- (UIImage *)setThumbnailDataFromImage:(UIImage *)img
{
    //get orig size
    CGSize origImageSize = img.size;
    
    //size of the thumbnail
    CGRect newRect = CGRectMake(0, 0, 40, 40);
    
    //ratio
    float ratio = MAX(newRect.size.width/origImageSize.width, newRect.size.height/origImageSize.height);
    
    //****Creates a bitmap-based graphics context with the specified options.
    UIGraphicsBeginImageContextWithOptions(newRect.size, NO, 0.0);
    
    //The UIBezierPath class lets you define a path consisting of straight and curved line segments and render that path in your custom views.
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:newRect cornerRadius:5.0];
    
    //make all subsequent drawing clip to this rounded rectangle
    //Intersects the area enclosed by the receiver’s path with the clipping path of the current graphics context and makes the resulting shape the current clipping path. This method modifies the visible drawing area of the current graphics context. After calling it, subsequent drawing operations result in rendered content only if they occur within the fill area of the specified path.
    [path addClip];
    
    //center the image in the thumbnail rect
    CGRect targetRect;
    targetRect.size.width = ratio*origImageSize.width;
    targetRect.size.height = ratio*origImageSize.height;
    targetRect.origin.x = (newRect.size.width - targetRect.size.width)/2.0;
    targetRect.origin.y = (newRect.size.height - targetRect.size.height)/2.0;
    
    //****draw image on target
    [img drawInRect:targetRect];
    
    //****get thumbnail from context
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    //self.thumbnail = smallImage;
    //get PNG and set as archievable data
    //self.thumbnailData = UIImagePNGRepresentation(smallImage); //do not use self.thumbnail, you will get nothing!
    
    //****clean image context
    UIGraphicsEndImageContext();
    
    return smallImage;
}


//#pragma mark - Data
//- (void)prepareAudio{
//    if (!self.audio) {
//        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
//        dispatch_async(queue, ^{
//            NSLog(@"Downloading audio from internet: %@", self.audio);
//        });
//    }
//    
//}



@end
