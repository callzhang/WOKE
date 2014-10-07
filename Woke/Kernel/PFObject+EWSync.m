//
//  PFObject+EWSync.m
//  Woke
//
//  Created by Lee on 9/25/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "PFObject+EWSync.h"
#import "EWSync.h"

@implementation PFObject(EWSync)
- (void)updateFromManagedObject:(NSManagedObject *)managedObject{
    NSError *err;
    [self fetchIfNeeded:&err];
    if (err && self.objectId) {
        if (err.code == kPFErrorObjectNotFound) {
            DDLogError(@"PO %@(%@) not found on server!", self.parseClassName, self.objectId);
            NSManagedObject *trueMO = [managedObject.managedObjectContext existingObjectWithID:managedObject.objectID error:NULL];
            if (trueMO) {
                [managedObject setValue:nil forKeyPath:kParseObjectID];
            }
        }
        else{
            DDLogError(@"Trying to upload but PO error fetching: %@. Skip!", err.description);
        }
        
        [managedObject uploadEventually];
        return;
    }
    
    //If PO just created, the PO is newer than MO, this is not reliable. Also, it is against the intention. Therefore, the intention of upload should overload the fact that PO is newer.
    //    if (self.isNewerThanMO) {
    //        NSLog(@"@@@ Trying to update MO %@, but PO is newer! Please check the code.(%@ -> %@)", managedObject.entity.name, [managedObject valueForKey:kUpdatedDateKey], self.updatedAt);
    //        return;
    //    }
    
    
    NSArray *changeValues = [[EWSync sharedInstance].changeRecords objectForKey:managedObject.objectID];
    [managedObject.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *obj, BOOL *stop) {
        //for now, we just use changed value as a mean to exam our theory
        BOOL expectChange = NO;
        if ([changeValues containsObject:key]){
            expectChange = YES;
        }
        
        //check if changed
        if (key.skipUpload) {
            return;
        }
        
        //=============== ATTRIBUTES ===============
        id value = [managedObject valueForKey:key];
        id POValue = [self valueForKey:key];
        
        //there could have some optimization that checks if value equals to PFFile value, and thus save some network calls. But in order to compare there will be another network call to fetch, the the comparison is redundant.
        if ([value isKindOfClass:[NSData class]]) {
            //data
            if (!expectChange && POValue) {
                DDLogVerbose(@"MO attribute %@(%@)->%@ not change", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], key);
                return;
            }
            //TODO: video file
            NSString *fileName = [NSString stringWithFormat:@"%@.m4a", [PFUser currentUser][@"name"]];
            PFFile *dataFile = [PFFile fileWithName:fileName data:value];
            [self setObject:dataFile forKey:key];
        }
        else if ([value isKindOfClass:[UIImage class]]){
            //image
            if (!expectChange && POValue) {
                DDLogVerbose(@"MO attribute %@(%@)->%@ not change", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], key);
                return;
            }
            PFFile *dataFile = [PFFile fileWithName:@"Image.png" data:UIImagePNGRepresentation((UIImage *)value)];
            //[dataFile saveInBackground];//TODO: handle file upload exception
            [self setObject:dataFile forKey:key];
        }
        else if ([value isKindOfClass:[CLLocation class]]){
            //location
            if (!expectChange && POValue) {
                DDLogVerbose(@"MO attribute %@(%@)->%@ no change", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], key);
                return;
            }
            PFGeoPoint *point = [PFGeoPoint geoPointWithLocation:(CLLocation *)value];
            [self setObject:point forKey:key];
        }
        else if(value){
            [self setObject:value forKey:key];
            
        }
        else{
            //value is nil, delete PO value
            if ([self.allKeys containsObject:key]) {
                DDLogWarn(@"!!! Data %@ empty on MO %@(%@), please check!", key, managedObject.entity.name, managedObject.serverID);
                [self removeObjectForKey:key];
            }
        }
        
    }];
    
    //=============== relation ===============
    NSMutableDictionary *mutableRelationships = [managedObject.entity.relationshipsByName mutableCopy];
    [mutableRelationships enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
        id relatedManagedObjects = [managedObject valueForKey:key];
        if (relatedManagedObjects){
            if ([obj isToMany]) {
                //To-Many relation
                //First detect if has inverse relation, if not, we use Array to represent the relation
                //Exceptin: if the relation is linked to a user, we still use PFRelation as the size of PFObject will be too large for Array to store PFUser
                //TODO: in the next release we need to use Array for all relation except relation to EWPerson
                if (!obj.inverseRelationship/* && ![key isEqualToString:kUserClass]*/) {
                    //No inverse relation, use array of pointer
                    
                    NSSet *relatedMOs = [managedObject valueForKey:key];
                    NSMutableArray *relatedPOs = [NSMutableArray new];
                    for (NSManagedObject *MO in relatedMOs) {
                        //PFObject *PO = [EWDataStore getCachedParseObjectForID:MO.serverID];
                        //if (!PO) {
                        PFObject *PO = [PFObject objectWithoutDataWithClassName:MO.serverClassName objectId:[MO valueForKey:kParseObjectID]];
                        //}
                        if (PO.objectId) {
                            [relatedPOs addObject:PO];
                        }else{
                            NSLog(@"objectId not found");
                        }
                        
                    }
                    [self setObject:[relatedPOs copy] forKey:key];
                    return;
                }
                
                //========================== relation ==========================
                PFRelation *parseRelation = [self relationForKey:key];
                
                //Find related PO to delete async
                NSMutableArray *relatedParseObjects = [[[parseRelation query] findObjects] mutableCopy];
                if (relatedParseObjects.count) {
                    NSArray *relatedParseObjectsToDelete = [relatedParseObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT %K IN %@", kParseObjectID, [relatedManagedObjects valueForKey:kParseObjectID]]];
                    for (PFObject *PO in relatedParseObjectsToDelete) {
                        [parseRelation removeObject:PO];
                        //We don't update the inverse PFRelation as they should be updated from that MO
                        NSLog(@"~~~> To-many relation on PO %@(%@)->%@(%@) deleted when updating from MO", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], obj.name, PO.objectId);
                    }
                }
                
                //related managedObject that needs to add
                for (NSManagedObject *relatedManagedObject in relatedManagedObjects) {
                    NSString *parseID = relatedManagedObject.serverID;
                    if (parseID) {
                        //the pfobject already exists, need to inspect PFRelation to determin add or remove
                        
                        //PFObject *relatedParseObject = [EWDataStore getCachedParseObjectForID:parseID];
                        PFObject *relatedParseObject = [PFObject objectWithoutDataWithClassName:relatedManagedObject.serverClassName objectId:parseID];
                        //[relatedParseObject fetchIfNeeded];
                        [parseRelation addObject:relatedParseObject];
                        //NSLog(@"+++> To-many relation on PO %@(%@)->%@(%@) added when updating from MO", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], obj.name, relatedParseObject.objectId);
                        
                    } else {
                        __block PFObject *blockObject = self;
                        __block PFRelation *blockParseRelation = parseRelation;
                        //set up a saving block
                        //NSLog(@"Relation %@ -> %@ save block setup", blockObject.parseClassName, relatedManagedObject.entity.serverClassName);
                        PFObjectResultBlock connectRelationship = ^(PFObject *object, NSError *error) {
                            //the relation can only be additive, which is not a problem for new relation
                            [blockParseRelation addObject:object];
                            [blockObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                NSLog(@"PO Relation %@(%@) -> %@ (%@) established in PO save callback", blockObject.parseClassName, blockObject.objectId, object.parseClassName, object.objectId);
                                if (error) {
                                    NSLog(@"Failed to save: %@", error.description);
                                    @try {
                                        [blockObject saveEventually];
                                    }
                                    @catch (NSException *exception) {
                                        [managedObject uploadEventually];
                                        DDLogError(@"saveEventually failed, move to uploadEventually, got exeption:%@", exception);
                                    }
                                }
                            }];
                        };
                        
                        //add to global save callback distionary
                        [[EWSync sharedInstance] addSaveCallback:connectRelationship forManagedObjectID:relatedManagedObject.objectID];
                        
                        //add relatedMO to insertQueue
                        if (![[EWSync sharedInstance] contains:relatedManagedObject inQueue:kParseQueueWorking]) {
                            [[EWSync sharedInstance] appendInsertQueue:relatedManagedObject];
                        }
                    }
                }
            }
            else {
                //TO-One relation
                NSManagedObject *relatedMO = [managedObject valueForKey:key];
                NSString *parseID = relatedMO.serverID;
                PFObject *relatedPO ;//TODO: test if we can use empty PO
                if (parseID) {
                    NSError *error;
                    relatedPO = [[EWSync sharedInstance] getParseObjectWithClass:relatedMO.serverClassName ID:relatedMO.serverID error:&error];
                    if (error) {
                        DDLogError(@"Failed to get related PO: %@", error);
                        if (kPFErrorObjectNotFound) {
                            [relatedMO setValue:nil forKey:kParseObjectID];
                        }
                    }
                    else {
                        [self setObject:relatedPO forKey:key];
                    }
                    //NSLog(@"+++> To-one relation on PO %@(%@)->%@(%@) added when updating from MO", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], obj.name, relatedPO.objectId);
                }
                if (!parseID || !relatedPO){
                    //MO doesn't have parse id, save to parse
                    __block PFObject *blockObject = self;
                    //set up a saving block
                    PFObjectResultBlock connectRelationship = ^(PFObject *object, NSError *error) {
                        [blockObject setObject:object forKey:key];
                        [blockObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            //relationship can be saved regardless of network condition.
                            if (error) {
                                NSLog(@"Failed to save: %@", error.description);
                                @try {
                                    [blockObject saveEventually];
                                }
                                @catch (NSException *exception) {
                                    [managedObject uploadEventually];
                                }
                                
                            }
                        }];
                    };
                    //add to global save callback distionary
                    [[EWSync sharedInstance] addSaveCallback:connectRelationship forManagedObjectID:relatedMO.objectID];
                }
            }
        }
        
        else{
            
            //relation cannot be to-many, as it's always has value
            //empty related object, delete PO relationship
            if ([self valueForKey:key]) {
                DDLogVerbose(@"Empty relationship on MO %@(%@) -> %@, delete PO relation.", managedObject.entity.name, self.objectId, obj.name);
                [self removeObjectForKey:key];
                
            }
        }
        
    }];
    //Only save when network is available so that MO can link with PO
    //[self saveEventually];
    
}

