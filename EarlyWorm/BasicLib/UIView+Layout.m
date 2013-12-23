//
//  UIView+Autolayout.m
//  TinnyKnowIt
//
//  Created by shenslu on 12-10-31.
//  Copyright (c) 2012年 Shens. All rights reserved.
//

#import "UIView+Layout.h"

@implementation UIView (Layout)

- (void) setX: (CGFloat)_x {
    CGRect frame = self.frame;
    frame.origin.x = _x;
    self.frame = frame;
}

- (CGFloat)x {
    return self.frame.origin.x;
}

- (void) setY: (CGFloat)_y {
    CGRect frame = self.frame;
    frame.origin.y = _y;
    self.frame = frame;
}

- (CGFloat)y {
    return self.frame.origin.y;
}

- (void) setWidth: (CGFloat)_width {
    CGRect frame = self.frame;
    frame.size.width = _width;
    self.frame = frame;
}

- (CGFloat)width {
    return self.frame.size.width;
}

- (void) setHeight: (CGFloat)_height {
    CGRect frame = self.frame;
    frame.size.height = _height;
    self.frame = frame;
}

- (CGFloat)height {
    return self.frame.size.height;
}

- (void) setTop:(CGFloat)_top {
    [self setY:_top];
}

- (CGFloat)top {
    return self.y;
}

- (void) setBottom:(CGFloat)_bottom {
    CGRect frame = self.frame;
    frame.origin.y = _bottom - self.height;
    self.frame = frame;
}

- (CGFloat)bottom {
    return self.y + self.height;
}

- (void) setLeft:(CGFloat)_left {
    [self setX:_left];
}

- (CGFloat)left {
    return self.x;
}

- (void) setRight:(CGFloat)_right {
    CGRect frame = self.frame;
    frame.origin.x = _right - self.width;
    self.frame = frame;
}

- (CGFloat)right {
    return self.x + self.width;
}

@end


