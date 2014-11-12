//
//  EWActivityManager.h
//  Woke
//
//  Created by Lei Zhang on 10/29/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"

extern NSString *const EWActivityTypeAlarm;
extern NSString *const EWActivityTypeFriendship;
extern NSString *const EWActivityTypeMedia;



@interface EWActivityManager : NSObject
+ (EWActivityManager *)sharedManager;
+ (NSArray *)myActivities;
+ (void)completeActivity:(EWActivity *)activity;
@property (nonatomic, strong) EWActivity *currentAlarmActivity;
@end
