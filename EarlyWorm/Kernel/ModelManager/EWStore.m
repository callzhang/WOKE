//
//  EWStore.m
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWStore.h"

@implementation EWStore
@synthesize model, context;

+ (EWStore *)sharedInstance{
    static EWStore *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWStore alloc] init];
    });
    return sharedStore_;
}

-(id)init{
    self = [super init];
    if (self) {
        //Returns a model created by merging all the models found in given bundles. If you specify nil, then the main bundle is searched.
        model = [NSManagedObjectModel mergedModelFromBundles:nil];
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        //define SQLite file path
        NSString *path = self.archievePath;
        //NSURL object as a file URL with a specified path
        NSURL *storeURL = [NSURL fileURLWithPath:path];
        NSError *error = nil;
        //Adds a new persistent store of a specified type at a given location, and returns the new store.
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil URL:storeURL
                                     options:nil error:&error]) {
            [NSException raise:@"Add persistent store failed" format:@"Reason: %@", error.localizedDescription];
        }
        //create managed object context
        context = [[NSManagedObjectContext alloc] init];
        context.persistentStoreCoordinator = psc;
        context.undoManager = nil; //TODO

    }
    return self;
}

//get app archieve path
- (NSString *)archievePath{
    //    searches the filesystem for a path that meets the criteria given by the arguments.
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //    get one and only document directory from the list
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    //~Users/Lei/Library/Application Support/iPhone Simulator/6.1/Applications/???/Documents
    
    //archieve path file name
    NSString *savePath = [documentDirectory stringByAppendingPathComponent:@"media.data"];
    return savePath;
}

- (void)save{
    NSError *err = nil;  //TODO
    BOOL successful = [context save:&err]; //Attempts to commit unsaved changes to registered objects to their persistent store.
    if (successful) {
        
        NSLog(@"Saved CoreData to %@", self.archievePath);
    }else{
        NSLog(@"Error saving: %@", err.localizedDescription);
    }
    //return successful;
}

@end
