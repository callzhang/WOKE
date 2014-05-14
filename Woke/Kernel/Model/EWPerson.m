//
//  EWPerson.m
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWPerson.h"
#import "EWAlarmItem.h"
#import "EWGroup.h"
#import "EWTaskStore.h"
#import "EWTaskItem.h"
#import "EWMediaItem.h"
#import "EWMessage.h"
#import "EWUtil.h"
#import "NSDate+Extend.h"
#import "StackMob.h"
#import "EWDataStore.h"
#import "NSString+MD5.h"
#import "EWDownloadManager.h"

@implementation EWPerson
@dynamic achievements;
@dynamic aws_id;
@synthesize bgImage;
@synthesize profilePic;
@dynamic bgImageKey;
@dynamic birthday;
@dynamic city;
@dynamic createddate;
@dynamic email;
@dynamic facebook;
@dynamic gender;
@dynamic lastLocation;
@dynamic lastmoddate;
@dynamic lastSeenDate;
@dynamic name;
@dynamic profilePicKey;
@synthesize preference;
@dynamic preferenceString;
@dynamic region;
@dynamic statement;
@dynamic username;
@dynamic weibo;
@dynamic alarms;
@dynamic friends;
@dynamic friended;
@dynamic groups;
@dynamic groupsManaging;
@dynamic groupTasks;
@dynamic medias;
@dynamic mediaAssets;
@dynamic receivedMessages;
@dynamic sentMessages;
@dynamic tasks;
@dynamic tasksHelped;
@dynamic pastTasks;
@dynamic notifications;

#pragma mark - User Management
- (id)initNewUserInContext:(NSManagedObjectContext *)context {
    //We have overridden this method to store a reference to [SMClient defaultClient]. This ensures that the SDK knows the primary key, etc of the user schema.
    self = [super initWithEntityName:@"EWPerson" insertIntoManagedObjectContext:context];
    
    if (self) {
        //[self setValue:[self assignObjectId] forKey:[self primaryKeyField]];
    }
    
    return self;
}

#pragma mark - IMAGE REPRESENTATION
- (UIImage *)profilePic{
    if (!profilePic) {
        profilePic = [UIImage imageWithData:[[EWDataStore sharedInstance] getRemoteDataWithKey:self.profilePicKey]];
        
    }
    
    
    
    return profilePic;
}

- (void)setProfilePic:(UIImage *)pic{
    //update memory
    profilePic = pic;
    
    NSData *picData = UIImagePNGRepresentation(pic);
    //update cache
    [[EWDataStore sharedInstance] updateCacheForKey:self.profilePicKey withData:picData];
    
    [[EWDataStore currentContext] saveToPersistentStoreAndWait];
}

- (UIImage *)bgImage{
    if (!bgImage) {
        bgImage = [UIImage imageWithData:[[EWDataStore sharedInstance] getRemoteDataWithKey:self.bgImageKey]];
    }
    return bgImage;
}


- (void)setBgImage:(UIImage *)img{
    //memory
    bgImage = img;
    
    NSData *imgData = UIImagePNGRepresentation(img);
    //cache
    [[EWDataStore sharedInstance] updateCacheForKey:self.bgImageKey.MD5Hash withData:imgData];
    
    //server
    self.bgImageKey = [SMBinaryDataConversion stringForBinaryData:imgData name:@"bgImage.png" contentType:@"image/png"];
    
    [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
        NSLog(@"BG img not saved");
    }];
}


#pragma mark - Preference
- (NSDictionary *)preference{
    if (self.preferenceString) {
        NSData *prefData = [self.preferenceString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:prefData options:0 error:&err];
        return json;
    }else{
        NSDictionary *defaults = userDefaults;
        self.preference = [defaults mutableCopy];
        NSLog(@"Set user defaults");
        return self.preference;
    }
    return nil;
}

- (void)setPreference:(NSDictionary *)p{
    NSError *err;
    NSData *prefData = [NSJSONSerialization dataWithJSONObject:p options:NSJSONWritingPrettyPrinted error:&err];
    NSString *prefStr = [[NSString alloc] initWithData:prefData encoding:NSUTF8StringEncoding];
    self.preferenceString = prefStr;
}



@end
