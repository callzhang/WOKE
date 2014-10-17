//
//  EWMediaStore.m
//  EarlyWorm
//
//  Created by Lei on 8/2/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWMediaStore.h"
#import "EWMediaItem.h"
#import "EWImageStore.h"
#import "EWPerson.h"
#import "EWTaskManager.h"
#import "EWTaskItem.h"
#import "EWUserManagement.h"
#import "EWNotificationManager.h"
#import "EWNotification.h"

@implementation EWMediaStore
//@synthesize context, model;
@synthesize myMedias;
//@synthesize context;

+(EWMediaStore *)sharedInstance{
    NSParameterAssert([NSThread isMainThread]);
    static EWMediaStore *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWMediaStore alloc] init];
    });
    return sharedStore_;
}


- (NSArray *)myMedias{
    NSParameterAssert([NSThread isMainThread]);
    return [self mediasForPerson:me];
}


#pragma mark - create media
- (EWMediaItem *)createMedia{
    NSParameterAssert([NSThread isMainThread]);
    EWMediaItem *m = [EWMediaItem createEntity];
    m.updatedAt = [NSDate date];
    m.author = me;
    return m;
}
- (EWMediaItem *)getWokeVoice{
    PFQuery *q = [PFQuery queryWithClassName:@"EWMediaItem"];
    [q whereKey:EWMediaItemRelationships.author equalTo:[PFQuery getUserObjectWithId:WokeUserID]];
    [q whereKey:EWMediaItemAttributes.type equalTo:kPushMediaTypeVoice];
    NSArray *mediasFromWoke = me.cachedInfo[kWokeVoiceReceived]?:[NSArray new];
#if !DEBUG
    [q whereKey:kParseObjectID notContainedIn:mediasFromWoke];
#endif
    NSArray *voices = [EWSync findServerObjectWithQuery:q];
    NSUInteger i = arc4random_uniform(voices.count);
    PFObject *voice = voices[i];
    if (voice) {
        EWMediaItem *media = (EWMediaItem *)[voice managedObjectInContext:nil];
        [media refresh];
        //save
        NSMutableDictionary *cache = [me.cachedInfo mutableCopy];
        NSMutableArray *voices = [mediasFromWoke mutableCopy];
        [voices addObject:media.objectId];
        [cache setObject:voices forKey:kWokeVoiceReceived];
        me.cachedInfo = [cache copy];
        [EWSync save];
        
        return media;
    }
    return nil;
}

- (EWMediaItem *)createBuzzMedia{
    EWMediaItem *media = [self createMedia];
    media.type = kMediaTypeBuzz;
    media.buzzKey = [me.preference objectForKey:@"buzzSound"];
    return media;
}

#pragma mark - SEARCH
- (EWMediaItem *)getMediaByID:(NSString *)mediaID{
    EWMediaItem *media = (EWMediaItem *)[EWSync managedObjectWithClass:@"EWMediaItem" withID:mediaID];
    return media;
}


- (NSArray *)mediaCreatedByPerson:(EWPerson *)person{
    NSArray *medias = [person.medias allObjects];
    if (medias.count == 0 && [person isMe]) {
        //query
        PFQuery *q = [[[PFUser currentUser] relationForKey:EWPersonRelationships.medias] query];
        [EWSync findServerObjectInBackgroundWithQuery:q completion:^(NSArray *objects, NSError *error) {
            [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
                EWPerson *localMe = [me inContext:localContext];
                NSArray *newMedias = [objects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT %K IN %@", kParseObjectID, [localMe.medias valueForKey:kParseObjectID]]];
                for (PFObject *m in newMedias) {
                    EWMediaItem *media = (EWMediaItem *)[m managedObjectInContext:localContext];
                    [media refresh];
                    [localMe addMediasObject:media];
                    [media saveToLocal];
                }
                [localMe saveToLocal];
                DDLogInfo(@"My media updated with %lu new medias", (unsigned long)newMedias.count);
            }];
        }];
    }
    return medias;
}

- (NSArray *)mediasForPerson:(EWPerson *)person{
    NSMutableSet *medias = [[NSMutableSet alloc] init];
    for (EWTaskItem *task in [person.tasks setByAddingObjectsFromSet:person.pastTasks]) {
        for (EWMediaItem *media in task.medias) {
            [medias addObject:media];
        }
    }
    //need to add Media Assets
    
    return [medias allObjects];
}

