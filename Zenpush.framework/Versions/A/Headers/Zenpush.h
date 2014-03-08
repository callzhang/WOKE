//
//  Zenpush.h
//  Zenpush
//
//  Created by Padraic Doyle on 10/16/12.
//  Copyright (c) 2012 Padraic Doyle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Zenpush : NSObject

- (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;
- (void)registerDeviceToken:(NSData *)devToken;
- (void)registerDeviceToken:(NSData *)devToken profileNamesForDevice:(NSArray *)deviceProfileNames;
- (void)registerDeviceToken:(NSData *)devToken alias:(NSString *) alias profileNamesForDevice:(NSArray *)deviceProfileNames;

@property (nonatomic, assign) BOOL set;

+ (Zenpush *)shared;

- (void)zenIn;
- (void)zenOut;

-(void)addDeviceToDeviceProfiles:(NSArray *)deviceProfileNames;
-(void)removeDeviceFromDeviceProfiles:(NSArray *)deviceProfileNames;

-(void)setAlias:(NSString *)alias;
-(void)removeAlias;

@end
