//
//  EWAlarmItem.h
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_EWAlarm.h"

@class EWTaskItem;

@interface EWAlarm : _EWAlarm

// add
+ (EWAlarm *)newAlarm;

// delete
- (void)remove;
+ (void)deleteAll;

//validate
- (BOOL)validate;

@end