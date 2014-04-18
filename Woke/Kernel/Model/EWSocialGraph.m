//
//  EWSocialGraph.m
//  Woke
//
//  Created by Lei on 4/16/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWSocialGraph.h"


@implementation EWSocialGraph

@dynamic ewsocialgraph_id;
@synthesize facebookFriends;
@dynamic facebook_friends_string;
@dynamic facebookUpdated;
@dynamic createddate;
@dynamic lastmoddate;
@dynamic owner;
@dynamic sm_owner;
@synthesize weiboFriends;
@dynamic weibo_friends_string;
@dynamic weiboUpdated;




#pragma mark - facebookFriends
- (NSDictionary *)facebookFriends{
    if (self.facebook_friends_string) {
        NSData *prefData = [self.facebook_friends_string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:prefData options:0 error:&err];
        return json;
    }else{
        NSDictionary *friends = [NSDictionary new];
        self.facebookFriends = friends;
        return friends;
    }
    return nil;
}

- (void)setFacebookFriends:(NSDictionary *)friends{
    NSError *err;
    NSData *friendsData = [NSJSONSerialization dataWithJSONObject:friends options:NSJSONWritingPrettyPrinted error:&err];
    NSString *friendsStr = [[NSString alloc] initWithData:friendsData encoding:NSUTF8StringEncoding];
    self.facebook_friends_string = friendsStr;
}




#pragma mark - weiboFriends
- (NSDictionary *)weiboFriends{
    if (self.weibo_friends_string) {
        NSData *weiboFriendsData = [self.weibo_friends_string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:weiboFriendsData options:0 error:&err];
        return json;
    }else{
        NSDictionary *friends = [NSDictionary new];
        self.weiboFriends = friends;
        return friends;
    }
    return nil;
}

- (void)setWeiboFriends:(NSDictionary *)friends{
    NSError *err;
    NSData *friendsData = [NSJSONSerialization dataWithJSONObject:friends options:NSJSONWritingPrettyPrinted error:&err];
    NSString *friendsStr = [[NSString alloc] initWithData:friendsData encoding:NSUTF8StringEncoding];
    self.weibo_friends_string = friendsStr;
}

@end
