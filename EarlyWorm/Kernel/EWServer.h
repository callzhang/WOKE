//
//  EWServer.h
//  EarlyWorm
//
//  Created by Lee on 2/21/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"
#import <AWSRuntime/AWSRuntime.h>
#import <AWSSNS/AWSSNS.h>

@interface EWServer : NSObject <UIAlertViewDelegate>
+ (void)getPersonWakingUpForTime:(NSDate *)timeSince1970 location:(SMGeoPoint *)geoPoint callbackBlock:(SMFullResponseSuccessBlock)successBlock;

/**
 Send buzz
 */
+ (void)buzz:(NSArray *)users;

/**
 Send push notification for media
 @params mediaId: mediaId
 @params users: array of EWPerson
 @params taskId: taskId
 */
+ (void)pushMedia:(NSString *)mediaId ForUsers:(NSArray *)users ForTask:(NSString *)taskId;



/**
 Async method to call AWS publish with block handler
 */
+ (void)AWSPush:(NSDictionary *)pushDic toUsers:(NSArray *)users onSuccess:(void (^)(SNSPublishResponse *response))successBlock onFailure:(void (^)(NSException *exception))failureBlock;



@end
