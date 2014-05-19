//
//  EWServer.h
//  EarlyWorm
//
//  Created by Lee on 2/21/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"
//#import <AWSRuntime/AWSRuntime.h>
//#import <AWSSNS/AWSSNS.h>


@interface EWServer : NSObject

+ (NSArray *)getPersonAlarmAtTime:(NSDate *)time location:(PFGeoPoint *)geoPoint;
+ (void)getPersonAlarmAtTime:(NSDate *)time location:(PFGeoPoint *)geoPoint completion: (void (^)(NSArray *results))successBlock;
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
+ (void)pushMedia:(EWMediaItem *)media ForUser:(EWPerson *)person;

#pragma mark - Push methods
+ (void)broadcastMessage:(NSString *)msg onSuccess:(void (^)(void))block onFailure:(void (^)(void))failureBlock;


/**
 Async method to call AWS publish with block handler
 @param pushDic
        the push payload
 @param users
        the EWPerson array
 @param successBlock
        block called when success
 @param failureBlock
        Blcok called when failure
 
 */
//+ (void)AWSPush:(NSDictionary *)pushDic toUsers:(NSArray *)users onSuccess:(void (^)(SNSPublishResponse *response))successBlock onFailure:(void (^)(NSException *exception))failureBlock;


/**
 Async method to call AWS publish with block handler
 @param pushDic
 the push payload
 @param users
 the EWPerson array
 @param successBlock
 block called when success
 @param failureBlock
 Blcok called when failure
 
 */
+ (void)parsePush:(NSDictionary *)pushPayload toUsers:(NSArray *)users completion:(PFBooleanResultBlock)block;

@end
