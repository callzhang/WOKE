//
//  EWSync.h
//  Woke
//
//  Created by Lee on 9/24/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <Parse/Parse.h>
#import "Reachability.h"
#import "NSManagedObject+EWSync.h"
#import "PFObject+EWSync.h"
#import "EWServerObject.h"

extern NSManagedObjectContext *mainContext;
typedef void (^EWSavingCallback)(void);



#pragma mark - Sync parameters
#define kServerTransformTypes               @{@"CLLocation": @"PFGeoPoint"} //localType: serverType
#define kServerTransformClasses             @{@"EWPerson": @"_User"} //localClass: serverClass
#define attributeUploadSkipped              @[kParseObjectID, kUpdatedDateKey, @"score"]
//#define kUserClass                          @"EWPerson"
//#define classSkipped                        @[@"EWPerson"]


//Server update time
#define kStalelessInterval                  30
#define kUploadLag                          10
#define kCacheLifeTime                      60*60 //1hr

//attribute stored on ManagedObject to identify corresponding PFObject on server
#define kParseObjectID                      @"objectId"
//Attribute stored on PFObject to identify corresponding ManagedObject on SQLite, not used
#define kManagedObjectID                    @"objectID"
//The timestamp when MO gets updated from PO
#define kUpdatedDateKey                     @"updatedAt"
//Not used
#define kCreatedDateKey                     @"createdAt"
//Parse update queue
#define kParseQueueInsert                   @"parse_queue_insert"
#define kParseQueueUpdate                   @"parse_queue_update"
#define kParseQueueDelete                   @"parse_queue_delete"
#define kParseQueueWorking                  @"parse_queue_working"
#define kParseQueueRefresh                  @"parse_queue_refresh"//queue for refresh
#define kUserID                             @"user_object_id"
#define kUsername                           @"username"



@interface EWSync : NSObject
@property NSMutableArray *saveCallbacks; //MO save callback
@property Reachability *reachability;
@property NSMutableDictionary *serverObjectPool;
@property NSMutableDictionary *changeRecords;
@property NSMutableArray *saveToLocalItems;
@property NSMutableArray *deleteToLocalItems;
@property BOOL isUploading;




+ (EWSync *)sharedInstance;
- (void)setup;

#pragma mark - Connectivity
+ (BOOL)isReachable;

#pragma mark - Parse Server methods
/**
 The main save function, it save and upload to the server
 */
+ (void)save;
+ (void)saveWithCompletion:(EWSavingCallback)block;
+ (void)saveAllToLocal:(NSArray *)MOs;
/**
 The main method of server update/insert/delete.
 And save ManagedObject.
 @discussion Please do not call this method directly. It is scheduled when you call save method.
 */
- (void)uploadToServer;

/*
 Resume uploading at startup.
 **/
- (void)resumeUploadToServer;

/**
 *Update or Insert PFObject according to given ManagedObject
 *
 *1. First decide create or find parse object, handle error if necessary
 *
 *2. Update PO value and relation with given MO. (-updateValueFromManagedObject:) If related PO doesn't exist, create a PO async, and assign the newly created related PO to the relation.
 *
 *3. Save PO in background.
 *
 *4. When saved, assign parseID to MO
 *
 *5. Perform save callback block for this PO
 */
- (void)updateParseObjectFromManagedObject:(NSManagedObject *)managedObject;

/**
 Find or delete ManagedObject by Entity and by Server Object
 @discussion This method only updates attributes of MO, not relationship. So it is only used to refresh value of specific MO
 */
//+ (NSManagedObject *)findOrCreateManagedObjectWithParseObjectID:(NSString *)objectId;

/**
 Delete PFObject in server
 */
- (void)deleteParseObject:(PFObject *)parseObject;

/**
 Perform save callback for managedObject
 */
//- (void)performSaveCallbacksWithParseObject:(PFObject *)parseObject andManagedObjectID:(NSManagedObjectID *)managedObjectID;
/**
 Access Global Save Callback dictionary and add blcok with key of ManagedObjectID
 */
- (void)addSaveCallback:(PFObjectResultBlock)callback forManagedObjectID:(NSManagedObjectID *)objectID;


#pragma mark - Queue
//update queue
- (NSSet *)updateQueue;
- (void)appendUpdateQueue:(NSManagedObject *)mo;
- (void)removeObjectFromUpdateQueue:(NSManagedObject *)mo;
//insert queue
- (NSSet *)insertQueue;
- (void)appendInsertQueue:(NSManagedObject *)mo;
- (void)removeObjectFromInsertQueue:(NSManagedObject *)mo;
//uploading queue
- (NSSet *)workingQueue;
- (void)appendObjectToWorkingQueue:(NSManagedObject *)mo;
- (void)removeObjectFromWorkingQueue:(NSManagedObject *)mo;
//delete queue
- (NSSet *) deleteQueue;
- (void)appendObjectToDeleteQueue:(PFObject *)object;
- (void)removeObjectFromDeleteQueue:(PFObject *)object;
//worker
- (NSSet *)getObjectFromQueue:(NSString *)queue;
- (void)appendObject:(NSManagedObject *)mo toQueue:(NSString *)queue;
- (BOOL)contains:(NSManagedObject *)mo inQueue:(NSString *)queue;

#pragma mark - CoreData
+ (NSManagedObject *)managedObjectWithClass:(NSString *)className withID:(NSString *)objectID;
+ (BOOL)validateSO:(EWServerObject *)mo;
+ (BOOL)validateSO:(EWServerObject *)mo andTryToFix:(BOOL)tryFix;

#pragma mark - Parse helper methods
//PO query
+ (NSArray *)findServerObjectWithQuery:(PFQuery *)query;
+ (NSArray *)findServerObjectWithQuery:(PFQuery *)query error:(NSError **)error;
+ (void)findServerObjectInBackgroundWithQuery:(PFQuery *)query completion:(PFArrayResultBlock)block;
//- (PFObject *)getCachedParseObjectForID:(NSString *)parseID;
//- (void)setCachedParseObject:(PFObject *)PO;
/**
 1. Try to get PO from cache
 2. If not, then request a network call with query cache life of 1 hour
 */
- (PFObject *)getParseObjectWithClass:(NSString *)class ID:(NSString *)ID error:(NSError **)error;

@end




@interface NSString (EWSync)
- (NSString *)serverType;
- (NSString *)serverClass;
- (BOOL)skipUpload;
@end
