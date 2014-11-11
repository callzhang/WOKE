//
//  EWActivityManager.h
//  Woke
//
//  Created by Lei Zhang on 10/29/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"

NSString *const EWActivityTypeAlarm = @"alarm";
NSString *const EWActivityTypeFriendship = @"friendship";
NSString *const EWActivityTypeMedia = @"media";



@interface EWActivityManager : NSObject
+ (EWActivityManager *)sharedManager;
+ (NSArray *)myActivities;
+ (void)completeActivity:(EWActivity *)activity;
@property (nonatomic, strong) EWActivity *currentAlarmActivity;
@end
