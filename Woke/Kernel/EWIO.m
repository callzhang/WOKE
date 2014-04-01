//
//  EWIO.m
//  EarlyWorm
//
//  Created by Lei on 8/19/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//
//  This class serves as the basic file input/output class that handles file namagement and memory management

#import "EWIO.h"
//#import "ASIdentifierManager.h"
#import <AdSupport/ASIdentifierManager.h>

@implementation EWIO

+ (NSString *)UUID{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    return uuid;
    
}

+ (NSString *)ADID{
    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    return adId;
}

+(void)clearMemory{
    //
}

@end
