//
//  EWServer.h
//  EarlyWorm
//
//  Created by Lee on 2/21/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"

@interface EWServer : NSObject

#pragma mark - Handle Push Notification
+ (void)handlePushNotification:(NSDictionary *)push;

#pragma mark - Handle Local Notification
+ (void)handleLocalNotification:(UILocalNotification *)localNotif;

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
+ (void)pushVoice:(EWMedia *)media toUser:(EWPerson *)person;

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


#pragma mark - Push notification
/**
 Initiate the Push Notification registration to APNS
 */
+ (void)registerAPNS;
/**
 Handle the returned token for registered device. Register the push service to 3rd party server.
 */
+ (void)registerPushNotificationWithToken:(NSData *)deviceToken;


+ (void)searchForFriendsOnServer;

+(void)publishOpenGraphUsingAPICallsWithObjectId:(NSString *)objectId andUrlString:(NSString *)url;

+(void)publishOpenGraphUsingShareDialog;// un wirte

+(void)makeRequestToPostStory;

+(void)updatingStatusInFacebook:(NSString *)status;

+(void)uploadOGStoryWithPhoto:(UIImage *)image;// use this to update a OG story

+(void)makeRequestToPostStoryWithId:(NSString *)objectId andUrlString:(NSString *)url;
@end
