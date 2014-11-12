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
#import "UIAlertView+.h"

//model
#import "EWDataStore.h"
#import "EWPersonManager.h"
//#import "EWTaskItem.h"
//#import "EWTaskManager.h"
#import "EWMedia.h"
#import "EWMediaManager.h"
#import "EWDownloadManager.h"
#import "EWNotification.h"
#import "EWNotificationManager.h"
#import "EWWakeUpManager.h"

//view
#import "EWWakeUpViewController.h"
#import "EWAppDelegate.h"
#import "AVManager.h"
#import "UIAlertView+.h"
#import "EWSleepViewController.h"

//Tool
#import "EWUIUtil.h"
#import "EWAlarmManager.h"

@implementation EWServer

+ (EWServer *)sharedInstance{
    static EWServer *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWServer alloc] init];
    });
    return manager;
}

#pragma mark - Handle Push Notification
+ (void)handlePushNotification:(NSDictionary *)push{
	NSString *type = push[kPushType];
					  
    if ([type isEqualToString:kPushTypeMedia]) {
		[EWWakeUpManager handlePushMedia:push];
		
	}
	else if([type isEqualToString:kPushTypeAlarmTimer]){
		// ============== Alarm Timer ================
		[EWWakeUpManager handleAlarmTimerEvent:push];
		
	}
	else if ([type isEqualToString:kPushTypeNotification]){
		NSString *notificationID = push[kPushNofiticationID];
		[EWNotificationManager handleNotification:notificationID];
	}
    else if ([type isEqualToString:kPushTypeBroadcast]){
        NSString *message = push[@"alert"];
        EWAlert(message);
    }
	else{
		// Other push type not supported
		NSString *str = [NSString stringWithFormat:@"Unknown push type received: %@", push];
		DDLogError(@"Received unknown type of push msg: %@", str);
#ifdef DEBUG
		EWAlert(str);
#endif
	}
}


#pragma mark - Handle Local Notification
+ (void)handleLocalNotification:(UILocalNotification *)notification{
    NSString *type = notification.userInfo[kLocalNotificationTypeKey];
    NSLog(@"Received local notification: %@", type);
    
    if ([type isEqualToString:kLocalNotificationTypeAlarmTimer]) {
        [EWWakeUpManager handleAlarmTimerEvent:notification.userInfo];
		
    }else if([type isEqualToString:kLocalNotificationTypeReactivate]){
        DDLogInfo(@"==================> Reactivated Woke <======================");
        EWAlert(@"You brought me back!");
		
    }else if ([type isEqualToString:kLocalNotificationTypeSleepTimer]){
        NSLog(@"=== Received Sleep timer local notification, broadcasting sleep event, and enter sleep mode... \n%@", notification);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kSleepNotification object:notification];
        
        [EWWakeUpManager handleSleepTimerEvent:notification];
    }
    else{
        NSLog(@"Unexpected Local Notification Type. Detail: %@", notification);
    }

}



#pragma mark - Send Voice tone
+ (void)pushVoice:(EWMedia *)media toUser:(EWPerson *)person{
    
    NSString *mediaId = media.objectId;
    NSDate *time = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:person];
    
    NSMutableDictionary *pushMessage = [@{@"badge": @"Increment",
                                 @"alert": @"Someone has sent you an voice greeting",
                                 @"content-available": @1,
                                 kPushType: kPushTypeMedia,
                                 kPushMediaType: kPushMediaTypeVoice,
                                 kPushPersonID: [EWSession sharedSession].currentUser.objectId,
                                 kPushMediaID: mediaId} mutableCopy];
    
    //form push payload
    if ([[NSDate date] isEarlierThan:time]) {
        //early, silent message

    }else if(time.timeElapsed < kMaxWakeTime){
        //struggle state
        pushMessage[@"sound"] = @"media.caf";
        pushMessage[@"alert"] = @"Someone has sent you an voice greeting";
        
    }else{
        //send silent push for next task
        
    }
    
    //push
    [EWServer parsePush:pushMessage toUsers:@[person] completion:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [rootViewController.view showSuccessNotification:@"Sent"];
        }else{
            NSLog(@"Send push message about media %@ failed. Reason:%@", mediaId, error.description);
            [rootViewController.view showFailureNotification:@"Failed"];
        }
    }];
    
    //save
    [EWSync save];
    
}



