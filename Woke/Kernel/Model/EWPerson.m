//
//  EWPerson.m
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWPerson.h"
#import "EWPersonStore.h"

@implementation EWPerson
@dynamic lastLocation;
@dynamic profilePic;
@dynamic bgImage;
@dynamic preference;

//#pragma mark - User Management
//- (id)initNewUserInContext:(NSManagedObjectContext *)context {
//    //We have overridden this method to store a reference to [SMClient defaultClient]. This ensures that the SDK knows the primary key, etc of the user schema.
//    self = [super initWithEntityName:@"EWPerson" insertIntoManagedObjectContext:context];
//    
//    if (self) {
//        //[self setValue:[self assignObjectId] forKey:[self primaryKeyField]];
//    }
//    
//    return self;
//}

#pragma mark - IMAGE REPRESENTATION
//- (UIImage *)profilePic{
//    if (!profilePic) {
//        profilePic = [UIImage imageWithData:[[EWDataStore sharedInstance] getRemoteDataWithKey:self.profilePicKey]];
//        
//    }
//    
//    
//    
//    return profilePic;
//}
//
//- (void)setProfilePic:(UIImage *)pic{
//    //update memory
//    profilePic = pic;
//    
//    NSData *picData = UIImagePNGRepresentation(pic);
//    //update cache
//    [[EWDataStore sharedInstance] updateCacheForKey:self.profilePicKey withData:picData];
//    
//    [[EWDataStore currentContext] MR_saveToPersistentStoreAndWait];
//}
//
//- (UIImage *)bgImage{
//    if (!bgImage) {
//        bgImage = [UIImage imageWithData:[[EWDataStore sharedInstance] getRemoteDataWithKey:self.bgImageKey]];
//    }
//    return bgImage;
//}
//
//
//- (void)setBgImage:(UIImage *)img{
//    //memory
//    bgImage = img;
//    
//    NSData *imgData = UIImagePNGRepresentation(img);
//    //cache
//    [[EWDataStore sharedInstance] updateCacheForKey:self.bgImageKey.MD5Hash withData:imgData];
//    
//    //server
//    self.bgImageKey = [SMBinaryDataConversion stringForBinaryData:imgData name:@"bgImage.png" contentType:@"image/png"];
//    
//    [[EWDataStore currentContext] saveOnSuccess:NULL onFailure:^(NSError *error) {
//        NSLog(@"BG img not saved");
//    }];
//}


#pragma mark - Preference
//- (NSDictionary *)preference{
//    if (self.preferenceString) {
//        NSData *prefData = [self.preferenceString dataUsingEncoding:NSUTF8StringEncoding];
//        NSError *err;
//        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:prefData options:0 error:&err];
//        return json;
//    }else{
//        NSDictionary *defaults = userDefaults;
//        self.preference = [defaults mutableCopy];
//        NSLog(@"Set user defaults");
//        return self.preference;
//    }
//    return nil;
//}
//
//- (void)setPreference:(NSDictionary *)p{
//    NSError *err;
//    NSData *prefData = [NSJSONSerialization dataWithJSONObject:p options:NSJSONWritingPrettyPrinted error:&err];
//    NSString *prefStr = [[NSString alloc] initWithData:prefData encoding:NSUTF8StringEncoding];
//    self.preferenceString = prefStr;
//}



#pragma mark - Helper methods
- (BOOL)isMe{
    BOOL isme = NO;
    if ([EWPersonStore me]) {
        isme = [self.username isEqualToString:[EWPersonStore me].username];
    }
    return isme;
}


@end
