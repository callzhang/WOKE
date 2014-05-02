//
//  EWPopupMenu.m
//  Woke
//
//  Created by Lei on 4/26/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWPopupMenu.h"
#import "EWUIUtil.h"

#define kCallOutBtnSize         70

@interface EWPopupMenu(){
    CGPoint cellCenter;
    EWCollectionPersonCell *cell;
    UIScrollView *collectionView;
    UILabel *name;
}

@end

@implementation EWPopupMenu

-(id)initWithCell:(EWCollectionPersonCell *)c
{
    cell = c;
    collectionView = (UIScrollView *)cell.superview;
    self = [super initWithFrame: collectionView.bounds];
    if (!self) {
        return nil;
    }
    
    //add self
    [collectionView addSubview:self];
    collectionView.scrollEnabled=NO;
    
    
    //move to the cell first
    CGRect frame = cell.frame;
    frame = CGRectInset(cell.frame, -50, -150);
    CGRect intersection = CGRectIntersection(frame, collectionView.bounds);
    float delay = 0.5;
    if (CGSizeEqualToSize(intersection.size, frame.size)) {
        //no need to move
        delay = 0;
    }else{
        [collectionView scrollRectToVisible:frame animated:YES];
    }
    //delay if scrollview moves
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //[collectionView.delegate scrollViewDidScroll:collectionView];
        
        //alpha view
        self.frame = collectionView.bounds;
        _alphaView = [[UIView alloc] initWithFrame: self.bounds];
        _alphaView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _alphaView.alpha = 0;
        [self addSubview:_alphaView];
        
        //cell
        CGRect cellFrame = cell.frame;
        cellFrame.origin.x = cellFrame.origin.x - collectionView.bounds.origin.x;
        cellFrame.origin.y = cellFrame.origin.y - collectionView.bounds.origin.y;
        cellCenter.x = cellFrame.origin.x + cellFrame.size.width/2;
        cellCenter.y = cellFrame.origin.y + cellFrame.size.height/2;
        
        //create buttons
        _profileButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kCallOutBtnSize, kCallOutBtnSize)];
        _profileButton.center = cellCenter;
        UIImage *aimge = [UIImage imageNamed:@"Callout_Profile_Btn"];
        [_profileButton setImage:aimge forState:UIControlStateNormal];
        [_profileButton addTarget:self action:@selector(toPerson) forControlEvents:UIControlEventTouchUpInside];
        
        _buzzButton = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, kCallOutBtnSize, kCallOutBtnSize)];
        _buzzButton.center = cellCenter;
        UIImage *bimge=[UIImage imageNamed:@"Callout_Buzz_Btn"];
        [_buzzButton setImage:bimge forState:UIControlStateNormal];
        [_buzzButton addTarget:self action:@selector(toBuzz) forControlEvents:UIControlEventTouchUpInside];
        
        _voiceButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kCallOutBtnSize, kCallOutBtnSize)];
        _voiceButton.center = cellCenter;
        UIImage *cimge=[UIImage imageNamed:@"Callout_Voice_Message_Btn"];
        [_voiceButton setImage:cimge forState:UIControlStateNormal];
        [_voiceButton addTarget:self action:@selector(toVoice) forControlEvents:UIControlEventTouchUpInside];
        
        _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kCallOutBtnSize, kCallOutBtnSize)];
        _closeButton.center = cellCenter;
        [_closeButton addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
        UIImage *dimge=[UIImage imageNamed:@"Callout_Close_Btn"];
        [_closeButton setImage:dimge forState:UIControlStateNormal];
        
        //name
        name = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kCollectionViewCellWidth, 30)];
        name.center = cellCenter;
        name.text = cell.name;
        NSLog(@"%@", name.text);
        [self addSubview:name];
        name.adjustsFontSizeToFitWidth = YES;
        name.textColor = [UIColor whiteColor];
        name.font = [UIFont systemFontOfSize:12];
        name.textAlignment = NSTextAlignmentCenter;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMenu)];
        [self addGestureRecognizer:tap];
        
        [self addSubview:_profileButton];
        [self addSubview:_buzzButton];
        [self addSubview:_voiceButton];
        [self addSubview:_closeButton];
        _profileButton.alpha=0;
        _buzzButton.alpha=0;
        _voiceButton.alpha=0;
        _closeButton.alpha=0;
        name.alpha = 0;
        
        
        //bring cell to the top
        [collectionView bringSubviewToFront:cell];
        
        
        [UIView transitionWithView:cell
                          duration:0.4
                           options:(UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionAllowAnimatedContent)
                        animations:
         ^{
             //CGAffineTransform flip = CGAffineTransformMakeRotation(M_PI);
             CGAffineTransform scale = CGAffineTransformMakeScale(1.25, 1.25);
             //cell.white.alpha = 0.8;
             //CGAffineTransform trans = CGAffineTransformConcat(flip, scale);
             cell.transform = scale;
             
             cell.white.alpha = 0.8;
             cell.distance.alpha = 1;
             cell.time.alpha = 1;
             cell.initial.alpha = 0;
             [EWUIUtil applyShadow:cell];
             
             //location
             CGRect nrect1=[_profileButton frame];
             CGRect nrect2=[_buzzButton frame];
             CGRect nrect3=[_voiceButton frame];
             CGRect nrect4=[_closeButton frame];
             CGRect nameRect = name.frame;
             
             nrect1.origin.x -= kCollectionViewCellWidth / 2 + 15;
             nrect1.origin.y -= kCollectionViewCellHeight / 2 + 15;
             nrect2.origin.y -= kCollectionViewCellHeight / 2 + 40;
             nrect3.origin.x += kCollectionViewCellWidth / 2 + 15;
             nrect3.origin.y -= kCollectionViewCellHeight / 2 + 15;
             nameRect.origin.y += kCollectionViewCellHeight / 2 + 20;
             nrect4.origin.y = nameRect.origin.y;
             
             _alphaView.alpha = 1;
             _profileButton.alpha=1;
             _buzzButton.alpha=1;
             _voiceButton.alpha=1;
             _closeButton.alpha=1;
             name.alpha = 1;
             [EWUIUtil applyShadow:name];
             
             [_profileButton setFrame:nrect1];
             [_buzzButton setFrame:nrect2];
             [_voiceButton setFrame:nrect3];
             [_closeButton setFrame:nrect4];
             name.frame = nameRect;
             
         } completion:^(BOOL finished){
             
         }];
    });
    
    collectionView.scrollEnabled = NO;

    return self;
}



