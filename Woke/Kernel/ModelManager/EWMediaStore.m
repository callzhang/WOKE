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
@synthesize allMedias;
//@synthesize context;

+(EWMediaStore *)sharedInstance{
    static EWMediaStore *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWMediaStore alloc] init];
    });
    return sharedStore_;
}


- (NSArray *)allMedias{
    return [self mediasForPerson:[EWUserManagement me]];
}


#pragma mark - create media
- (EWMediaItem *)createMedia{
    EWMediaItem *m = [EWMediaItem createEntity];
    EWPerson *user = [EWUserManagement me];
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
    [media refresh];//get object id
    return media;
}

#pragma mark - SEARCH
- (EWMediaItem *)getMediaByID:(NSString *)mediaID{
    EWMediaItem *media = [EWMediaItem findFirstByAttribute:kParseObjectID withValue:mediaID];
    if (!media) {
        //get from server
        PFQuery *query = [PFQuery queryWithClassName:@"EWMediaItem"];
        [query whereKey:kParseObjectID equalTo:media];
        PFObject *object = [query getFirstObject];
        media = (EWMediaItem *)[object managedObject];
    }
    return media;
}
- (NSArray *)mediaCreatedByPerson:(EWPerson *)person{
//    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWMediaItem"];
//    request.predicate = [NSPredicate predicateWithFormat:@"author == %@", person];
//    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createddate" ascending:YES]];
//    NSError *err;
//    NSArray *medias = [[EWDataStore currentContext] executeFetchRequest:request error:&err];
    NSArray *medias = [person.medias allObjects];
    if (medias.count == 0) {
        [person refresh];
        medias = [person.medias allObjects];
    }
    return medias;
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
- (void)deleteMedia:(EWMediaItem *)mi{

    [[EWDataStore currentContext] deleteObject:mi];
    [EWDataStore save];
}


- (void)deleteAllMedias{
#ifdef DEV_TEST
    NSLog(@"*** Delete all medias");
    EWPerson *me = me;
    NSArray *medias = [self mediaCreatedByPerson:me];
    for (EWMediaItem *m in medias) {
        [[EWDataStore currentContext] deleteObject:m];
    }
    [EWDataStore save];
#endif
}

@end
