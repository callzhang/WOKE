//
//  EWUIUtil.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-3.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWUIUtil.h"
#import "EWAppDelegate.h"

@implementation EWUIUtil

+ (CGFloat)screenWidth {
    return [[UIScreen mainScreen] bounds].size.width;
}

+ (CGFloat)screenHeight {
    return [[UIScreen mainScreen] bounds].size.height;
}

+ (CGFloat)navigationBarHeight {
    return 44;
}

+ (CGFloat)statusBarHeight {
    return [UIApplication sharedApplication].statusBarFrame.size.height;
}

+ (void)OnSystemStatusBarFrameChange {
    
}

+ (BOOL) isMultitaskingSupported {
    
    BOOL result = NO;
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]){
        result = [[UIDevice currentDevice] isMultitaskingSupported];
    }
    return result;
}

+ (void)showHUDWithCheckMark:(NSString *)str{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootViewController.view animated:YES];
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
    hud.mode = MBProgressHUDModeCustomView;
    hud.labelText = str;
    [hud hide:YES afterDelay:1.5];
}

+ (NSString *)toString:(NSDictionary *)dic{
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:NULL];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return str;
}

@end
