//
//  EWAlarmItem.h
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_EWAlarmItem.h"

@class EWTaskItem;

@interface EWAlarmItem : _EWAlarmItem
@property (nonatomic) BOOL important;
@property (nonatomic) BOOL state;
@end