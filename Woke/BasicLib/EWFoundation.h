//
//  EWFoundation.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-31.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWFoundation : NSObject


@end

#define SAFE_DELEGATE_RETURN(obj, sel, func) {(obj && [obj respondsToSelector:sel])?[obj func]:nil}
#define SAFE_DELEGATE_VOID(obj,sel,func) { if(obj&&[obj respondsToSelector:sel]) [obj func];}
