//
//  EWAchievement.m
//  EarlyWorm
//
//  Created by Lei on 1/9/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWAchievement.h"
#import "EWPerson.h"
#import "EWDataStore.h"

@implementation EWAchievement

@dynamic name;
@dynamic ewachievement_id;
@dynamic image_key;
@dynamic explaination;
@dynamic time;
@dynamic type;
@dynamic owner;

@synthesize image;


- (UIImage *)image{
    if (!image) {
        image = [UIImage imageWithData:[[EWDataStore sharedInstance] getRemoteDataWithKey:self.image_key]];
    }
    return image;
}

- (void)setImage:(UIImage *)pic{
    NSData *picData = UIImagePNGRepresentation(pic);
    self.image_key = [SMBinaryDataConversion stringForBinaryData:picData name:@"achievement_icon.png" contentType:@"image/png"];
}

@end
