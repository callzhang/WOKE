//
//  EWCollectionPersonCell.h
//  EarlyWorm
//
//  Created by Lei on 3/2/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EWCollectionPersonCell : UICollectionViewCell

//@property (nonatomic, retain) UILabel *name;
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *time;
@property (weak, nonatomic) IBOutlet UIImageView *selectionView;
@property (weak, nonatomic) IBOutlet UIView *white;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UILabel *initial;
@property (nonatomic) NSString *name;

- (void)applyHexagonMask;

@end
