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
    return [self mediasForPerson:[EWPersonStore me]];
}


#pragma mark - create media
- (EWMediaItem *)createMedia{
    EWMediaItem *m = [EWMediaItem createEntity];
    EWPerson *user = [EWPersonStore me];
    m.author = user;
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
    
    [EWDataStore save];
    
    return media;
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
        media = (EWMediaItem *)[object managedObject];
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

    [[EWDataStore currentContext] deleteObject:mi];
    [EWDataStore save];
}


- (void)deleteAllMedias{
#ifdef DEV_TEST
    NSLog(@"*** Delete all medias");
    NSArray *medias = [self mediaCreatedByPerson:me];
    for (EWMediaItem *m in medias) {
        [[EWDataStore currentContext] deleteObject:m];
    }
    [EWDataStore save];
#endif
}


- (NSArray *)checkMediaAssets{
    PFQuery *query = [PFQuery queryWithClassName:@"EWMediaItem" predicate:[NSPredicate predicateWithFormat:@"ANY receivers = %@", [PFUser currentUser]]];
    NSMutableArray *mediaPOs = [[query findObjects] mutableCopy];
    [mediaPOs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT %K IN %@", kParseObjectID, [me.mediaAssets valueForKey:kParseObjectID]]];
    for (PFObject *po in mediaPOs) {
        EWMediaItem *mo = (EWMediaItem *)po.managedObject;
        
        //relationship
        if ([mo.tasks containsObject:me]) {
            [mo removeReceiversObject:me];
        }else{
            [mo addReceiversObject:me];
            NSLog(@"Received media (%@)", mo.objectId);
            EWAlert(@"You got voice for your next wake up");
        }
        [EWDataStore save];
    }
    return [[EWPersonStore me].mediaAssets allObjects];
}

+ (EWTaskItem *)myTaskInMedia:(EWMediaItem *)media{
    EWTaskItem *task = [[media.tasks filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"owner = %@", me]] anyObject];
    return task;
}

@end
