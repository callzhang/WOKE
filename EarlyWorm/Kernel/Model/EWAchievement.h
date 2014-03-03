//
//  EWAchievement.h
//  EarlyWorm
//
//  Created by Lei on 1/9/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
//#import "_EWAchievement.h"

@class EWPerson;

@interface EWAchievement : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * ewachievement_id;
@property (nonatomic, retain) NSString * image_key;
@property (nonatomic, retain) NSString * explaination;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) EWPerson *owner;
@property (nonatomic, retain) UIImage *image;

@end
