//
//  FTWCache.m
//  FTW
//
//  Created by Soroush Khanlou on 6/28/12.
//  Copyright (c) 2012 FTW. All rights reserved.
//

#import "FTWCache.h"
#import "NSString+MD5.h"

static NSTimeInterval cacheTime =  (double)3600*24*30*12;  //1year

@implementation FTWCache

+ (void) resetCache {
	[[NSFileManager defaultManager] removeItemAtPath:[FTWCache cacheDirectory] error:nil];
}

+ (NSString*) cacheDirectory {
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cacheDirectory = [paths objectAtIndex:0];
	cacheDirectory = [cacheDirectory stringByAppendingPathComponent:@"FTWCaches"];
	return cacheDirectory;
}

+ (NSData*) objectForKey:(NSString*)key {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filename = [self.cacheDirectory stringByAppendingPathComponent:key];
	
	if ([fileManager fileExistsAtPath:filename])
	{
		NSDate *modificationDate = [[fileManager attributesOfItemAtPath:filename error:nil] objectForKey:NSFileModificationDate];
		if ([modificationDate timeIntervalSinceNow] > cacheTime) {
			[fileManager removeItemAtPath:filename error:nil];
		} else {
			NSData *data = [NSData dataWithContentsOfFile:filename];
			return data;
		}
	}
	return nil;
}

+ (void) setObject:(NSData*)data forKey:(NSString*)key {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filename = [self.cacheDirectory stringByAppendingPathComponent:key];

	BOOL isDir = YES;
	if (![fileManager fileExistsAtPath:self.cacheDirectory isDirectory:&isDir]) {
		[fileManager createDirectoryAtPath:self.cacheDirectory withIntermediateDirectories:NO attributes:nil error:nil];
	}
	
	NSError *error;
	@try {
		[data writeToFile:filename options:NSDataWritingAtomic error:&error];
	}
	@catch (NSException * e) {
		//TODO: error handling maybe
	}
}

+ (NSString *)localPathForKey:(NSString *)key{
    NSString *hashKey = [key MD5Hash];
    if ([FTWCache objectForKey:hashKey]) {
        //has cache
        NSString *path = [[FTWCache cacheDirectory] stringByAppendingString:hashKey];
        NSLog(@"Find cache path: %@ for Key: %@", path, key);
        return path;
    }
    NSLog(@"Could not find local cache for remote content: %@", key);
    return nil;
}


@end
