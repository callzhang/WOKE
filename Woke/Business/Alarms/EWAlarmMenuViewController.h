//
//  EWAlarmMenuViewController.h
//  Woke
//
//  Created by apple on 14-4-17.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWCollectionPersonCell.h"
#import "EWPerson.h"
#import "EWPersonViewController.h"
@protocol EWMenuButtonDelegate<NSObject>
-(void)buttontoperson;
-(void)buttontobuzz;
-(void)buttontovoice;
@end
@interface EWAlarmMenuViewController : UIViewController
@property( nonatomic,unsafe_unretained)id<EWMenuButtonDelegate>delegate;
@property(strong,nonatomic) UIView *alphaview;
@property(strong,nonatomic) UIButton *profilebutton;
@property(strong,nonatomic) UIButton *buzzbutton;
@property(strong,nonatomic) UIButton *voicebutton;
@property(strong,nonatomic) UIButton *closebutton;
@property(strong,nonatomic) UIImageView *personview;
@property(strong,nonatomic) EWCollectionPersonCell *personcellview;

-(void)viewDidLoadWithCell:(EWCollectionPersonCell*)cell;

@end
