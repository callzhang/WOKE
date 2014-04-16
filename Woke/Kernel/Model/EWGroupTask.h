//
//  EWGroupTask.h
//  EarlyWorm
//
//  Created by Lei on 10/11/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@class EWMediaItem, EWMessage, EWPerson;

@interface EWGroupTask : NSManagedObject

@property (nonatomic, retain) NSDate * added;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSDate * createddate;
@property (nonatomic, retain) NSString * ewgrouptask_id;
@property (nonatomic, retain) NSDate * lastmoddate;
@property (nonatomic, retain) NSString * region;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSSet *medias;
@property (nonatomic, retain) EWMessage *messages;
@property (nonatomic, retain) NSSet *participents;
@end

@interface EWGroupTask (CoreDataGeneratedAccessors)

- (void)addMediasObject:(EWMediaItem *)value;
- (void)removeMediasObject:(EWMediaItem *)value;
- (void)addMedias:(NSSet *)values;
- (void)removeMedias:(NSSet *)values;

- (void)addParticipentsObject:(EWPerson *)value;
- (void)removeParticipentsObject:(EWPerson *)value;
- (void)addParticipents:(NSSet *)values;
- (void)removeParticipents:(NSSet *)values;

@end
