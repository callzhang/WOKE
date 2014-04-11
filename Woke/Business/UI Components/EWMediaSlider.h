//
//  EWMediaSlider.h
//  EarlyWorm
//
//  Created by Lei on 3/18/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWMediaItem;

@interface EWMediaSlider : UISlider{
    UILabel *typeLabel;
}
@property (nonatomic) UILabel *timeLabel;
@property (nonatomic) UIImageView *buzzIcon;
@property (nonatomic) UIImageView *playIndicator;
@property (nonatomic) NSInteger type;


- (void)play;
- (void)stop;
- (void)setUpWithMedia:(EWMediaItem *)media;
@end