- (void)toPerson
{
    self.toProfileButtonBlock();
}
- (void)toBuzz
{
    self.toBuzzButtonBlock();
}
- (void)toVoice
{
    self.toVoiceButtonBlock();
}

//close method
- (void)closeMenu
{
    
    //[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    
    [UIView transitionWithView:cell
                      duration:0.4
                       options:(UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionAllowAnimatedContent)
                    animations:
     ^{
         cell.white.alpha = 0;
         cell.distance.alpha = 0;
         cell.time.alpha = 0;
         if ([cell.initial.text isEqualToString:@"YOU"]) {
             cell.initial.alpha = 1;
         }
     
        CGAffineTransform scale = CGAffineTransformMakeScale(1.0, 1.0);
        cell.transform = scale;
        cell.white.alpha = 0;
        //cell.initial.alpha = 0;
        cell.layer.shadowRadius = 0;
        
        _profileButton.center = cellCenter;
        _buzzButton.center = cellCenter;
        _voiceButton.center = cellCenter;
        _closeButton.center = cellCenter;
        name.center = cellCenter;
        
        _profileButton.alpha=0;
        _buzzButton.alpha=0;
        _voiceButton.alpha=0;
        _closeButton.alpha=0;
        _alphaView.alpha=0;
        name.alpha = 0;
        
    } completion:^(BOOL finished) {
        collectionView.scrollEnabled = YES;
        [self removeFromSuperview];
        
        
    }];
}

+ (void)flipCell:(EWCollectionPersonCell *)cell completion:(void (^)(void))block{
    if (cell.white.alpha == 0) {
        //initial state
        [UIView transitionWithView:cell
                          duration:0.4
                           options:(UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionAllowAnimatedContent)
                        animations:^{
            cell.white.alpha = 0.8;
            cell.distance.alpha = 1;
            cell.time.alpha = 1;
            cell.initial.alpha = 0;
        } completion:^(BOOL finished) {
            if (block) {
                block();
            }
        }];
        [UIView animateWithDuration:0.4 animations:^{
            
        }];
    }else{
        [UIView transitionWithView:cell
                          duration:0.4
                           options:(UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionAllowAnimatedContent)
                        animations:
         ^{
            cell.white.alpha = 0;
            cell.distance.alpha = 0;
            cell.time.alpha = 0;
            if ([cell.initial.text isEqualToString:@"YOU"]) {
                cell.initial.alpha = 1;
            }
        } completion:^(BOOL finished) {
            if (block) {
                block();
            }
        }];
    }
}

@end