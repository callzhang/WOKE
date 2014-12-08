//
//  NSString+Extend.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-9.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extend)

- (NSDate *)string2Date;
- (NSDate *)coredataString2Date;
- (NSMutableArray *)repeatArray;
- (NSString *)initial;
@end


@interface NSString (Color)

- (UIColor *)string2Color;

@end
