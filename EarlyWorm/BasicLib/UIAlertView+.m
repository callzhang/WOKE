//
//  UIAlertView+.m
//  EarlyWorm
//
//  Created by Lei on 2/27/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "UIAlertView+.h"

@implementation UIAlertView(Extend)
@dynamic userInfo;

-(void)setUserInfo:(NSDictionary *)dic {
    objc_setAssociatedObject(self, @selector(userInfo), dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(id)context {
    return objc_getAssociatedObject(self, @selector(userInfo));
}

@end
