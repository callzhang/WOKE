//
//  EWStore.h
//  EarlyWorm
//
//  Data Manager manages all data related tasks, such as login check and data synchronization with server
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Woke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWSync.h"

@interface EWDataStore : NSObject
@property (nonatomic, retain) NSDate *lastChecked;//The date that last sync with server
+ (EWDataStore *)sharedInstance;
@end


