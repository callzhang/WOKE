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

+ (CGFloat)distanceOfRectMid:(CGRect)rect1 toRectMid:(CGRect)rect2{
    
    CGFloat distance = sqrt(pow((CGRectGetMidX(rect1) - CGRectGetMidX(rect2)),2) + pow((CGRectGetMidY(rect1) - CGRectGetMidY(rect2)), 2));
    return distance;
}

+ (CGFloat)distanceOfPoint:(CGPoint)point1 toPoint:(CGPoint)point2{
    CGFloat distance = sqrt(pow((point1.x - point2.x),2) + pow((point1.y - point2.y), 2));
    return distance;
}

+ (void)addImage:(UIImage *)image toAlertView:(UIAlertView *)alert{
    
    alert.message = [NSString stringWithFormat:@"\n\n\n\n\n%@", alert.message];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
    CGRect frame = imgView.frame;
    frame.origin.x = 40;
    frame.origin.y = (alert.frame.size.width - imgView.frame.size.width)/2;
    
}

+ (void)applyHexagonMaskForView:(UIView *)view{
    float originalSize = 80.0;
    
    //get mask
    CAShapeLayer *hexagonMask = [[CAShapeLayer alloc] initWithLayer:view.layer];
    UIBezierPath *hexagonPath = [EWUIUtil getHexagonPath];
    
    //scale
    float height = view.bounds.size.height;
    float width = view.bounds.size.width;
    float ratio = MAX(height, width)/originalSize;
    [hexagonPath applyTransform:CGAffineTransformMakeScale(ratio, ratio)];
    
    //apply mask
    hexagonMask.path = hexagonPath.CGPath;
    view.layer.mask  = hexagonMask;
    view.layer.masksToBounds = YES;
    view.clipsToBounds = YES;
}

+ (void)applyHexagonSoftMaskForView:(UIView *)view{
    float originalSize = 80.0;
    CAShapeLayer *hexagonMask = [[CAShapeLayer alloc] initWithLayer:view.layer];
    UIBezierPath *hexagonPath = [EWUIUtil getHexagonSoftPath];
    
    //scale
    float height = view.bounds.size.height;
    float width = view.bounds.size.width;
    float ratio = MAX(height, width)/originalSize;
    [hexagonPath applyTransform:CGAffineTransformMakeScale(ratio, ratio)];
    
    //apply mask
    hexagonMask.path = hexagonPath.CGPath;
    view.layer.mask  = hexagonMask;
    view.layer.masksToBounds = YES;
    //view.clipsToBounds = YES;
    
    //stroke
//    
//    [[UIColor whiteColor] setStroke];
//    hexagonPath.lineWidth = 1;
//    [hexagonPath stroke];
}

+ (UIBezierPath *)getHexagonSoftPath{
    
    UIBezierPath* polygonPath = [UIBezierPath bezierPath];
    [polygonPath moveToPoint: CGPointMake(72.5, 17.5)];
    [polygonPath addCurveToPoint: CGPointMake(42.87, 0.93) controlPoint1: CGPointMake(65.28, 13.42) controlPoint2: CGPointMake(47.9, 3.76)];
    [polygonPath addCurveToPoint: CGPointMake(36.84, 0.93) controlPoint1: CGPointMake(41, -0.12) controlPoint2: CGPointMake(38.37, 0.06)];
    [polygonPath addCurveToPoint: CGPointMake(8.07, 17.62) controlPoint1: CGPointMake(35.71, 1.57) controlPoint2: CGPointMake(13.74, 14.31)];
    [polygonPath addCurveToPoint: CGPointMake(5, 22.5) controlPoint1: CGPointMake(6.05, 18.81) controlPoint2: CGPointMake(4.99, 20.08)];
    [polygonPath addCurveToPoint: CGPointMake(5, 57) controlPoint1: CGPointMake(5.02, 29.07) controlPoint2: CGPointMake(4.99, 55.25)];
    [polygonPath addCurveToPoint: CGPointMake(7.5, 61.5) controlPoint1: CGPointMake(5.01, 58.75) controlPoint2: CGPointMake(5.97, 60.61)];
    [polygonPath addCurveToPoint: CGPointMake(37.47, 78.89) controlPoint1: CGPointMake(9.03, 62.39) controlPoint2: CGPointMake(35.79, 77.96)];
    [polygonPath addCurveToPoint: CGPointMake(42.87, 78.89) controlPoint1: CGPointMake(39.15, 79.82) controlPoint2: CGPointMake(40.63, 80.28)];
    [polygonPath addCurveToPoint: CGPointMake(73.01, 61.05) controlPoint1: CGPointMake(49.13, 75.01) controlPoint2: CGPointMake(71.62, 61.94)];
    [polygonPath addCurveToPoint: CGPointMake(74.99, 56.45) controlPoint1: CGPointMake(74.9, 59.83) controlPoint2: CGPointMake(75, 58.3)];
    [polygonPath addCurveToPoint: CGPointMake(74.99, 22.64) controlPoint1: CGPointMake(74.97, 52.25) controlPoint2: CGPointMake(74.93, 29.58)];
    [polygonPath addCurveToPoint: CGPointMake(72.5, 17.5) controlPoint1: CGPointMake(75.01, 20.14) controlPoint2: CGPointMake(74.31, 18.52)];
    [polygonPath closePath];
    polygonPath.miterLimit = 11;
    polygonPath.lineJoinStyle = kCGLineJoinRound;
    
    
    return polygonPath;
}

