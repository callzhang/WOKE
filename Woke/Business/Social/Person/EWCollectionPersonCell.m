//
//  EWCollectionPersonCell.m
//  EarlyWorm
//
//  Created by Lei on 3/2/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWCollectionPersonCell.h"
#import "EWUIUtil.h"

@implementation EWCollectionPersonCell
@synthesize profilePic;
@synthesize name;
@synthesize selectionView;

//only called when registing class
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        
        //mask
        [self applyHexagonMask];
        
        
        //boarder
//        UIImageView *boarderView = [[UIImageView alloc] initWithFrame:profilePic.frame];
//        UIGraphicsBeginImageContext(boarderView.frame.size);
//        [boarderView.image drawInRect:boarderView.frame];
//        [[UIColor colorWithWhite:1.0 alpha:0.8] setStroke];
//        UIBezierPath *hexagonPath = [self getHexagonPath];
//        hexagonPath.lineWidth = 4.0;
//        [hexagonPath stroke];
//        boarderView.image = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();

        
    }
    return self;
}

- (void)applyHexagonMask{
    [EWUIUtil applyHexagonMaskForView:self.contentView];
}




@end
