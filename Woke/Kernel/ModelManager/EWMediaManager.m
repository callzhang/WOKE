//
//  EWMediaStore.m
//  EarlyWorm
//
//  Created by Lei on 8/2/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWMediaManager.h"
#import "EWMedia.h"
#import "EWImageStore.h"
#import "EWPerson.h"
//#import "EWTaskManager.h"
//#import "EWTaskItem.h"
#import "EWUserManagement.h"
#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWActivity.h"

@implementation EWMediaManager
//@synthesize context, model;
@synthesize myMedias;
//@synthesize context;

+(EWMediaManager *)sharedInstance{
    NSParameterAssert([NSThread isMainThread]);
    static EWMediaManager *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWMediaManager alloc] init];
    });
    return sharedStore_;
}


- (NSArray *)myMedias{
    NSParameterAssert([NSThread isMainThread]);
    return [self mediasForPerson:[EWSession sharedSession].currentUser];
}


- (EWMedia *)getWokeVoice{
    PFQuery *q = [PFQuery queryWithClassName:@"EWMedia"];
    [q whereKey:EWMediaRelationships.author equalTo:[PFQuery getUserObjectWithId:WokeUserID]];
    [q whereKey:EWMediaAttributes.type equalTo:kPushMediaTypeVoice];
    NSArray *mediasFromWoke = [EWSession sharedSession].currentUser.cachedInfo[kWokeVoiceReceived]?:[NSArray new];
#if !DEBUG
    [q whereKey:kParseObjectID notContainedIn:mediasFromWoke];
#endif
    NSArray *voices = [EWSync findServerObjectWithQuery:q];
    NSUInteger i = arc4random_uniform(voices.count);
    PFObject *voice = voices[i];
    if (voice) {
        EWMedia *media = (EWMedia *)[voice managedObjectInContext:nil];
        [media refresh];
        //save
        NSMutableDictionary *cache = [[EWSession sharedSession].currentUser.cachedInfo mutableCopy];
        NSMutableArray *voices = [mediasFromWoke mutableCopy];
        [voices addObject:media.objectId];
        [cache setObject:voices forKey:kWokeVoiceReceived];
        [EWSession sharedSession].currentUser.cachedInfo = [cache copy];
        [EWSync save];
        
        return media;
    }
    return nil;
}

//possible redundant API, my media should be ready on start
- (NSArray *)mediaCreatedByPerson:(EWPerson *)person{
    NSArray *medias = [person.medias allObjects];
    if (medias.count == 0 && [person isMe]) {
        //query
        PFQuery *q = [[[PFUser currentUser] relationForKey:EWPersonRelationships.medias] query];
        [EWSync findServerObjectInBackgroundWithQuery:q completion:^(NSArray *objects, NSError *error) {
            [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
                EWPerson *localMe = [[EWSession sharedSession].currentUser inContext:localContext];
                NSArray *newMedias = [objects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT %K IN %@", kParseObjectID, [localMe.medias valueForKey:kParseObjectID]]];
                for (PFObject *m in newMedias) {
                    EWMedia *media = (EWMedia *)[m managedObjectInContext:localContext];
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
    NSMutableArray *medias = [[NSMutableArray alloc] init];
    for (EWActivity *activity in person.activities) {
        for (EWMedia *media in activity.medias) {
            [medias addObject:media];
        }
    }
    //sort
    [medias sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.createdAt ascending:YES]]];
    
    return medias;
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
    PFQuery *query = [PFQuery queryWithClassName:@"EWMedia"];
    [query whereKey:@"receivers" containedIn:@[[PFUser currentUser]]];
    NSSet *localAssetIDs = [[EWSession sharedSession].currentUser.unreadMedias valueForKey:kParseObjectID];
    [query whereKey:kParseObjectID notContainedIn:localAssetIDs.allObjects];
    NSArray *mediaPOs = [EWSync findServerObjectWithQuery:query];
	BOOL newMedia = NO;
    for (PFObject *po in mediaPOs) {
        EWMedia *mo = (EWMedia *)[po managedObjectInContext:context];
        [mo refresh];//save to local marked
        //relationship
        NSMutableArray *receivers = po[@"receivers"];
        for (PFObject *receiver in receivers) {
            if ([receiver.objectId isEqualToString:[EWSession sharedSession].currentUser.objectId]) {
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
        
        mo.receiver = nil;
        [[EWSession sharedSession].currentUser addUnreadMediasObject:mo];
        
        //in order to upload change to server, we need to save to server
        [mo saveToServer];
        DDLogInfo(@"Received media(%@) from %@", mo.objectId, mo.author.name);
		
		//find if new media has been notified
		BOOL notified = NO;
		for (EWNotification *note in [EWPerson myNotifications]) {
			if ([note.userInfo[@"media"] isEqualToString:mo.objectId]) {
				DDLogVerbose(@"Media has already been notified to user, skip.");
				notified = YES;
                break;
			}
		}
		
        //create a notification
		if (!notified) {
			dispatch_async(dispatch_get_main_queue(), ^{
				EWMedia *media = (EWMedia *)[mo inContext:mainContext];
				[EWNotification newNotificationForMedia:media];
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


@end
