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
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        //mask
        [self applyHexagonMask];
    }
    return self;
}

- (void)applyHexagonMask{
    [EWUIUtil applyHexagonMaskForView:self.contentView];
    //[EWUIUtil applyHexagonSoftMaskForView:self.contentView];
}

-(NSString *)timeAndDistance
{
    if ([_time.text isEqualToString:@""]||[_distance.text isEqualToString:@""]) {
        if ([_time.text  isEqualToString:@""]&&[_distance.text isEqualToString:@""]) {
            _timeAndDistance = @"";
        }
        else
        {
            _timeAndDistance = [_time.text stringByAppendingString:_distance.text];
        }
    }
    else
    {
       _timeAndDistance = [[_time.text stringByAppendingString:@" . "] stringByAppendingString:_distance.text];
    }
    
    
    
        
    
    
    return _timeAndDistance;
}


@end
