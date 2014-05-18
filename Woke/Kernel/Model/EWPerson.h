//
//  EWPerson.h
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@import CoreLocation;
#import "_EWPerson.h"
@interface EWPerson : _EWPerson
@property (nonatomic) CLLocation* lastLocation;
@property (nonatomic) UIImage *profilePic;
@property (nonatomic) UIImage *bgImage;

- (id)initNewUserInContext:(NSManagedObjectContext *)context;

@end
