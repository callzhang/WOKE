//
//  EWMediaItem.h
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_EWMediaItem.h"

#define kMediaTypeBuzz      @"buzz"
#define kMediaTypeVoice     @"voice"

@class EWGroupTask, EWPerson, EWTaskItem;
@interface EWMediaItem : _EWMediaItem
@property (nonatomic, retain) NSData *audio;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic) BOOL played;
@property (nonatomic) NSInteger priority;
@property (nonatomic, retain) UIImage *thumbnail;

-(UIImage *)setThumbnailDataFromImage:(UIImage *)image;

@end


//@interface EWMediaItem (CoreDataGeneratedAccessors)

//- (void)addGroupTask:(NSSet*)value_;
//- (void)removeGroupTask:(NSSet*)value_;
//- (void)addGroupTaskObject:(EWGroupTask*)value_;
//- (void)removeGroupTaskObject:(EWGroupTask*)value_;
//
//- (void)addTasks:(NSSet*)value_;
//- (void)removeTasks:(NSSet*)value_;
//- (void)addTasksObject:(EWTaskItem*)value_;
//- (void)removeTasksObject:(EWTaskItem*)value_;

//@end