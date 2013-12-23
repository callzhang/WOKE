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
@synthesize context;

+(EWMediaStore *)sharedInstance{
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
        context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
    }
    return self;
}

- (NSArray *)allMedias{
    EWPerson *me = [EWPersonStore sharedInstance].currentUser;
    return [self mediasForPerson:me];
}




- (EWMediaItem *)createMedia{
    EWMediaItem *m = [NSEntityDescription insertNewObjectForEntityForName:@"EWMediaItem" inManagedObjectContext:context];
    [m assignObjectId];
    m.author = [EWPersonStore sharedInstance].currentUser;
    //TODO: update method here
    NSInteger k = arc4random() % 6;
    NSArray *vmList = @[@"vm1.m4a", @"vm2.m4a", @"vm3.m4a", @"vm3.m4a", @"vm5.m4a", @"vm6.m4a"];
    NSString *vmName = vmList[k];
    //NSArray *nameArray = [vmName componentsSeparatedByString:@"."];
    //PFFile *f = [PFFile fileWithName:vmName contentsAtPath:[[NSBundle mainBundle] pathForResource:nameArray[0] ofType:nameArray[1]]];
    m.audioKey = vmName;
    [context saveOnSuccess:^{
        NSLog(@"Media created with name: %@", vmName);
    } onFailure:^(NSError *error) {
        [NSException raise:@"Create media failed" format:@"Reason: %@",error.description];
    }];
    return m;
}

#pragma mark - SEARCH

- (NSArray *)mediaCreatedByPerson:(EWPerson *)person{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EWMediaItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"author == %@", person];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createddate" ascending:YES]];
    NSError *err;
    return [context executeFetchRequestAndWait:request error:&err];
}

- (NSArray *)mediasForPerson:(EWPerson *)person{
    NSMutableArray *medias = [[NSMutableArray alloc] init];
    for (EWTaskItem *task in person.tasks) {
        for (EWMediaItem *media in task.medias) {
            [medias addObject:media];
        }
    }
    return medias;
}

@end
