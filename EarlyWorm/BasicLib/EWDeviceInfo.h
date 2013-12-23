//
//  EWDeviceInfo.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-31.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWDeviceInfo : NSObject

//+ (double)iOSVersion;

+ (BOOL)isIOS5_Plus;
+ (BOOL)isIOS6_Plus;
+ (BOOL)isIOS7_Plus;

@end
