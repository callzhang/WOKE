//
//  EWDeviceInfo.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-31.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWDeviceInfo.h"

@implementation EWDeviceInfo

double g_iOSVersion = 0;
double getiOSVersion() {
    if (g_iOSVersion < 0.1) {
        NSString *nsOsversion = [UIDevice currentDevice].systemVersion;
        g_iOSVersion = atof([nsOsversion UTF8String]);
    }
    return g_iOSVersion;
}

//+ (double)iOSVersion {
//    return getiOSVersion();
//}

+ (BOOL)isIOS5_Plus {
    return getiOSVersion() >= 5.0;
}

+ (BOOL)isIOS6_Plus {
    return getiOSVersion() >= 6.0;
}

+ (BOOL)isIOS7_Plus {
    return getiOSVersion() >= 7.0;
}

@end
