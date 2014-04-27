//
//  EWPopupMenu.m
//  Woke
//
//  Created by Lei on 4/26/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWPopupMenu.h"

@implementation EWPopupMenu
//-(UIImage *)convertViewToImage
//{
//    UIGraphicsBeginImageContext(self.bounds.size);
//    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return image;
//}
-(id)initWithCollectionView:(UICollectionView *)collectionView
               initWithCell:(EWCollectionPersonCell *)cell
{
    self.tag=1;
    _collectionView = collectionView;
    self = [super initWithFrame:CGRectMake(0,0, ([[UIScreen mainScreen] bounds].size.width)*5,  ([[UIScreen mainScreen] bounds].size.height)*5)];
    if(self){
        UIToolbar *tb=[[UIToolbar alloc]initWithFrame:CGRectMake(-([[UIScreen mainScreen]bounds].size.width), -([[UIScreen mainScreen]bounds].size.height),([[UIScreen mainScreen] bounds].size.width)*5,  ([[UIScreen mainScreen] bounds].size.height)*5)];
        _alphaview=tb;
        _alphaview.alpha=0;
        [self addSubview:_alphaview];
        [UIView animateWithDuration:0.6 animations:^{
            _alphaview.alpha=0.98;
        }];
        
        _collectionView.scrollEnabled=NO;
        
        //create buttons
        UIButton *abutton=[[UIButton alloc]initWithFrame:CGRectMake(cell.frame.origin.x-30 ,cell.frame.origin.y-30 , 30, 30)];
        abutton.center=cell.center;
        _profilebutton=abutton;
        UIImage *aimge=[UIImage imageNamed:@"button_p.png"];
        [_profilebutton setImage:aimge forState:UIControlStateNormal];
        [_profilebutton addTarget:self action:@selector(toperson) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *bbutton=[[UIButton alloc]initWithFrame:CGRectMake(cell.frame.origin.x+cell.frame.size.width ,cell.frame.origin.y-30 , 30, 30)];
        bbutton.center=cell.center;
        _buzzbutton=bbutton;
        UIImage *bimge=[UIImage imageNamed:@"button_b.png"];
        [_buzzbutton setImage:bimge forState:UIControlStateNormal];
        [_buzzbutton addTarget:self action:@selector(tobuzz) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *cbutton=[[UIButton alloc]initWithFrame:CGRectMake(cell.frame.origin.x+cell.frame.size.width/2-15 ,cell.frame.origin.y-45 , 30, 30)];
        cbutton.center=cell.center;
        _voicebutton=cbutton;
        UIImage *cimge=[UIImage imageNamed:@"button_v.png"];
        [_voicebutton setImage:cimge forState:UIControlStateNormal];
        [_voicebutton addTarget:self action:@selector(tovoice) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *dbutton=[[UIButton alloc]initWithFrame:CGRectMake(cell.frame.origin.x+cell.frame.size.width/2-15, cell.frame.origin.y+cell.frame.size.height , 30, 30)];
        dbutton.center=cell.center;
        _closebutton=dbutton;
        [_closebutton addTarget:self action:@selector(closemeun) forControlEvents:UIControlEventTouchUpInside];
        UIImage *dimge=[UIImage imageNamed:@"button_x.png"];
        [_closebutton setImage:dimge forState:UIControlStateNormal];
        _personcellview=cell;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closemeun)];
        [self addGestureRecognizer:tap];
        
        [self addSubview:_profilebutton];
        [self addSubview:_buzzbutton];
        [self addSubview:_voicebutton];
        [self addSubview:_closebutton];
        [self addSubview:_personcellview];
        _profilebutton.alpha=0;
        _buzzbutton.alpha=0;
        _voicebutton.alpha=0;
        _closebutton.alpha=0;
        
        //button animation
        [UIView animateWithDuration:0.6 delay:0.2 options:UIViewAnimationOptionCurveEaseIn animations:^
         {
             CGRect nrect1=[_profilebutton frame];
             CGRect nrect2=[_buzzbutton frame];
             CGRect nrect3=[_voicebutton frame];
             CGRect nrect4=[_closebutton frame];
             
             nrect1.origin.x=cell.frame.origin.x-20;
             nrect1.origin.y=cell.frame.origin.y-20;
             nrect2.origin.y=cell.frame.origin.y-35;
             nrect3.origin.x=cell.frame.origin.x+cell.frame.size.width-10;
             nrect3.origin.y=cell.frame.origin.y-20;
             nrect4.origin.y=cell.frame.origin.y+cell.frame.size.height;
             
             [_profilebutton setFrame:nrect1];
             [_buzzbutton setFrame:nrect2];
             [_voicebutton setFrame:nrect3];
             [_closebutton setFrame:nrect4];
             
         } completion:nil];
        
        [UIView animateWithDuration:1.8 delay:0.2 options:UIViewAnimationOptionCurveEaseIn animations:^
         {
             _profilebutton.alpha=1;
             _buzzbutton.alpha=1;
             _voicebutton.alpha=1;
             _closebutton.alpha=1;
             
         } completion:nil];
        
        self.collectionView.scrollEnabled = NO;
    }
    //[UIView commitAnimations];
    
    return self;
}

//block callbcack methods
-(void)toprofilebuttonWithBlock:(profilebuttonBlock)profile
{
    _toprofilebuttonBlock=profile;
}
-(void)tobuzzbuttonWithBlock:(buzzbuttonBlock)buzz;
{
    _tobuzzbuttonBlock=buzz;
}
-(void)tovoicebuttonWithBlock:(voicebuttonBlock)voice
{
    _tovoicebuttonBlock=voice;
}

-(void)toperson
{
    _toprofilebuttonBlock();
}
-(void)tobuzz
{
    _tobuzzbuttonBlock();
}
-(void)tovoice
{
    _tovoicebuttonBlock();
}

//close method
-(void)closemeun
{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect rect1=[_profilebutton frame];
        CGRect rect2=[_buzzbutton frame];
        CGRect rect3=[_voicebutton frame];
        CGRect rect4=[_closebutton frame];
        
        rect1.origin.x=_personcellview.center.x-15;
        rect1.origin.y=_personcellview.center.y-15;
        rect2.origin.x=_personcellview.center.x-15;
        rect2.origin.y=_personcellview.center.y-15;
        rect3.origin.x=_personcellview.center.x-15;
        rect3.origin.y=_personcellview.center.y-15;
        rect4.origin.x=_personcellview.center.x-15;
        rect4.origin.y=_personcellview.center.y-15;
        
        [_profilebutton setFrame:rect1];
        [_buzzbutton setFrame:rect2];
        [_voicebutton setFrame:rect3];
        [_closebutton setFrame:rect4];
    } completion:^(BOOL finished) {
        _collectionView.scrollEnabled = YES;
        [self.superview addSubview:_personcellview];
        [self removeFromSuperview];
        self.tag=0;
    }];
    
    
}

@end