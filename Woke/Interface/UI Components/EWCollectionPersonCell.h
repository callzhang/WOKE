//
//  EWCollectionPersonCell.h
//  EarlyWorm
//
//  Created by Lei on 3/2/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EWPerson;
@interface EWCollectionPersonCell : UICollectionViewCell

//@property (nonatomic, retain) UILabel *name;
@property (weak, nonatomic) IBOutlet UIImageView *profile;
@property (weak, nonatomic) IBOutlet UIImageView *selection;
@property (weak, nonatomic) IBOutlet UIView *image;
@property (weak, nonatomic) IBOutlet UILabel *info;
@property (weak, nonatomic) IBOutlet UILabel *initial;
@property (strong, nonatomic) IBOutlet UILabel *name;

@property (nonatomic,strong)NSString *timeAndDistance;
@property (nonatomic, strong) EWPerson *person;
@property (nonatomic) float distance;
@property (nonatomic) float timeLeft;
@property (nonatomic) BOOL showName;
@property (nonatomic) BOOL showDistance;
@property (nonatomic) BOOL showTime;
- (void)applyHexagonMask;
- (void)prepareForDisplay;
@end
