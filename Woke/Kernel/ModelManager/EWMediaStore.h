//
//  EWMediaStore.h
//  EarlyWorm
//
//  Created by Lei on 8/2/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#include <stdlib.h>
#import "EWPersonStore.h"

#define buzzSounds                      @{@"default": @"buzz.caf"};
#define kWokeVoiceReceived              @"woke_voice_received"//the ramdom voice alraddy received, stored in cache

@class EWMediaItem;
@interface EWMediaStore : NSObject //EWStore

/*
 medias that has been played.
 **/
@property (nonatomic) NSArray *myMedias;

+ (EWMediaStore *)sharedInstance;

//add
- (EWMediaItem *)createMedia;
- (EWMediaItem *)createBuzzMedia;

//delete
- (void)deleteMedia:(EWMediaItem *)mi;
- (void)deleteAllMedias;

//search
- (EWMediaItem *)getMediaByID:(NSString *)mediaID;
/**
 Fetch media by author
 */
- (NSArray *)mediaCreatedByPerson:(EWPerson *)person;

/**
 Fetch media by receiver
 */
- (NSArray *)mediasForPerson:(EWPerson *)person;

//Check media assets relationship
- (BOOL)checkMediaAssets;
- (void)checkMediaAssetsInBackground;

//get ramdom voice
- (EWMediaItem *)getWokeVoice;

//get my task in a media
+ (EWTaskItem *)myTaskInMedia:(EWMediaItem *)media;


//Validation
+ (BOOL)validateMedia:(EWMediaItem *)media;

//ACL
+ (void)createACLForMedia:(EWMediaItem *)media;
@end
