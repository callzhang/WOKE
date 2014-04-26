//
//  EWPopupMenu.h
//  Woke
//
//  Created by Lei on 4/26/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWCollectionPersonCell.h"
#import "EWPerson.h"
#import "EWPersonViewController.h"
#import<QuartzCore/QuartzCore.h>
@protocol EWMenuButtonDelegate<NSObject>
-(void)buttontoperson;
-(void)buttontobuzz;
-(void)buttontovoice;
@end

@interface EWPopupMenu : UIView
@property( nonatomic,unsafe_unretained)id<EWMenuButtonDelegate>delegate;
@property(strong,nonatomic) UIView *alphaview;
@property(strong,nonatomic) UIButton *profilebutton;
@property(strong,nonatomic) UIButton *buzzbutton;
@property(strong,nonatomic) UIButton *voicebutton;
@property(strong,nonatomic) UIButton *closebutton;
@property(strong,nonatomic) UIImageView *personview;
@property(strong,nonatomic) EWCollectionPersonCell *personcellview;
@property (nonatomic, retain) UIImageView *maskView;
@property(nonatomic,retain)UICollectionView *collectionView;
@property(nonatomic,retain)UIScrollView *scrollView;

//- (id)initWithFrame:(CGRect)frame
//       initWithCell:(EWCollectionPersonCell*)cell;
-(id)initWithCollectionView:(UICollectionView *)collectionView
               initWithCell:(EWCollectionPersonCell *)cell;

@end