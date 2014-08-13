//
//  EWPopupMenu.h
//  Woke
//
//  Created by Lei on 4/26/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "EWCollectionPersonCell.h"
//#import "EWPerson.h"
//#import "EWPersonViewController.h"
//#import <QuartzCore/QuartzCore.h>

typedef void(^profileButtonBlock)(void);
typedef void(^buzzButtonBlock)(void);
typedef void(^voiceButtonBlock)(void);


@interface EWPopupMenu : UIView

@property (strong, nonatomic) UIView *alphaView;
@property (strong, nonatomic) UIButton *profileButton;
@property (strong, nonatomic) UIButton *buzzButton;
@property (strong, nonatomic) UIButton *voiceButton;
@property (strong, nonatomic) UIButton *closeButton;
@property (nonatomic, copy) profileButtonBlock toProfileButtonBlock;
@property (nonatomic, copy) buzzButtonBlock toBuzzButtonBlock;
@property (nonatomic, copy) voiceButtonBlock toVoiceButtonBlock;

- (instancetype)initWithCell:(EWCollectionPersonCell *)cell;
- (void)closeMenu;
- (void)closeMenuWithCompletion:(void (^)(void))block;
//+ (void)flipCell:(EWCollectionPersonCell *)cell completion:(void (^)(void))block;

@end