+ (void)broadcastMessage:msg onSuccess:(void (^)(void))block onFailure:(void (^)(void))failureBlock{
    
    NSDictionary *payload = @{@"alert": msg,
                              @"sound": @"new.caf",
                              kPushType: kPushTypeBroadcast};
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKeyExists:@"username"];
    PFPush *push = [PFPush new];
    [push setQuery:pushQuery];
    [push setData:payload];
    block = block?:NULL;
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded && block) {
            block();
        }else if (failureBlock){
            NSLog(@"Failed to broadcast push message: %@", error.description);
            failureBlock();
        }
    }];
}


#pragma mark - Parse Push
+ (void)parsePush:(NSDictionary *)pushPayload toUsers:(NSArray *)users completion:(PFBooleanResultBlock)block{
    
    NSArray *userIDs = [users valueForKey:kUsername];
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:kUsername containedIn:userIDs];
    PFPush *push = [PFPush new];
    [push setQuery:pushQuery];
    [push setData:pushPayload];
    block = block?:NULL;
    //[push sendPushInBackgroundWithBlock:block];
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        block(succeeded, error);
    }];
}


#pragma mark - PUSH

+ (void)registerAPNS{
    //push
#if TARGET_IPHONE_SIMULATOR
    //Code specific to simulator
#else
    //pushClient = [[SMPushClient alloc] initWithAPIVersion:@"0" publicKey:kStackMobKeyDevelopment privateKey:kStackMobKeyDevelopmentPrivate];
    //register everytime in case for events like phone replacement
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeNewsstandContentAvailability | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
#endif
}

