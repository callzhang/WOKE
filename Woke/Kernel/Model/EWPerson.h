//
//  EWPerson.h
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_EWPerson.h"

@import CoreLocation;

@interface EWPerson : _EWPerson
@property (nonatomic, strong) CLLocation* lastLocation;
@property (nonatomic, strong) UIImage *profilePic;
@property (nonatomic, strong) UIImage *bgImage;
@property (nonatomic, strong) NSDictionary *preference;
@property (nonatomic, strong) NSDictionary *cachedInfo;
@property (nonatomic, strong) NSArray *images;

- (BOOL)isMe;
- (BOOL)isFriend;
- (BOOL)friendPending;
- (BOOL)friendWaiting;
- (NSString *)genderObjectiveCaseString;

- (BOOL)validate;


+ (NSArray *)myActivities;
+ (NSArray *)myNotifications;
+ (NSArray *)myUnreadNotifications;
@end
