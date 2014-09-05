//
//  MBProgressHUD+Notification.m
//  EarlyWorm
//
//  Created by Lei on 3/31/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "UIView+Extend.h"

@implementation UIView(HUD)

- (void)showNotification:(NSString *)alert WithStyle:(HUDStyle)style{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [MBProgressHUD hideAllHUDsForView:self animated:YES];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        UIImage *img;
        switch (style) {
            case hudStyleSuccess:
                img = [UIImage imageNamed:@"37x-Checkmark"];
                break;
                
            case hudStyleFailed:
                img = [UIImage imageNamed:@"fail_37x"];
                break;
                
            case hudStyleWarning:
                img = [UIImage imageNamed:@"warning_37x"];
                break;
                
            default:
                break;
        }
        hud.customView = [[UIImageView alloc] initWithImage:img];
        hud.mode = MBProgressHUDModeCustomView;
        hud.labelText = alert;
        [hud hide:YES afterDelay:1.5];

    });
    }

- (void)showSuccessNotification:(NSString *)alert{
    [self showNotification:alert WithStyle:hudStyleSuccess];
}

- (void)showFailureNotification:(NSString *)alert{
    [self showNotification:alert WithStyle:hudStyleFailed];
}


@end


@implementation UIView (Sreenshot)

- (UIImage *)screenshot{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, self.window.screen.scale);
    
    /* iOS 7 */
    //BOOL visible = !self.hidden && self.superview != nil;
    BOOL animating = self.layer.animationKeys != nil;
    BOOL success = YES;
    if ([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]){
        //only works when visible
        //if (!animating) {
            success = [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
        //}else{
        //    success = [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
        //}
    
    }
    if(!success){ /* iOS 6 */
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

@end
