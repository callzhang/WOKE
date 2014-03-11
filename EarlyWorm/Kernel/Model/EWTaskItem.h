//
//  EWTaskItem.h
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_EWTaskItem.h"

@interface EWTaskItem : NSManagedObject {}
@property (nonatomic, retain) NSDate * added;
@property (nonatomic, retain) NSString * aws_id;
@property (nonatomic, retain) NSDictionary * buzzers;
@property (nonatomic, retain) NSString * buzzers_string;
@property (nonatomic, retain) NSDate * completed;
@property (nonatomic, retain) NSDate * createddate;
@property (nonatomic, retain) NSString * ewtaskitem_id;
@property (nonatomic, retain) NSDate * lastmoddate;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) NSString * statement;
@property (nonatomic, retain) NSNumber * success;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) EWAlarmItem *alarm;
@property (nonatomic, retain) NSSet *medias;
@property (nonatomic, retain) EWMessage *messages;
@property (nonatomic, retain) EWPerson *owner;
@property (nonatomic, retain) NSSet *waker;
@property (nonatomic, retain) EWPerson *pastOwner;

//custom methods
- (void)addBuzzer:(EWPerson *)person atTime:(NSDate *)time;

@end

@interface EWTaskItem (CoreDataGeneratedAccessors)

- (void)addMediasObject:(EWMediaItem *)value;
- (void)removeMediasObject:(EWMediaItem *)value;
- (void)addMedias:(NSSet *)values;
- (void)removeMedias:(NSSet *)values;

- (void)addWakerObject:(EWPerson *)value;
- (void)removeWakerObject:(EWPerson *)value;
- (void)addWaker:(NSSet *)values;
- (void)removeWaker:(NSSet *)values;

@end