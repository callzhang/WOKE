//
//  EWServer.m
//  EarlyWorm
//
//  Translate client requests to server custom code, providing a set of tailored APIs to client coding environment.
//
//  Created by Lee on 2/21/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWServer.h"
#import "EWDataStore.h"
#import "EWPersonStore.h"

@implementation EWServer

+ (void)getPersonWakingUpForTime:(NSDate *)time location:(SMGeoPoint *)geoPoint callbackBlock:(SMFullResponseSuccessBlock)successBlock{
    NSLog(@"%s", __func__);
    
    NSString *userId = currentUser.username;
    NSInteger timeSince1970 = (NSInteger)[time timeIntervalSince1970];
    NSString *timeStr = [NSString stringWithFormat:@"%d", timeSince1970];
    NSString *lat = [geoPoint.latitude stringValue];
    NSString *lon = [geoPoint.longitude stringValue];
    NSString *geoStr = [NSString stringWithFormat:@"%@,%@", lat, lon];
    
    
    SMCustomCodeRequest *request = [[SMCustomCodeRequest alloc]
                                    initGetRequestWithMethod:@"get_person_waking_up"];
    
    [request addQueryStringParameterWhere:@"personId" equals:userId];
    [request addQueryStringParameterWhere:@"time" equals:timeStr];
    [request addQueryStringParameterWhere:@"location" equals:geoStr];
    
    [[[SMClient defaultClient] dataStore]
     performCustomCodeRequest:request
     onSuccess:successBlock
     onFailure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id responseBody){
         [NSException raise:@"Server custom code error" format:@"Reason: %@", error.description];
         //retry...
         
     }];
}

+ (void)buzz:(EWPerson *)user{
    //TODO: buzz sound selection
    //TODO: buzz message selection
    
    
    //send push notification, The payload can consist of the alert, badge, and sound keys.
    NSDictionary *pushMessage = @{@"alert": [NSString stringWithFormat:@"New buzz from %@", currentUser.name],
                                  @"badge": @1,
                                  @"from": currentUser.username,
                                  @"type": @"buzz",
                                  @"sound": @"buzz.caf"};
    
    [pushClient sendMessage:pushMessage toUsers:@[user.username] onSuccess:^{
        NSLog(@"Push notification successfully sent to %@", user.username);
    } onFailure:^(NSError *error) {
        [NSException raise:@"Failed to send push notification" format:@"Reason: %@", error.description];
    }];

}

@end