#pragma mark - DELETE
- (void)deleteMedia:(EWMediaItem *)mi{

    [mi.managedObjectContext deleteObject:mi];
    [EWSync save];
}


- (void)deleteAllMedias{
#ifdef DEBUG
    NSLog(@"*** Delete all medias");
    NSArray *medias = [self mediaCreatedByPerson:me];
    for (EWMediaItem *m in medias) {
        [m.managedObjectContext deleteObject:m];
    }
    [EWSync save];
#endif
}


- (BOOL)checkMediaAssets{
    NSParameterAssert([NSThread isMainThread]);

    BOOL new;
    new = [self checkMediaAssetsInContext:mainContext];
    return new;
}

- (void)checkMediaAssetsInBackground{
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        [self checkMediaAssetsInContext:localContext];
    }];
}

- (BOOL)checkMediaAssetsInContext:(NSManagedObjectContext *)context{
    if (![PFUser currentUser]) {
        return NO;
    }
    PFQuery *query = [PFQuery queryWithClassName:@"EWMediaItem"];
    [query whereKey:@"receivers" containedIn:@[[PFUser currentUser]]];
    NSSet *localAssetIDs = [me.mediaAssets valueForKey:kParseObjectID];
    [query whereKey:kParseObjectID notContainedIn:localAssetIDs.allObjects];
    NSArray *mediaPOs = [EWSync findServerObjectWithQuery:query];
	BOOL newMedia = NO;
    for (PFObject *po in mediaPOs) {
        EWMediaItem *mo = (EWMediaItem *)[po managedObjectInContext:context];
        [mo refresh];//save to local marked
        //relationship
        NSMutableArray *receivers = po[@"receivers"];
        for (PFObject *receiver in receivers) {
            if ([receiver.objectId isEqualToString:me.objectId]) {
                [receivers removeObject:receiver];
                break;
            }
        }
        po[@"receivers"] = receivers.copy;
        [po saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                DDLogError(@"Failed to save media %@: %@",po.objectId, error);
            }
        }];
        
        [mo removeReceiversObject:me];
        [me addMediaAssetsObject:mo];
        
        //in order to upload change to server, we need to save to server
        [mo saveToServer];
        DDLogInfo(@"Received media(%@) from %@", mo.objectId, mo.author.name);
		
		//find if new media has been notified
		BOOL notified = NO;
		for (EWNotification *note in [EWNotificationManager allNotifications]) {
			if ([note.userInfo[@"media"] isEqualToString:mo.objectId]) {
				DDLogVerbose(@"Media has already been notified to user, skip.");
				notified = YES;
                break;
			}
		}
		
        //create a notification
		if (!notified) {
			dispatch_async(dispatch_get_main_queue(), ^{
				EWMediaItem *media = (EWMediaItem *)[mo inContext:mainContext];
				[EWNotificationManager newNotificationForMedia:media];
			});
			newMedia = YES;
		}
		
    }
	
    if (newMedia) {
        //notify user for the new media
        dispatch_async(dispatch_get_main_queue(), ^{
            EWAlert(@"You got voice for your next wake up");
        });
        return YES;
    }
    
    return NO;
}


+ (BOOL)validateMedia:(EWMediaItem *)media{
    BOOL good = YES;
    if(!media.type){
        good = NO;
    }
    if (!media.author) {
        good = NO;
    }
    if ([media.type isEqualToString:kMediaTypeVoice]) {
        if(!media.audio){
            DDLogError(@"Media %@ type voice with no audio.", media.serverID);
            good = NO;
        }
    }else if ([media.type isEqualToString:kMediaTypeBuzz]){
        if(!media.buzzKey){
            DDLogError(@"Media %@ type buzz with no buzz type", media.serverID);
            good = NO;
        }
    }
    if (!media.receivers) {
        if(media.tasks.count == 0){
            DDLogError(@"Found media %@ with no receiver and no task.", media.serverID);
            good = NO;
        }
    }
    
    return good;
}

+ (void)createACLForMedia:(EWMediaItem *)media{
    NSSet *receivers = media.receivers;
    PFObject *m = media.parseObject;
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    for (EWPerson *p in receivers) {
        PFObject *PO = p.parseObject;
        [acl setReadAccess:YES forUser:(PFUser *)PO];
        [acl setReadAccess:YES forUser:(PFUser *)PO];
        
    }
    m.ACL = acl;
    NSLog(@"ACL created for media(%@) with access for %@", media.objectId, [receivers valueForKey:kParseObjectID]);
}
@end
