//
//  EWNotification.m
//  Woke
//
//  Created by Lei on 4/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWNotification.h"
#import "EWPerson.h"


@implementation EWNotification

@dynamic body;
@dynamic completed;
@dynamic createddate;
@dynamic ewnotification_id;
@dynamic lastmoddate;
@dynamic title;
@dynamic type;
@synthesize userInfo;
@dynamic userInfoString;
@dynamic owner;
@dynamic sender;
@dynamic importance;

- (NSDictionary *)userInfo{
    if (self.userInfoString) {
        NSData *infoData = [self.userInfoString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:infoData options:0 error:&err];
        return json;
    }
    
    return nil;
}

- (void)setUserInfo:(NSDictionary *)info{
    NSError *err;
    NSData *infoData = [NSJSONSerialization dataWithJSONObject:info options:NSJSONWritingPrettyPrinted error:&err];
    NSString *infoStr = [[NSString alloc] initWithData:infoData encoding:NSUTF8StringEncoding];
    self.userInfoString = infoStr;
}


@end
