//
//  EWUtil.m
//  EarlyWorm
//
//  Created by Lei on 8/19/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//
//  This class serves as the basic file input/output class that handles file namagement and memory management

#import "EWUtil.h"
//#import "ASIdentifierManager.h"
#import <AdSupport/ASIdentifierManager.h>

@implementation EWUtil

+ (NSString *)UUID{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    return uuid;
    
}

+ (NSString *)ADID{
    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    return adId;
}

+(void)clearMemory{
    //
}

+ (NSDictionary *)timeFromNumber:(double)number{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    NSInteger hour = floor(number);
    NSInteger minute = (number - hour)*100;
    dic[@"hour"] = [NSNumber numberWithInteger:hour];
    dic[@"minute"] = [NSNumber numberWithInteger: minute];
    return dic;
}

+ (double)numberFromTime:(NSDictionary *)dic{
    double hour = [(NSNumber *)dic[@"hour"] doubleValue];
    double minute = [(NSNumber *)dic[@"minute"] doubleValue];
    double number = hour + minute/100;
    return number;
}


+ (BOOL) isMultitaskingSupported {
    
    BOOL result = NO;
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]){
        result = [[UIDevice currentDevice] isMultitaskingSupported];
    }
    return result;
}

+(BOOL) isFirstTimeLogin{
    
    NSDictionary *option = @{@"firstTime": @"YES"};
    [[NSUserDefaults standardUserDefaults] registerDefaults:option];
    
    NSString *isString = [[NSUserDefaults standardUserDefaults] valueForKey:@"firstTime"];
    
    if ([isString isEqualToString:@"YES"]) {
        
        return YES;
        
    }
    else{
        
        return NO;
    }

}
+(void)setFirstTimeLoginOver{
    
    [[NSUserDefaults standardUserDefaults] setValue:@"NO" forKey:@"firstTime"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}
+(NSString *)uploadImageToParseREST:(UIImage *)uploadImage
{
    
    NSMutableString *urlString = [NSMutableString string];
    [urlString appendString:kParseUploadUrl];
    [urlString appendFormat:@"files/imagefile.jpg"];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request addValue:kParseApplicationId forHTTPHeaderField:@"X-Parse-Application-Id"];
    [request addValue:kParseRestAPIId forHTTPHeaderField:@"X-Parse-REST-API-Key"];
    [request addValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:UIImagePNGRepresentation(uploadImage)];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSString *fileUrl = [httpResponse allHeaderFields][@"Location"];
    
    NSLog(@"%@",fileUrl);
    return fileUrl;

}
@end
