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

typedef void(^profilebuttonBlock)(void);
typedef void(^buzzbuttonBlock)(void);
typedef void(^voicebuttonBlock)(void);


@interface EWPopupMenu : UIView

@property(strong,nonatomic) UIView *alphaview;
@property(strong,nonatomic) UIButton *profilebutton;
@property(strong,nonatomic) UIButton *buzzbutton;
@property(strong,nonatomic) UIButton *voicebutton;
@property(strong,nonatomic) UIButton *closebutton;
@property(strong,nonatomic) UIImageView *personview;

-(id)initWithCollectionView:(UICollectionView *)collectionView
               initWithCell:(EWCollectionPersonCell *)cell;

-(void)toprofilebuttonWithBlock:(profilebuttonBlock)profile;
-(void)tobuzzbuttonWithBlock:(buzzbuttonBlock)buzz;
-(void)tovoicebuttonWithBlock:(voicebuttonBlock)voice;

@end