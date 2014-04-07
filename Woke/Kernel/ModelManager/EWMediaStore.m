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
#import "StackMob.h"

@implementation EWMediaStore
//@synthesize context, model;
@synthesize allMedias;
//@synthesize context;

+(EWMediaStore *)sharedInstance{
    BOOL mainThread = [NSThread isMainThread];
    if (!mainThread) {
        NSLog(@"**** Media Store not on main thread ****");
    }
    
    static EWMediaStore *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWMediaStore alloc] init];
    });
    return sharedStore_;
}

- (id)init{
    self = [super init];
    if (self) {
        //context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
    }
    return self;
}

- (NSArray *)allMedias{
    EWPerson *me = currentUser;
    return [self mediasForPerson:me];
}


#pragma mark - create media

- (EWMediaItem *)createMedia{
    EWMediaItem *m = [NSEntityDescription insertNewObjectForEntityForName:@"EWMediaItem" inManagedObjectContext:[EWDataStore currentContext]];
    [m assignObjectId];
    m.author = currentUser;
    
    [[EWDataStore currentContext] saveOnSuccess:^{
        NSLog(@"Media created");
    } onFailure:^(NSError *error) {
        //[NSException raise:@"Create media failed" format:@"Reason: %@",error.description];
        EWAlert(@"Failed to send voice. You can send it again.");
    }];
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
    media.audioKey = path;
    
    media.message = @"This is a test voice tone";
    
    [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
        NSLog(@"Failed to save pseudo media");
    }];
    
    return media;
}

- (void)createPseudoMediaForTask:(EWTaskItem *)task{
    EWTaskItem *task_ = [EWDataStore objectForCurrentContext:task];
    EWMediaItem *media = [self createPseudoMedia];
    [task_ addMediasObject:media];
    [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
        NSLog(@"Failed to save task for pseudo media");
    }];
}

#pragma mark - SEARCH
- (EWMediaItem *)getMediaByID:(NSString *)mediaID{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EWMediaItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"ewmediaitem_id == %@", mediaID];
    NSError *err;
    NSArray *medias = [[EWDataStore currentContext] executeFetchRequestAndWait:request error:&err];
    if (medias.count == 0) NSLog(@"Could not fetch media for ID: %@, error: %@", mediaID, err.description);
    return medias[0];
}

- (NSArray *)mediaCreatedByPerson:(EWPerson *)person{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWMediaItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"author == %@", person];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createddate" ascending:YES]];
    NSError *err;
    return [[EWDataStore currentContext] executeFetchRequestAndWait:request error:&err];
}

- (NSArray *)mediasForPerson:(EWPerson *)person{
    NSMutableArray *medias = [[NSMutableArray alloc] init];
    for (EWTaskItem *task in [person.tasks setByAddingObjectsFromSet:person.pastTasks]) {
        for (EWMediaItem *media in task.medias) {
            [medias addObject:media];
        }
    }
    return medias;
}

#pragma mark - DELETE
- (void)deleteAllMedias{
    EWPerson *me = currentUser;
    NSArray *medias = [self mediaCreatedByPerson:me];
    for (EWMediaItem *m in medias) {
        [[EWDataStore currentContext] deleteObject:m];
    }
    [[EWDataStore currentContext] saveOnSuccess:^{
        NSLog(@"All media for person: %@ has been purged", me.name);
    } onFailure:^(NSError *error) {
        [NSException raise:@"Unable to delete media" format:@"Reason: %@", error.description];
    }];
}

@end