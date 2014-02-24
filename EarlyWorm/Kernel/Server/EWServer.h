//
//  EWServer.h
//  EarlyWorm
//
//  Created by Lee on 2/21/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"

@interface EWServer : NSObject
+ (void)getPersonWakingUpForTime:(NSDate *)timeSince1970 location:(SMGeoPoint *)geoPoint callbackBlock:(SMFullResponseSuccessBlock)successBlock;
+ (void)buzz:(EWPerson *)user;
@end
