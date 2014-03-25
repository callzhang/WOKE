//
//  PBJHexagonFlowLayout.m
//
//  Created by Patrick Piemonte on 10/30/13.
//  Copyright (c) 2013. All rights reserved.
//

#import "PBJHexagonFlowLayout.h"




@interface PBJHexagonFlowLayout ()
{
    NSInteger _itemsPerRow;
    NSInteger _itemTotalCount;
    CGSize _hexagonSize;
}

@end

@implementation PBJHexagonFlowLayout
@synthesize itemsPerRow = _itemsPerRow;
@synthesize itemTotalCount = _itemTotalCount;
@synthesize hexagonSize = _hexagonSize;

#pragma mark - UICollectionViewLayout Subclass hooks

- (void)prepareLayout
{
    [super prepareLayout];
    
    _itemTotalCount = [self.collectionView numberOfItemsInSection:0];
    if (_itemsPerRow == 0)
        _itemsPerRow = (NSInteger)floorf(sqrt(_itemTotalCount));
    _hexagonSize = CGSizeMake(kCollectionViewCellWidth * CELL_SPACE_RATIO, kCollectionViewCellHeight * CELL_SPACE_RATIO);
    
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *attributes = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0 ; i < _itemTotalCount; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = (NSInteger)( floorf((indexPath.row / _itemsPerRow)) );
    NSInteger col = indexPath.row % _itemsPerRow;

    CGFloat horiOffset = ((row % 2) != 0) ? 0 : _hexagonSize.width * 0.5f;
    CGFloat vertOffset = 0;
    
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.size = _hexagonSize;
    attributes.center = CGPointMake( ( (col * _hexagonSize.width) + (0.5f * _hexagonSize.width) + horiOffset),
                                     ( ( (row * 0.75f) * _hexagonSize.height) + (0.5f * _hexagonSize.height) + vertOffset) );
    return attributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return NO;
}

//- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context{
//    
//}

- (CGSize)collectionViewContentSize
{
    NSInteger row = _itemTotalCount / _itemsPerRow;
    NSInteger column = _itemTotalCount % _itemsPerRow;

    CGFloat contentWidth = (column + 1) * _hexagonSize.width;
    CGFloat contentHeight = ( (row * 0.75f) * _hexagonSize.height) + (0.5f + _hexagonSize.height);
    CGSize contentSize = CGSizeMake(contentWidth, contentHeight);
    return contentSize;
}

@end
