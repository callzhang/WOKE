//
//  EWIO.m
//  EarlyWorm
//
//  Created by Lei on 8/19/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//
//  This class serves as the basic file input/output class that handles file namagement and memory management

#import "EWIO.h"

@implementation EWIO

+(NSString *)UUID{
    CFUUIDRef ID = CFUUIDCreate(kCFAllocatorDefault); //core foundation = CF
    CFStringRef IDString = CFUUIDCreateString(kCFAllocatorDefault, ID);
    NSString *key = (__bridge NSString*)IDString;//bridge cast CF object to NS object
    CFRelease(ID);
    CFRelease(IDString);
    
    return key;
    
}

+(void)clearMemory{
    //
}

@end
