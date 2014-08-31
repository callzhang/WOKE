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
#import "EWTaskStore.h"
#import "EWTaskItem.h"
#import "EWUserManagement.h"
#import "EWDataStore.h"

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

- (EWMediaItem *)createPseudoMedia{
    EWMediaItem *media = [self createMedia];
    
    //create ramdom media
    NSInteger k = arc4random_uniform(6);
    NSArray *vmList = @[@"vm1.m4a", @"vm2.m4a", @"vm3.m4a", @"vm3.m4a", @"vm5.m4a", @"vm6.m4a"];
    NSString *vmName = vmList[k];
    NSArray *name = [vmName componentsSeparatedByString:@"."];
    NSString *path = [[NSBundle mainBundle] pathForResource:name[0] ofType:name[1]];
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    media.audio = data;
    media.type = kMediaTypeVoice;
    media.message = @"This is a test voice tone";
    media.type = kMediaTypeVoice;
    
    [EWDataStore save];
    
    return media;
}

- (EWMediaItem *)getWokeVoice{
    PFQuery *q = [PFQuery queryWithClassName:@"EWMediaItem"];
    [q whereKey:@"author" equalTo:[PFQuery getUserObjectWithId:WokeUserID]];
    NSArray *mediasFromWoke = me.cachedInfo[kWokeVoiceReceived]?:[NSArray new];
    [q whereKey:kParseObjectID notContainedIn:mediasFromWoke];
    PFObject *voice = [q getFirstObject];
    if (voice) {
        [EWDataStore setCachedParseObject:voice];
        EWMediaItem *media = (EWMediaItem *)[voice managedObjectInContext:nil];
        [media refresh];
        //save
        NSMutableDictionary *cache = [me.cachedInfo mutableCopy];
        NSMutableArray *voices = [mediasFromWoke mutableCopy];
        [voices addObject:media.objectId];
        [cache setObject:voices forKey:kWokeVoiceReceived];
        me.cachedInfo = [cache copy];
        [EWDataStore save];
        
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
    EWMediaItem *media = [EWMediaItem MR_findFirstByAttribute:kParseObjectID withValue:mediaID];
    if (!media) {
        //get from server
        PFQuery *query = [PFQuery queryWithClassName:@"EWMediaItem"];
        [query whereKey:kParseObjectID equalTo:mediaID];
        [query includeKey:@"receivers"];
        PFObject *object = [query getFirstObject];
        media = (EWMediaItem *)[object managedObjectInContext:nil];
        [media refresh];
    }
    return media;
}


- (NSArray *)mediaCreatedByPerson:(EWPerson *)person{
    NSArray *medias = [person.medias allObjects];
    if (medias.count == 0) {
        //query
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
    [EWDataStore save];
}


- (void)deleteAllMedias{
#ifdef DEBUG
    NSLog(@"*** Delete all medias");
    NSArray *medias = [self mediaCreatedByPerson:me];
    for (EWMediaItem *m in medias) {
        [m.managedObjectContext deleteObject:m];
    }
    [EWDataStore save];
#endif
}


- (BOOL)checkMediaAssets{
    //NSParameterAssert([NSThread isMainThread]);
    __block NSArray *mediaPOs;
    [mainContext saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        PFQuery *query = [PFQuery queryWithClassName:@"EWMediaItem"];
        [query whereKey:@"receivers" containedIn:@[[PFUser currentUser]]];
        EWPerson *localMe = [me inContext:localContext];
        NSSet *localAssetIDs = [localMe.mediaAssets valueForKey:kParseObjectID];
        [query whereKey:kParseObjectID notContainedIn:localAssetIDs.allObjects];
        mediaPOs = [query findObjects];
        NSManagedObjectID *myID = localMe.objectID;
        
        for (PFObject *po in mediaPOs) {
            EWMediaItem *mo = (EWMediaItem *)[po managedObjectInContext:localContext];
            [mo refresh];
            //relationship
            EWPerson *localMe = (EWPerson *)[localContext objectWithID:myID];
            [mo removeReceiversObject:localMe];//remove from the receiver list
            [localMe addMediaAssetsObject:mo];//add to my media asset list
            NSLog(@"Received media(%@) from %@", mo.objectId, mo.author.name);
            EWAlert(@"You got voice for your next wake up");
        }
    }];
    
    if (mediaPOs.count > 0) {
        [EWDataStore save];
        return YES;
    }
    
    return NO;
}

- (void)checkMediaAssetsInBackground{
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        PFQuery *query = [PFQuery queryWithClassName:@"EWMediaItem"];
        [query whereKey:@"receivers" containedIn:@[[PFUser currentUser]]];
        NSSet *localAssetIDs = [me.mediaAssets valueForKey:kParseObjectID];
        [query whereKey:kParseObjectID notContainedIn:localAssetIDs.allObjects];
        NSArray *mediaPOs = [query findObjects];
        mediaPOs = [mediaPOs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT %K IN %@", kParseObjectID, localAssetIDs]];
        for (PFObject *po in mediaPOs) {
            EWMediaItem *mo = (EWMediaItem *)[po managedObjectInContext:localContext];
            [mo refresh];
            //relationship
            [mo removeReceiversObject:me];
            [me addMediaAssetsObject:mo];
            NSLog(@"Received media(%@) from %@", mo.objectId, mo.author.name);
            EWAlert(@"You got voice for your next wake up");
            
        }
    }];
}

+ (EWTaskItem *)myTaskInMedia:(EWMediaItem *)media{
    EWTaskItem *task = [[media.tasks filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"owner = %@", me]] anyObject];
    return task;
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
            NSLog(@"Media %@ type voice with no audio.", media.serverID);
            good = NO;
        }
    }else if ([media.type isEqualToString:kMediaTypeBuzz]){
        if(!media.buzzKey){
            NSLog(@"Media %@ type buzz with no buzz type", media.serverID);
            good = NO;
        }
    }
    if (!media.receivers) {
        if(media.tasks.count == 0){
            NSLog(@"Found media %@ with no receiver and no task.", media.serverID);
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
        PFObject *PO = [p getParseObjectWithError:NULL];
        [acl setReadAccess:YES forUser:(PFUser *)PO];
        [acl setReadAccess:YES forUser:(PFUser *)PO];
        
    }
    m.ACL = acl;
    NSLog(@"ACL created for media(%@) with access for %@", media.objectId, [receivers valueForKey:kParseObjectID]);
}
@end
