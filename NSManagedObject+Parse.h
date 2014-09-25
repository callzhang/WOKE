//
//  NSManagedObject(Parse).h
//  Woke
//
//  Created by Lee on 9/25/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject(Parse)
/**
 Update ManagedObject from correspoinding Server Object
 
 *1) First assign the attribute value from server object
 
 *2) Iterate through the relations
 **   -> Delete obsolete related object.
 **   -> For each end point in relationship, To-Many or To-One, find or create MO and assign value to that relationship.
 @discussion The attributes and relationship are updated in sync.
 */
- (void)updateValueAndRelationFromParseObject:(PFObject *)object;

/**
 Get conterparty Parse Object and assign value to self
 */
- (PFObject *)parseObject;
/**
 Get PO only
 */
- (PFObject *)getParseObjectWithError:(NSError **)error;
/**
 Create a parse object
 */
- (void)createParseObjectWithCompletion:(void (^)(void))block;

/**
 Refresh ManagedObject value from server in background
 @discussion If the ParseID is not found on this ManagedObject, an insert action will performed.
 */
- (void)refreshInBackgroundWithCompletion:(void (^)(void))block;

/**
 Refresh ManagedObject value from server in the current thread
 @discussion If the ParseID is not found on this ManagedObject, an insert action will performed.
 */
- (void)refresh;

/**
 *Refresh related MO from server in background.
 *
 *This method iterates all objects related to the MO and refresh (updatedDate) to make sure my relevant data is copied locally.
 *
 *TODO: It also checks that if any data on server has duplication.
 *@discussion it is usually used for current user object (me)
 */
- (void)refreshRelatedWithCompletion:(void (^)(void))block;

/**
 Update object from PO for value, and related PO that is returned as Array of pointers
 The goal is to call server once and get as much as possible.
 */
- (void)refreshShallowWithCompletion:(void (^)(void))block;

/**
 Assign only attribute values (not relation) to the ManagedObject from the Parse Object
 */
- (void)assignValueFromParseObject:(PFObject *)object;

/**
 Save ManagedObjectID into update queue in userDefaults
 */
- (void)updateEventually;

/**
 Save ManagedObjectID into delete queue in userDefaults
 */
- (void)deleteEventually;

/**
 Changed keys beyond those excluded.
 */
- (NSArray *)changedKeys;

#pragma mark - Network
/**
 Mark MO as to save locally and remove MO from upload queue
 */
- (void)saveToLocal;
/**
 Mark MO to upload to server and insert MO to upload queue
 */
- (void)saveToServer;

#pragma mark - Helper methods
/**
 Reflex method to search for runtime attributes
 */
- (NSString *)getPropertyClassByName:(NSString *)name;

/**
 Check if the MO's updatedAt time is more than the server refresh interval
 */
- (BOOL)isOutDated;

//Parse objectId
- (NSString *)serverID;

@end


@interface NSEntityDescription (EWSync)
- (NSString *)serverClassName;
@end
