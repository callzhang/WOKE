//
//  MBProgressHUD+Notification.h
//  EarlyWorm
//
//  Created by Lei on 3/31/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

@import UIKit;

typedef enum{
    hudStyleSuccess,
    hudStyleFailed,
    hudStyleWarning
}HUDStyle;

@interface UIView(HUD)

- (void)showNotification:(NSString *)alert WithStyle:(HUDStyle)style;
- (void)showSuccessNotification:(NSString *)alert;
- (void)showFailureNotification:(NSString *)alert;
@end

@interface UIView (Sreenshot)
- (UIImage *)screenshot;
@end