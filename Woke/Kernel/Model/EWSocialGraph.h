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
@property (nonatomic, retain) NSDictionary *facebookFriends;
@property (nonatomic, retain) NSDictionary *weiboFriends;
@end
