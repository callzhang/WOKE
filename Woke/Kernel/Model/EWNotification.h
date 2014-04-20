//
//  EWNotification.h
//  Woke
//
//  Created by Lei on 4/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EWPerson;

@interface EWNotification : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * completed;
@property (nonatomic, retain) NSDate *createddate;
@property (nonatomic, retain) NSString * ewnotification_id;
@property (nonatomic, retain) NSDate * lastmoddate;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSDictionary *userInfo;
@property (nonatomic, retain) NSString * userInfoString;
@property (nonatomic, retain) EWPerson *owner;
@property (nonatomic, retain) NSString * sender;

@end
