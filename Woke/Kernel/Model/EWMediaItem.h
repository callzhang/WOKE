//
//  EWMediaItem.h
//  EarlyWorm
//
//  Created by Lei on 8/27/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
//#import "_EWMediaItem.h"

typedef enum{
    mediaTypeVoice,
    mediaTypeBuzz
} mediaType;

@class EWGroupTask, EWPerson, EWTaskItem;
@interface EWMediaItem : NSManagedObject
@property (nonatomic, retain) EWPerson *author;
@property (nonatomic, retain) NSData *audio;
@property (nonatomic, retain) NSString * audioKey;
@property (nonatomic, retain) NSString *buzzKey;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSDate * createddate;
@property (nonatomic, retain) NSString *ewmediaitem_id;
@property (nonatomic, retain) NSSet *groupTask;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSString * imageKey;
@property (nonatomic, retain) NSDate * lastmoddate;
@property (nonatomic, retain) NSString * message;
@property (nonatomic) BOOL played;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) UIImage *thumbnail;
@property (nonatomic, retain) NSString * videoKey;
@property (nonatomic, retain) NSSet *tasks;
@property (nonatomic) NSInteger type;

-(UIImage *)setThumbnailDataFromImage:(UIImage *)image;
//Data
/**
 Prepare audio data from audioKey
 */
- (void)prepareAudio;

@end


@interface EWMediaItem (CoreDataGeneratedAccessors)

- (void)addGroupTask:(NSSet*)value_;
- (void)removeGroupTask:(NSSet*)value_;
- (void)addGroupTaskObject:(EWGroupTask*)value_;
- (void)removeGroupTaskObject:(EWGroupTask*)value_;

- (void)addTasks:(NSSet*)value_;
- (void)removeTasks:(NSSet*)value_;
- (void)addTasksObject:(EWTaskItem*)value_;
- (void)removeTasksObject:(EWTaskItem*)value_;

@end