+ (void)registerPushNotificationWithToken:(NSData *)deviceToken{
    
    //Parse: Store the deviceToken in the current Installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}


+(void)searchForFriendsOnServer
{
    PFQuery *q = [PFQuery queryWithClassName:@"User"];
    
    //[q whereKey:@"email" containedIn:[EWUtil readContactsEmailsFromAddressBooks]];
    
    [EWSync findServerObjectInBackgroundWithQuery:q completion:^(NSArray *objects, NSError *error) {
        if (!error) {
            
            // push  notification;
            
            
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    
}

+(void)publishOpenGraphUsingAPICallsWithObjectId:(NSString *)objectId andUrlString:(NSString *)url {
    
    // We will post a story on behalf of the user
    // These are the permissions we need:
    NSArray *permissionsNeeded = @[@"publish_actions"];
    
    // Request the permissions the user currently has
    [FBRequestConnection startWithGraphPath:@"/me/permissions"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error){
                                  NSDictionary *currentPermissions= [(NSArray *)[result data] objectAtIndex:0];
                                  NSLog(@"current permissions %@", currentPermissions);
                                  NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
                                  
                                  // Check if all the permissions we need are present in the user's current permissions
                                  // If they are not present add them to the permissions to be requested
                                  for (NSString *permission in permissionsNeeded){
                                      if (![currentPermissions objectForKey:permission]){
                                          [requestPermissions addObject:permission];
                                      }
                                  }
                                  
                                  // If we have permissions to request
                                  if ([requestPermissions count] > 0){
                                      // Ask for the missing permissions
                                      [FBSession.activeSession requestNewPublishPermissions:requestPermissions
                                                                            defaultAudience:FBSessionDefaultAudienceFriends
                                                                          completionHandler:^(FBSession *session, NSError *error) {
                                                                              if (!error) {
                                                                                  // Permission granted
                                                                                  NSLog(@"new permissions %@", [FBSession.activeSession permissions]);
                                                                                  // We can request the user information
                                                          [EWServer makeRequestToPostStoryWithId:objectId andUrlString:url];
                                                        //upload a graph and form a OG story
                                                                                  
                                                                              } else {
                                                                                  // An error occurred, we need to handle the error
                                                                                  // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                                                                  NSLog(@"error %@", error.description);
                                                                              }
                                                                          }];
                                  } else {
                                      // Permissions are present
                                      // We can request the user information
                                      
                                      [EWServer makeRequestToPostStoryWithId:objectId andUrlString:url];
                                       //upload a graph and form a OG story
                                  }
                                  
                              } else {
                                  // An error occurred, we need to handle the error
                                  // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                  NSLog(@"error %@", error.description);
                              }
                          }];

    
    
}







+(void)updatingStatusInFacebook:(NSString *)status
{
    // NOTE: pre-filling fields associated with Facebook posts,
    // unless the user manually generated the content earlier in the workflow of your app,
    // can be against the Platform policies: https://developers.facebook.com/policy
    
    [FBRequestConnection startForPostStatusUpdate:status
                                completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                    if (!error) {
                                        // Status update posted successfully to Facebook
                                        NSLog(@"result: %@", result);
                                        
                                    } else {
                                        // An error occurred, we need to handle the error
                                        // See: https://developers.facebook.com/docs/ios/errors
                                        NSLog(@"%@", error.description);
                                    }
                                }];
}

+(void)uploadOGStoryWithPhoto:(UIImage *)image

{
    
    [FBRequestConnection startForUploadStagingResourceWithImage:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        //__block NSString *alertText;
        //__block NSString *alertTitle;
        __block NSString *urlString ;
        if(!error) {
            
            NSArray *image = @[@{@"url": [result objectForKey:@"uri"], @"user_generated" : @"true" }];
            
            urlString = [result objectForKey:@"uri"];
   
            // Package image inside a dictionary, inside an array like we'll need it for the object
            
            
            // Create an object
            NSMutableDictionary<FBOpenGraphObject> *place = [FBGraphObject openGraphObjectForPost];
            
            // specify that this Open Graph object will be posted to Facebook
            place.provisionedForPost = YES;
            
            // Add the standard object properties
            place[@"og"] = @{ @"title":@"Woke Now", @"type":@"woke_alarm:people", @"description":@"Woke up", @"image":image };
            
            // Add the properties restaurant inherits from place
            place[@"place"] = @{ @"location" : @{ @"longitude": @"-58.381667", @"latitude":@"-34.603333"} };
            
            // Add the properties particular to the type restaurant.restaurant
            place[@"restaurant"] = @{@"category": @[@"Mexican"],
                                          @"contact_info": @{@"street_address": @"123 Some st",
                                                             @"locality": @"Menlo Park",
                                                             @"region": @"CA",
                                                             @"phone_number": @"555-555-555",
                                                             @"website": @"http://www.example.com"}};
            
            // Make the Graph API request to post the object
            FBRequest *request = [FBRequest requestForPostWithGraphPath:@"me/objects/woke_alarm:people"
                                                            graphObject:@{@"object":place}];
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    // Success! Include your code to handle the results here
                    NSLog(@"result: %@", result);
                    NSString *  _objectID = [result objectForKey:@"id"];
                    [EWServer publishOpenGraphUsingAPICallsWithObjectId:_objectID andUrlString:urlString];
                    
                } else {
                    // An error occurred, we need to handle the error
                    // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                    NSLog(@"error %@", error.description);
                }
            }];
        } else {
            // An error occurred, we need to handle the error
            // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
            NSLog(@"error %@", error.description);
        }
    }];

}

+(void)makeRequestToPostStoryWithId:(NSString *)objectId andUrlString:(NSString *)url
{
    if(!objectId){
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Please tap the \"Post an object\" button first to create an object, then you can click on this button to like it."
                                   delegate:self
                          cancelButtonTitle:@"OK!"
                          otherButtonTitles:nil] show];
    } else {
        // Create a like action
        id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
        
        // Link that like action to the restaurant object that we have created
//        [action setObject:objectId forKey:@"object"];
        action[@"people"] = objectId;
        
        // Post the action to Facebook
        [FBRequestConnection startForPostWithGraphPath:@"me/woke_alarm:woke"
                                           graphObject:action
                                     completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                         __block NSString *alertText;
                                         __block NSString *alertTitle;
                                         if (!error) {
                                             // Success, the restaurant has been liked
                                             NSLog(@"Posted OG action, id: %@", [result objectForKey:@"id"]);
                                             alertText = [NSString stringWithFormat:@"Posted OG action, id: %@", [result objectForKey:@"id"]];
                                             alertTitle = @"Success";
                                             [[[UIAlertView alloc] initWithTitle:alertTitle
                                                                         message:alertText
                                                                        delegate:self
                                                               cancelButtonTitle:@"OK!"
                                                               otherButtonTitles:nil] show];
                                         } else {
                                             // An error occurred, we need to handle the error
                                             // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                             NSLog(@"error %@", error.description);
                                         }
                                     }];
        
    }
    
   
 }


@end
