//
//  EWStatsManager.h
//  EarlyWorm
//
//  Created by Lei on 10/11/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EWPerson, EWTaskItem, EWTaskStore, EWPersonStore;

@interface EWStatsManager : NSObject
+(EWStatsManager *)sharedInstance;
-(NSArray *)pastTasksForPerson:(EWPerson *)person;
-(NSDictionary *)statsForPerson:(EWPerson *)person;
@end
