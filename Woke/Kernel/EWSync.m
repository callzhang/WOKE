//
//  EWSync.m
//  Woke
//
//  Created by Lee on 9/24/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWSync.h"
#import "EWDataStore.h"
#import "EWUserManagement.h"
#import "EWPersonStore.h"
#import "EWMediaStore.h"
#import "EWTaskStore.h"
#import "EWAlarmManager.h"
#import "EWWakeUpManager.h"
#import "EWServer.h"
#import "EWTaskItem.h"
#import "EWMediaItem.h"
#import "EWNotification.h"
#import "EWUIUtil.h"
#import "EWStatisticsManager.h"
#import "NSManagedObject+Parse.h"
#import "PFObject+EWSync.h"


#pragma mark -
#define kServerTransformTypes               @{@"CLLocation": @"PFGeoPoint"} //localType: serverType
#define kServerTransformClasses             @{@"EWPerson": @"_User"} //localClass: serverClass
#define kUserClass                          @"EWPerson"
//#define classSkipped                        @[@"EWPerson"]
#define attributeUploadSkipped              @[kParseObjectID, kUpdatedDateKey, @"score"]


//============ Global shortcut to main context ===========
NSManagedObjectContext *mainContext;
//=======================================================

@interface EWSync(){
	NSMutableDictionary *workingChangedRecords;
}
@property NSManagedObjectContext *context; //the main context(private), only expose 'currentContext' as a class method
@property NSMutableDictionary *parseSaveCallbacks;
@property (nonatomic) NSTimer *saveToServerDelayTimer;
@property NSMutableArray *saveToLocalItems;
@property NSMutableArray *deleteToLocalItems;
//@property (nonatomic) NSMutableDictionary *changesDictionary;
@end


@implementation EWSync
@synthesize context;
@synthesize model;
@synthesize parseSaveCallbacks;
@synthesize isUploading = _isUploading;


- (void)setup{
    
    //server: enable alert when offline
    [Parse errorMessagesEnabled:YES];
    
    //Access Control: enable public read access while disabling public write access.
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    //core data
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Woke"];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelWarn];
    context = [NSManagedObjectContext defaultContext];
    mainContext = context;
    
    //observe context change to update the modifiedData of that MO. (Only observe the main context)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preSaveAction:) name:NSManagedObjectContextWillSaveNotification object:context];
    
    //Observe background context saves so main context can perform upload
    //We don't need to merge child context change to main context
    //It will cause errors when main and child context access same MO
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:context queue:nil usingBlock:^(NSNotification *note) {
        
        [_saveToServerDelayTimer invalidate];
        _saveToServerDelayTimer = [NSTimer scheduledTimerWithTimeInterval:kUploadLag target:self selector:@selector(updateToServer) userInfo:nil repeats:NO];
    }];
    
    //Reachability
    self.reachability = [Reachability reachabilityForInternetConnection];
    self.reachability.reachableBlock = ^(Reachability *reachability) {
        NSLog(@"====== Network is reachable. Start upload. ======");
        //in background thread
        [EWSync resumeUploadToServer];
        
        //resume refresh MO
        NSSet *MOs = [EWSync getObjectFromQueue:kParseQueueRefresh];
        for (NSManagedObject *MO in MOs) {
            [MO refreshInBackgroundWithCompletion:^{
                NSLog(@"%@(%@) refreshed after network resumed.", MO.entity.name, MO.serverID);
            }];
        }
    };
    self.reachability.unreachableBlock = ^(Reachability * reachability){
        NSLog(@"====== Network is unreachable ======");
        [EWUIUtil showHUDWithString:@"Offline"];
    };
    
    //facebook
    [PFFacebookUtils initializeFacebook];
    
    //watch for login event
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDataCheck) name:kPersonLoggedIn object:Nil];
    
    //initial property
    self.parseSaveCallbacks = [NSMutableDictionary dictionary];
    self.saveCallbacks = [NSMutableArray new];
    self.saveToLocalItems = [NSMutableArray new];
    self.deleteToLocalItems = [NSMutableArray new];
    self.serverObjectPool = [NSMutableDictionary new];
    self.changeRecords = [NSMutableDictionary new];
    
}

@end
