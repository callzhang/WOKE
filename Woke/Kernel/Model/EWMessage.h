//
//  EWMessage.h
//  EarlyWorm
//
//  Created by Lei on 10/11/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@class EWTaskItem, EWGroupTask;

@interface EWMessage : NSManagedObject
@property (nonatomic, retain) NSDate * createddate;
@property (nonatomic, retain) NSString * ewmessage_id;
@property (nonatomic, retain) NSDate * lastmoddate;
@property (nonatomic, retain) NSString * media;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) EWGroupTask *groupTask;
@property (nonatomic, retain) EWPerson *recipient;
@property (nonatomic, retain) EWPerson *sender;
@property (nonatomic, retain) EWTaskItem *task;
@end