- (NSManagedObject *)managedObjectInContext:(NSManagedObjectContext *)context{
    
    if (!self.objectId) {
        return nil;
    }
    
    if (!context) {
        context = mainContext;
    }
    NSMutableArray *MOs = [[NSClassFromString(self.localClassName) findByAttribute:kParseObjectID withValue:self.objectId inContext:context] mutableCopy];
    //NSManagedObject *mo = [NSClassFromString(self.localClassName) MR_findFirstByAttribute:kParseObjectID withValue:self.objectId inContext:context];
    while (MOs.count > 1) {
        NSLog(@"Find duplicated MO for ID %@", self.objectId);
        NSManagedObject *mo_ = MOs.lastObject;
        [MOs removeLastObject];
        [mo_ deleteEntityInContext:context];
        
        [[EWSync sharedInstance].deleteToLocalItems addObject:self.objectId];
        
        //remove from the update queue
        [[EWSync sharedInstance] removeObjectFromDeleteQueue:self];
    }
    NSManagedObject *mo = MOs.firstObject;
    
    if (!mo) {
        //if managedObject not exist, create it locally
        mo = [NSClassFromString(self.localClassName) MR_createInContext:context];
        [mo assignValueFromParseObject:self];
        DDLogInfo(@"+++> MO created: %@ (%@)", self.localClassName, self.objectId);
    }else{
        
        if ([mo valueForKey:kUpdatedDateKey] && (mo.isOutDated || self.isNewerThanMO)) {
            
            [mo assignValueFromParseObject:self];
            //[EWDataStore saveToLocal:mo];//mo will be saved later
        }
    }
    
    return mo;
}

- (BOOL)isNewerThanMO{
    NSDate *updatedPO = [self valueForKey:kUpdatedDateKey];
    NSManagedObject *mo = [NSClassFromString(self.localClassName) findFirstByAttribute:kParseObjectID withValue:self.objectId];
    NSDate *updatedMO = [mo valueForKey:kUpdatedDateKey];
    if (updatedPO && updatedMO) {
        if ([updatedPO timeIntervalSinceDate:updatedMO]>1) {
            DDLogVerbose(@"PO is newer than MO: %@ > %@", updatedPO, updatedMO);
            return YES;
        }else{
            return NO;
        }
    }else if (updatedMO){
        return NO;
    }else if (updatedPO){
        return YES;
    }
    return NO;
}

- (NSString *)localClassName{
    NSDictionary *map = kServerTransformClasses;
    NSString *localClass = [[map allKeysForObject:self.parseClassName] firstObject];
    return localClass ?: self.parseClassName;
}
@end
