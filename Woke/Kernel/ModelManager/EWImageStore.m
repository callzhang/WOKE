//
//  EWImageStore.m
//  EarlyWorm
//
//  Created by Lei on 8/2/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//
//  ImageStore is not using CoreData tech. It saves image info in disctionary. Then it saves the image file in Documents folder as CGData, and also keeps a copy as UIImage in dictionary.

#import "EWImageStore.h"

@implementation EWImageStore
@synthesize allImages;

+ (EWImageStore *)sharedInstance {
    static EWImageStore *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWImageStore alloc] init];
    });
    return sharedStore_;
}

- (id)init {
    self = [super init];
    if (self) {
        allImages = [[NSMutableDictionary alloc] init];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(clearCache:)
                   name:UIApplicationDidReceiveMemoryWarningNotification
                 object:nil];
    }
    return self;
}

//save image with key to core data and keep a copy in memory
- (void)setImage:(UIImage *)i forKey:(NSString *)key {
    [allImages setObject:i forKey:key];
    
    //create path for image
    NSString *imagePath = [self imagePathForKey:key];
    //get png representation of image
    NSData *d = UIImagePNGRepresentation(i);
    //save to path
    BOOL success = [d writeToFile:imagePath atomically:YES];
    if (success) {
        NSLog(@"image saved to image path folder");
    }else{
        NSLog(@"image NOT saved");
    }
}

- (void)deleteImageForKey:(NSString *)key {
    if (!key) return;
    [allImages removeObjectForKey:key];
    //delete image from file system
    NSString *path = [self imagePathForKey:key];
    [NSFileManager.defaultManager removeItemAtPath:path error:nil];
    NSLog(@"Image with key:%@ deleted", key);
}

//load image for key
- (UIImage *)imageForKey:(NSString *)key {
    //try to get image from dictionary first
    UIImage *result = [allImages objectForKey:key];
    //load from file if not able to load from dictioary
    if (!result) {
        //Creates and returns an image object by loading the image data from the file at the specified path.
        result = [UIImage imageWithContentsOfFile:[self imagePathForKey:key]];
        if (result) {
            [allImages setObject:result forKey:key];
            NSLog(@"image loaded from file");
        }else{
            NSLog(@"Error: unable to find %@", [self imagePathForKey:key]);
        }
    }
    return result;
}

- (NSString *)imagePathForKey:(NSString *)key {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = documentDirectories[0];
    return [documentDirectory stringByAppendingPathComponent:key];
}

//mamory management
//Removing an object from a dictionary relinquishes ownership of the object, so flushing the cache causes all of the images to lose an owner. Images that aren’t being used by other objects are destroyed, and when they are needed again, they will be reloaded from the filesystem. If an image is currently displayed in the DetailViewController’s imageView, then it will not be destroyed since it is owned by the imageView. When the DetailViewController’s imageView loses ownership of that image (either because the DetailViewController was popped off the stack or a new image was taken), then it is destroyed. It will be reloaded later if needed.
- (void)clearCache:(NSNotification *)note
{
    NSLog(@"flushing %lu image out of the cache", (unsigned long)[allImages count]);
    [allImages removeAllObjects];
}


@end
