//
//  EWCollectionPersonCell.m
//  EarlyWorm
//
//  Created by Lei on 3/2/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWCollectionPersonCell.h"

@implementation EWCollectionPersonCell
@synthesize profilePic;
@synthesize name;
@synthesize selectionView;

//only called when registing class
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        
        //mask
        [self applyHexagonMaskForView:self.contentView];
        
        
        //boarder
//        UIImageView *boarderView = [[UIImageView alloc] initWithFrame:profilePic.frame];
//        UIGraphicsBeginImageContext(boarderView.frame.size);
//        [boarderView.image drawInRect:boarderView.frame];
//        [[UIColor colorWithWhite:1.0 alpha:0.8] setStroke];
//        UIBezierPath *hexagonPath = [self getHexagonPath];
//        hexagonPath.lineWidth = 4.0;
//        [hexagonPath stroke];
//        boarderView.image = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();

        
    }
    return self;
}

- (void)applyHexagonMask{
    [self applyHexagonMaskForView:self.contentView];
}

- (void)applyHexagonMaskForView:(UIView *)view{
    CAShapeLayer *hexagonMask = [[CAShapeLayer alloc] initWithLayer:view.layer];
    UIBezierPath *hexagonPath = [self getHexagonPath];
    hexagonMask.path = hexagonPath.CGPath;
    view.layer.mask  = hexagonMask;
    view.layer.masksToBounds = YES;
    //view.clipsToBounds = YES;
}

- (UIBezierPath *)getHexagonPath{
    
    UIBezierPath* polygonPath = [UIBezierPath bezierPath];
    [polygonPath moveToPoint: CGPointMake(70.23, 17.06)];
    [polygonPath addCurveToPoint: CGPointMake(45.22, 2.34) controlPoint1: CGPointMake(55, 8.1) controlPoint2: CGPointMake(56.04, 8.53)];
    [polygonPath addCurveToPoint: CGPointMake(34.71, 2.34) controlPoint1: CGPointMake(41.86, 0.42) controlPoint2: CGPointMake(37.52, 0.68)];
    [polygonPath addCurveToPoint: CGPointMake(9.73, 17.06) controlPoint1: CGPointMake(32.64, 3.57) controlPoint2: CGPointMake(17.78, 12.31)];
    [polygonPath addCurveToPoint: CGPointMake(5, 25.9) controlPoint1: CGPointMake(6.86, 18.76) controlPoint2: CGPointMake(4.97, 20.93)];
    [polygonPath addCurveToPoint: CGPointMake(5, 52.86) controlPoint1: CGPointMake(5.08, 39.43) controlPoint2: CGPointMake(5.06, 48.65)];
    [polygonPath addCurveToPoint: CGPointMake(9.73, 62.37) controlPoint1: CGPointMake(4.94, 57.06) controlPoint2: CGPointMake(6.39, 60.1)];
    [polygonPath addCurveToPoint: CGPointMake(34.71, 77.51) controlPoint1: CGPointMake(13.07, 64.64) controlPoint2: CGPointMake(31.59, 75.65)];
    [polygonPath addCurveToPoint: CGPointMake(45.22, 77.51) controlPoint1: CGPointMake(37.83, 79.36) controlPoint2: CGPointMake(41.56, 79.63)];
    [polygonPath addCurveToPoint: CGPointMake(70.23, 62.37) controlPoint1: CGPointMake(55.42, 71.57) controlPoint2: CGPointMake(68.24, 63.93)];
    [polygonPath addCurveToPoint: CGPointMake(74.99, 52.86) controlPoint1: CGPointMake(72.93, 60.25) controlPoint2: CGPointMake(74.98, 58.06)];
    [polygonPath addCurveToPoint: CGPointMake(74.99, 25.9) controlPoint1: CGPointMake(75, 41.06) controlPoint2: CGPointMake(75, 40.06)];
    [polygonPath addCurveToPoint: CGPointMake(70.23, 17.06) controlPoint1: CGPointMake(74.98, 20.8) controlPoint2: CGPointMake(74.04, 19.3)];
    [polygonPath closePath];
    polygonPath.miterLimit = 11;
    
    polygonPath.lineJoinStyle = kCGLineJoinRound;
    
    
    return polygonPath;
}


@end
