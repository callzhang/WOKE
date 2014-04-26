//
//  EWPopupMenu.m
//  Woke
//
//  Created by Lei on 4/26/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWPopupMenu.h"

@implementation EWPopupMenu
-(id)initWithCollectionView:(UICollectionView *)collectionView
               initWithCell:(EWCollectionPersonCell *)cell
//- (id)initWithFrame:(CGRect)frame
//       initWithCell:(EWCollectionPersonCell*)cell
{
    self.tag=1;
    _collectionView = collectionView;
    self = [super initWithFrame:CGRectMake(0, 0, ([[UIScreen mainScreen] bounds].size.width)*4,  ([[UIScreen mainScreen] bounds].size.height)*4)];
    if(self){
        //        UINavigationBar *nb=[[UINavigationBar alloc] initWithFrame:CGRectMake(-[[UIScreen mainScreen] bounds].size.width, -[[UIScreen mainScreen] bounds].size.height,([[UIScreen mainScreen] bounds].size.width)*4, ([[UIScreen mainScreen] bounds].size.height)*4)];
        //    UINavigationBar *nb=[[UINavigationBar alloc] initWithFrame:collectionView.frame];
        //        nb.backgroundColor=[UIColor whiteColor];
        //        nb.alpha=0.7;
        //        _alphaview=nb;
        
        //    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(-[[UIScreen mainScreen] bounds].size.width, -[[UIScreen mainScreen] bounds].size.height,([[UIScreen mainScreen] bounds].size.width)*5, ([[UIScreen mainScreen] bounds].size.height)*5)];
        //    view.backgroundColor=[UIColor whiteColor];
        //    view.alpha=0.7;
        //    _alphaview=view;
        
        //    UITableView *tbv=[[UITableView alloc] initWithFrame:CGRectMake(0, 0, ([[UIScreen mainScreen] bounds].size.width)*4, ([[UIScreen mainScreen] bounds].size.height)*4)];
        //        tbv.backgroundColor=[UIColor whiteColor];
        //        tbv.scrollEnabled=NO;
        //        tbv.alpha=0.78;
        //        _alphaview=tbv;
        
        UIToolbar *tb=[[UIToolbar alloc]initWithFrame:CGRectMake(-([[UIScreen mainScreen]bounds].size.width), -([[UIScreen mainScreen]bounds].size.height),([[UIScreen mainScreen] bounds].size.width)*5,  ([[UIScreen mainScreen] bounds].size.height)*5)];
        _alphaview=tb;
        _alphaview.alpha=0;
        //        [UIView beginAnimations:nil context:NULL];
        //        [UIView setAnimationDuration:1];
        //        [_alphaview setAlpha:0.0];
        //        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.8];
        [_alphaview setAlpha:0.98];
        [UIView commitAnimations];
        
        
        _collectionView.scrollEnabled=NO;
        
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
        //
        //
        //    int index=[self.superview.subviews indexOfObject:cell];
        //    NSLog(@"index1:%i",index);
        _personcellview=cell;
        //    int index2=[self.superview.subviews indexOfObject:cell];
        //    NSLog(@"index2:%i",index2);
        
        
        
        //    UIImage* newimage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect()];
        
        //    UIImageView *imageview=[[UIImageView alloc]initWithFrame:cell.frame];
        //    [imageview addSubview:cell.contentView];
        //    [imageview addSubview:cell.maskView];imageview.image=cell.profilePic.image;
        //    [imageview addSubview:cell.maskView];
        //    personcell.profilePic.image =imageview.image;
        //  _personcellview=personcell;
        
        UIButton *button=[[UIButton alloc]initWithFrame:CGRectMake(-([[UIScreen mainScreen]bounds].size.width), -([[UIScreen mainScreen]bounds].size.height),([[UIScreen mainScreen] bounds].size.width)*5,  ([[UIScreen mainScreen] bounds].size.height)*5)];
        [button addTarget:self action:@selector(closemeun) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_alphaview];
        [self addSubview:button];
        [self addSubview:_profilebutton];
        [self addSubview:_buzzbutton];
        [self addSubview:_voicebutton];
        [self addSubview:_closebutton];
        //  [self addSubview:collectionview];
        [self addSubview:_personcellview];
        _profilebutton.alpha=0;
        _buzzbutton.alpha=0;
        _voicebutton.alpha=0;
        _closebutton.alpha=0;
        
        
        
        //    [self.superview bringSubviewToFront:_closebutton];
        //        int index3=[self.superview.subviews indexOfObject:cell];
        //        NSLog(@"index3:%i",index3);
        
        //    CGContextRef context = UIGraphicsGetCurrentContext();
        //    [UIView beginAnimations:nil context:context];
        //    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView animateWithDuration:0.6 delay:0.2 options:UIViewAnimationOptionCurveEaseIn animations:^
         {
             CGRect rect1=[_profilebutton frame];
             CGRect rect2=[_buzzbutton frame];
             CGRect rect3=[_voicebutton frame];
             CGRect rect4=[_closebutton frame];
             
             rect1.origin.x=cell.frame.origin.x-30;
             rect1.origin.y=cell.frame.origin.y-30;
             rect2.origin.y=cell.frame.origin.y-45;
             rect3.origin.x=cell.frame.origin.x+cell.frame.size.width+5;
             rect3.origin.y=cell.frame.origin.y-30;
             rect4.origin.y=cell.frame.origin.y+cell.frame.size.height+10;
             
             [_profilebutton setFrame:rect1];
             [_buzzbutton setFrame:rect2];
             [_voicebutton setFrame:rect3];
             [_closebutton setFrame:rect4];
             
             
         } completion:^(BOOL finished)
         {
             [UIView animateWithDuration:0.15 delay:0.2 options:UIViewAnimationOptionCurveEaseIn animations:^
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
             
         }
         ];
        
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




/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */
-(void)toperson
{
    [self.delegate buttontoperson];
}
-(void)tobuzz
{
    [self.delegate buttontobuzz];
}
-(void)tovoice
{
    [self.delegate buttontovoice];
}
-(void)closemeun
{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.3];//动画时间长度，单位秒，浮点数
    
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
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(stop)];
    [UIView commitAnimations];
    [self.superview addSubview:_personcellview];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [_alphaview setAlpha:0];
    [UIView commitAnimations];
    
    
    
    
    
    
    
    //    [UIView beginAnimations:@"Curl" context:nil];
    //    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    //    [UIView setAnimationDuration:0.5];
    //    CGRect rect1=[_profilebutton frame];
    //    CGRect rect2=[_buzzbutton frame];
    //    CGRect rect3=[_voicebutton frame];
    //    CGRect rect4=[_closebutton frame];
    //
    //    rect1.origin.x=_personcellview.center.x-15;
    //    rect1.origin.y=_personcellview.center.y-15;
    //    rect2.origin.x=_personcellview.center.x-15;
    //    rect2.origin.y=_personcellview.center.y-15;
    //    rect3.origin.x=_personcellview.center.x-15;
    //    rect3.origin.y=_personcellview.center.y-15;
    //    rect4.origin.x=_personcellview.center.x-15;
    //    rect4.origin.y=_personcellview.center.y-15;
    //
    //    [_profilebutton setFrame:rect1];
    //    [_buzzbutton setFrame:rect2];
    //    [_voicebutton setFrame:rect3];
    //    [_closebutton setFrame:rect4];
    //
    //    [UIView setAnimationDidStopSelector:@selector(stop)];
    //    [UIView commitAnimations];
    //    _alphaview=nil;
    //    _profilebutton=nil;
    //    _buzzbutton=nil;
    //    _voicebutton=nil;
    //    _closebutton=nil;
    
}
-(void)stop
{
    _collectionView.scrollEnabled = YES;
    [self.superview addSubview:_personcellview];
    [self removeFromSuperview];
    self.tag=0;
    
}
//-(UIImage*)saveImageWithCell:(EWCollectionPersonCell*)cell
//{
//    UIGraphicsBeginImageContext(CGSizeMake(cell.view.bounds.size.width, cell.view.bounds.size.height - 20));
//    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
//    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return viewImage;
//}
//-(int)getSubviewIndex
//
//{
//
//    return [self.superview.subviews indexOfObject:self];
//    
//}
@end