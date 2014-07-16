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
@property (nonatomic) NSNumber *aveWakingLength;
@property (nonatomic) NSString *aveWakingLengthString;
@property (nonatomic) NSString *aveWakeUpTime;
@property (nonatomic) NSNumber *successRate;
@property (nonatomic) NSString *successString;

- (NSInteger)wakability;
- (NSString *)wakabilityStr;
@end
