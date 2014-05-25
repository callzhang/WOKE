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
/*
@property (nonatomic, strong) NSString* aws_id;
@property (nonatomic, strong) NSDate* birthday;
@property (nonatomic, strong) NSString* city;
@property (nonatomic, strong) NSDate* createdAt;
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* facebook;
@property (nonatomic, strong) NSString* gender;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* objectId;
@property (nonatomic, strong) id preference;
@property (nonatomic, strong) NSString* region;
@property (nonatomic, strong) NSString* statement;
@property (nonatomic, strong) NSDate* updatedAt;
@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) NSString* weibo;
*/

@end