+ (UIBezierPath *)getHexagonPath{
    UIBezierPath* polygonPath = [UIBezierPath bezierPath];
    [polygonPath moveToPoint: CGPointMake(40, -0)];
    [polygonPath addLineToPoint: CGPointMake(5, 20)];
    [polygonPath addLineToPoint: CGPointMake(5, 60)];
    [polygonPath addLineToPoint: CGPointMake(40, 80)];
    [polygonPath addLineToPoint: CGPointMake(75, 60)];
    [polygonPath addLineToPoint: CGPointMake(75, 20)];
    [polygonPath addLineToPoint: CGPointMake(40, -0)];
    [polygonPath closePath];
    
    return polygonPath;
}

+ (void)applyShadow:(UIView *)view{
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    float op = 0.4;
    float r = 5;
    if ([view isKindOfClass:[UILabel class]]) {
        op = 1.0;
        r = 3;
    }
    view.layer.shadowOpacity = op;
    view.layer.shadowRadius = r;
    view.layer.shadowOffset = CGSizeMake(0,0);
    view.clipsToBounds = NO;
}

+ (CGPoint)getCartesianFromPolarCoordinateOfR:(float)r degree:(float)d{
    float degree_pi = d/180 * M_PI;
    float x = r * cosf(degree_pi);
    float y = r * sinf(degree_pi);
    CGPoint p = CGPointMake(x, y);
    return p;
}

+ (void)applyAlphaGradientForView:(UIView *)view withEndPoints:(NSArray *)locations{
    //alpha mask
    UIView *mask = [[UIView alloc] initWithFrame:view.frame];
    [view.superview insertSubview:mask aboveSubview:view];
    [mask addSubview:view];
    view.frame = mask.bounds;
    mask.backgroundColor = [UIColor clearColor];
    
    CAGradientLayer *alphaMask = [CAGradientLayer layer];
    alphaMask.anchorPoint = CGPointZero;
    alphaMask.startPoint = CGPointZero;
    alphaMask.endPoint = CGPointMake(0.0f, 1.0f);
    UIColor *startColor = [UIColor colorWithWhite:1.0 alpha:0.0];
    UIColor *endColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    NSArray *endPoints;
    NSArray *colors;
    if (locations.count == 1) {
        endPoints = @[@0.0, locations[0], @1.0];
        colors = @[(id)startColor.CGColor, (id)endColor.CGColor, (id)endColor.CGColor];
    }else if (locations.count == 2){
        endPoints = @[@0.0, locations[0], locations[1], @1.0];
        colors = @[(id)startColor.CGColor, (id)endColor.CGColor, (id)endColor.CGColor, (id)startColor.CGColor];
    }
    alphaMask.colors = colors;
    alphaMask.locations =endPoints;
    alphaMask.bounds = CGRectMake(0, 0, mask.frame.size.width, mask.frame.size.height);
    
    mask.layer.mask = alphaMask;
    
}

+ (void)addTransparantNavigationBarToViewController:(UIViewController *)vc withLeftItem:(UIBarButtonItem *)leftItem rightItem:(UIBarButtonItem *)rightItem{
    //first detect if navigation item exists
    if (vc.navigationController) {
        [vc.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        vc.navigationController.navigationBar.shadowImage = [UIImage new];
        vc.navigationController.navigationBar.translucent = YES;
        vc.navigationController.view.backgroundColor = [UIColor clearColor];
        vc.navigationItem.rightBarButtonItem = rightItem;
        vc.navigationItem.leftBarButtonItem = leftItem;
        vc.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    }else{
        //not in navigation controller
        UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(260, 20, 40, 40)];
        [closeBtn setImage:[UIImage imageNamed:@"Close Button"] forState:UIControlStateNormal];
        [closeBtn addTarget:vc action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
        [vc.view addSubview:closeBtn];
    }
    
}

+ (NSString *)getStringFromTime:(float)time{
    
    NSString *timeStr;
    NSInteger t = (NSInteger)time;
    NSInteger hours = floor(t / 3600);
    NSInteger minutes = floor((t % 3600)/60);
    NSInteger seconds = t % 60;
    
    if (hours > 10) {
        timeStr = [NSString stringWithFormat:@"%.1f hours",time/3600];
    }else if (hours > 0){
        timeStr = [NSString stringWithFormat:@"%ld hours",(long)hours];
    }else if(minutes > 0){
        timeStr = [NSString stringWithFormat:@"%ld minutes",(long)minutes];
    }else{
        timeStr = [NSString stringWithFormat:@"%ld seconds",(long)seconds];
    }
        return timeStr;
}

@end
