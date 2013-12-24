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

#import "StackMob.h"
#import "NSString+MD5.h"
#import "FTWCache.h"

@implementation EWMediaItem

@dynamic created;
@synthesize image;
@dynamic imageKey;
@dynamic videoKey;
@synthesize audio;
@dynamic audioKey;
@dynamic message;
@dynamic mediaType;
@synthesize thumbnail;
@dynamic title;
@dynamic author;
@dynamic tasks;
@dynamic groupTask;
@dynamic createddate;
@dynamic lastmoddate;
@dynamic ewmediaitem_id;

- (id)init
{
    self = [super init];
    if (self) {
        [self setValue:[self assignObjectId] forKey:[self primaryKeyField]];
    }
    return self;
}

- (UIImage *)image{
    if (!image) {
        __block UIImage *img;
        if ([SMBinaryDataConversion stringContainsURL:self.imageKey]) {
            //read from URL
            NSURL* imageURL = [NSURL URLWithString:self.imageKey];
            
            NSString *key = [imageURL.absoluteString MD5Hash];
            NSData *data = [FTWCache objectForKey:key];
            if (data) {
                //data in cache
                img = [UIImage imageWithData:data];
                
            } else {
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
                dispatch_async(queue, ^{
                    NSData *data = [NSData dataWithContentsOfURL:imageURL];
                    [FTWCache setObject:data forKey:key];
                    img = [UIImage imageWithData:data];
                });
            }
        } else {
            img = [UIImage imageWithData:[SMBinaryDataConversion dataForString:self.imageKey]];
        }
        image = img;
    }
    return image;
}

- (void)setImage:(UIImage *)img{
    NSData *imgData = UIImageJPEGRepresentation(img, 0.7);
    self.imageKey = [SMBinaryDataConversion stringForBinaryData:imgData name:@"alarmImage.jpg" contentType:@"image/jpg"];
    //save and merge
    NSManagedObjectContext *context = [[[SMClient defaultClient] coreDataStore] contextForCurrentThread];
    [context saveOnSuccess:^{
        [context refreshObject:self mergeChanges:YES];
    } onFailure:^(NSError *error) {
        [NSException raise:@"Unable to save image" format:@"Reason: %@", error.description];
    }];
}

#pragma mark - AUDIO
- (NSData *)audio{
    if(!audio){
        __block NSData *data;
        if ([SMBinaryDataConversion stringContainsURL:self.audioKey]) {
            //read from url
            NSURL *audioURL = [NSURL URLWithString:self.audioKey];
            NSString *key = [audioURL.absoluteString MD5Hash];
            data = [FTWCache objectForKey:key];
            if (data) {
                self.audio = data;
            }else{
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
                dispatch_async(queue, ^{
                    data = [NSData dataWithContentsOfURL:audioURL];
                    [FTWCache setObject:data forKey:key];
                });
            }
        }else if(self.audioKey.length > 200){
            //string contains data
            data = [SMBinaryDataConversion dataForString:self.audioKey];
        }else{
            //string is a local file
            NSArray *array = [self.audioKey componentsSeparatedByString:@"."];
            
            NSString *file = nil;
            NSString *type = nil;
            if (array.count == 2) {
                file = [array firstObject];
                type = [array lastObject];
            }else{
                [NSException raise:@"Unexpected file format" format:@"Please provide a who file name with extension"];
            }
            NSString *filePath = [[NSBundle mainBundle] pathForResource:file ofType:type];
            data = [NSData dataWithContentsOfFile:filePath];
        }
        
        //save data
        self.audio = data;
    }
    return audio;
}


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



@end
