//
//  EWNotification.h
//  Woke
//
//  Created by Lei on 4/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_EWNotification.h"

@class EWPerson;

@interface EWNotification : NSManagedObject

@property (nonatomic) int64_t importance;
@property (nonatomic, retain) NSDictionary *lastLocation;
@property (nonatomic, retain) NSDictionary *userInfo;

@end
