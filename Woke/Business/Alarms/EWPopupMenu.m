//
//  EWPopupMenu.m
//  Woke
//
//  Created by Lei on 4/26/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWPopupMenu.h"

@interface EWPopupMenu(){
    CGRect cellOriginalFrame;
    CGRect cellFrame;
    profilebuttonBlock _toprofilebuttonBlock;
    buzzbuttonBlock _tobuzzbuttonBlock;
    voicebuttonBlock _tovoicebuttonBlock;
}
@property(weak, nonatomic) EWCollectionPersonCell *personcellview;
@property(nonatomic,retain) UICollectionView *collectionView;
@end

@implementation EWPopupMenu

-(id)initWithCollectionView:(UICollectionView *)collectionView
               initWithCell:(EWCollectionPersonCell *)cell
{
    self.tag=1;
    _collectionView = collectionView;
    CGRect frame = CGRectMake(0, 0, collectionView.frame.size.width,  collectionView.frame.size.height);
    self = [super initWithFrame:frame];
    if(self){
        
        //alpha view
        UIToolbar *tb=[[UIToolbar alloc]initWithFrame: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        _alphaview=tb;
        _alphaview.alpha=0;
        [self addSubview:_alphaview];
        [UIView animateWithDuration:0.6 animations:^{
            _alphaview.alpha=0.98;
        }];
        
        _collectionView.scrollEnabled=NO;
        
        
        //cell
        cellFrame = cell.frame;
        cellOriginalFrame = cell.frame;
        _personcellview = cell;
        cellFrame.origin.x = cellFrame.origin.x - collectionView.bounds.origin.x;
        cellFrame.origin.y = cellFrame.origin.y - collectionView.bounds.origin.y;
        _personcellview.frame = cellFrame;
        
        //create buttons
        _profilebutton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
        _profilebutton.center=cell.center;
        UIImage *aimge = [UIImage imageNamed:@"button_p.png"];
        [_profilebutton setImage:aimge forState:UIControlStateNormal];
        [_profilebutton addTarget:self action:@selector(toperson) forControlEvents:UIControlEventTouchUpInside];
        
        _buzzbutton = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 30, 30)];
        _buzzbutton.center=cell.center;
        UIImage *bimge=[UIImage imageNamed:@"button_b.png"];
        [_buzzbutton setImage:bimge forState:UIControlStateNormal];
        [_buzzbutton addTarget:self action:@selector(tobuzz) forControlEvents:UIControlEventTouchUpInside];
        
        _voicebutton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        _voicebutton.center=cell.center;
        UIImage *cimge=[UIImage imageNamed:@"button_v.png"];
        [_voicebutton setImage:cimge forState:UIControlStateNormal];
        [_voicebutton addTarget:self action:@selector(tovoice) forControlEvents:UIControlEventTouchUpInside];
        
        _closebutton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
        _closebutton.center=cell.center;
        [_closebutton addTarget:self action:@selector(closemeun) forControlEvents:UIControlEventTouchUpInside];
        UIImage *dimge=[UIImage imageNamed:@"button_x.png"];
        [_closebutton setImage:dimge forState:UIControlStateNormal];
        
        
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
        [UIView animateWithDuration:0.6 delay:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^
         {
             CGRect nrect1=[_profilebutton frame];
             CGRect nrect2=[_buzzbutton frame];
             CGRect nrect3=[_voicebutton frame];
             CGRect nrect4=[_closebutton frame];
             
             nrect1.origin.x -= 55;
             nrect1.origin.y -= 55;
             nrect2.origin.y -= 70;
             nrect3.origin.x += 55;
             nrect3.origin.y -= 55;
             nrect4.origin.y += 70;
             
             _profilebutton.alpha=1;
             _buzzbutton.alpha=1;
             _voicebutton.alpha=1;
             _closebutton.alpha=1;
             
             [_profilebutton setFrame:nrect1];
             [_buzzbutton setFrame:nrect2];
             [_voicebutton setFrame:nrect3];
             [_closebutton setFrame:nrect4];
             
         } completion:nil];
        
//        [UIView animateWithDuration:1.8 delay:0.2 options:UIViewAnimationOptionCurveEaseIn animations:^
//         {
//             _profilebutton.alpha=1;
//             _buzzbutton.alpha=1;
//             _voicebutton.alpha=1;
//             _closebutton.alpha=1;
//             
//         } completion:nil];
        
        self.collectionView.scrollEnabled = NO;
    }
    //[UIView commitAnimations];
    
    return self;
}

//block callbcack methods
-(void)toprofilebuttonWithBlock:(profilebuttonBlock)profile
{
    _toprofilebuttonBlock = profile;
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
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [_profilebutton setFrame:cellFrame];
        [_buzzbutton setFrame:cellFrame];
        [_voicebutton setFrame:cellFrame];
        [_closebutton setFrame:cellFrame];
        
        _profilebutton.alpha=0;
        _buzzbutton.alpha=0;
        _voicebutton.alpha=0;
        _closebutton.alpha=0;
        _alphaview.alpha=0;
        
    } completion:^(BOOL finished) {
        _collectionView.scrollEnabled = YES;
        self.personcellview.frame = cellOriginalFrame;
        [self.collectionView addSubview:_personcellview];
        [self removeFromSuperview];
        self.tag=0;
    }];
    
    
}

@end