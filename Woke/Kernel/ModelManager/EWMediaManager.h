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
#import "EWPersonManager.h"

//#define buzzSounds                      @{@"default": @"buzz.caf"};
#define kWokeVoiceReceived              @"woke_voice_received"//the ramdom voice alraddy received, stored in cache

@class EWMedia;
@interface EWMediaManager : NSObject //EWStore

/*
 medias that has been played.
 **/
@property (nonatomic) NSArray *myMedias;

+ (EWMediaManager *)sharedInstance;


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
- (EWMedia *)getWokeVoice;
@end
