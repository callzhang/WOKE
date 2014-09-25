//
//  EWStore.h
//  EarlyWorm
//
//  This class manages Core Data related properties and functions, such as context and model.
//  It also manages backend: StockMob related and Push notification registration
//  https://www.draw.io/?#G0B8EqrGjPaSeTczJtNEQ1dER3Rjg
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWSync.h"

//Server update time
#define kServerUpdateInterval            1800 //30 min
@interface EWDataStore : NSObject
@property (nonatomic, retain) NSDate *lastChecked;//The date that last sync with server
@end


