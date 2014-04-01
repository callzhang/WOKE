//
//  EWImageStore.h
//  EarlyWorm
//
//  Created by Lei on 8/2/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWImageStore : NSObject

@property (nonatomic) NSMutableDictionary *allImages;

+ (EWImageStore *)sharedInstance;
- (void)setImage:(UIImage *)i forKey:(NSString *)key;
- (void)deleteImageForKey:(NSString *)key;
- (UIImage *)imageForKey:(NSString *)key;
- (NSString *)imagePathForKey:(NSString *)key;

@end
