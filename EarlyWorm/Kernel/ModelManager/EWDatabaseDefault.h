//
//  EWDatabaseDefault.h
//  EarlyWorm
//
//  Created by Lei on 10/18/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWDatabaseDefault : NSObject
@property (nonatomic, retain) NSDictionary *defaults;
@property (nonatomic, retain) NSArray *ringtoneList;


+(EWDatabaseDefault *)sharedInstance;
- (void)initData;
- (void)setDefault;
- (void)cleanData;
//-(void)createPerson;
//-(void)createMediaItem;
//-(void)createGroup;
@end
