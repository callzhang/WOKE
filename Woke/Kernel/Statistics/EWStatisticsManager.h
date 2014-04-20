//
//  EWStatisticsManager.h
//  EarlyWorm
//
//  Created by Lei on 1/8/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"

@interface EWStatisticsManager : NSObject

@property (nonatomic, weak) EWPerson *person;
@property (nonatomic, weak) NSArray *tasks;
@property (nonatomic) NSNumber *aveWakeupTime;
@property (nonatomic) NSNumber *successRate;

- (NSInteger)wakability;
- (NSString *)wakabilityStr;
@end
