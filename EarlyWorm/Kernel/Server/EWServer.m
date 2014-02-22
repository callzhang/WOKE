//
//  EWServer.m
//  EarlyWorm
//
//  Created by Lee on 2/21/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWServer.h"
#import "EWDataStore.h"
#import "EWPersonStore.h"

@implementation EWServer

+ (NSArray *)getPersonWakingUpForUser:(EWPerson *)user time:(NSInteger)timeSince1970 location:(NSString *)locationStr{
    NSLog(@"%s", __func__);
    
    SMCustomCodeRequest *request = [[SMCustomCodeRequest alloc]
                                    initGetRequestWithMethod:@"get_person_waking_up"];
    __block NSArray *personList;
    [request addQueryStringParameterWhere:@"personId" equals:user.username];
    [request addQueryStringParameterWhere:@"time" equals:[NSString stringWithFormat:@"%ld", (long)timeSince1970]];
    [request addQueryStringParameterWhere:@"location" equals:locationStr];
    
    [[[SMClient defaultClient] dataStore]
     performCustomCodeRequest:request
     onSuccess:^(NSURLRequest *request,
                 NSHTTPURLResponse *response,
                 id responseBody) {
         NSLog(@"Success: %@",responseBody);
         personList = [(NSDictionary *)responseBody objectForKey:@"person"];
     } onFailure:^(NSURLRequest *request,
                   NSHTTPURLResponse *response,
                   NSError *error,
                   id responseBody){
         NSLog(@"Failure: %@",error);
     }];
}

@end
