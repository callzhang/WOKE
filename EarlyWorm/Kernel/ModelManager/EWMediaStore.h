//
//  EWMediaStore.h
//  EarlyWorm
//
//  Created by Lei on 8/2/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#include <stdlib.h>
#import "EWPersonStore.h"

@class EWMediaItem;
@interface EWMediaStore : NSObject //EWStore

//you don't need to see all medias
@property (nonatomic) NSArray *allMedias;
//@property (nonatomic) NSManagedObjectContext *context;

+ (EWMediaStore *)sharedInstance;

//add
- (EWMediaItem *)createMedia;

//delete
//- (void)removeMediaItem:(EWMediaItem *)mi;
- (void)deleteAllMedias;

//search
/**
 Fetch media by author
 */
- (NSArray *)mediaCreatedByPerson:(EWPerson *)person;
/**
 Fetch media by receiver
 */
- (NSArray *)mediasForPerson:(EWPerson *)person;
//edit




//- (NSString *)mediaArchievePath;

@end
