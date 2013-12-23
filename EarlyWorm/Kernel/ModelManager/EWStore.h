//
//  EWStore.h
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EWStore : NSObject

@property (nonatomic) NSManagedObjectContext *context;
@property (nonatomic) NSManagedObjectModel *model;

-(void)save;
-(NSString *)archievePath;
@end
