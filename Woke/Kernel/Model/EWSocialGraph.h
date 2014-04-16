//
//  EWSocialGraph.h
//  Woke
//
//  Created by Lei on 4/16/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EWSocialGraph : NSManagedObject

@property (nonatomic, retain) NSString * ewsocialgraph_id;
@property (nonatomic, retain) NSDictionary * facebook_friends;
@property (nonatomic, retain) NSDate * createddate;
@property (nonatomic, retain) NSDate * lastmoddate;
@property (nonatomic, retain) NSString * sm_owner;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSDictionary * weibo_friends;
@end
