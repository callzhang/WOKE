//
//  EWSocialGraph.h
//  Woke
//
//  Created by Lei on 4/16/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_EWSocialGraph.h"

@interface EWSocialGraph : _EWSocialGraph
@property (nonatomic, strong) NSArray *facebookFriends;
@property (nonatomic, strong) NSArray *addressBookFriends;
@end
