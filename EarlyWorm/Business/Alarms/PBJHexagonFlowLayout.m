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
    if (_itemsPerRow == 0) _itemsPerRow = (NSInteger)floorf(sqrt(_itemTotalCount));
    //if (_itemsPerRow == 0) _itemsPerRow = 4;
    _hexagonSize = CGSizeMake(kCollectionViewCellWidth * CELL_SPACE_RATIO, kCollectionViewCellHeight * CELL_SPACE_RATIO);
    
    //precalculate the coordinates
    attributeArray = [[NSMutableArray alloc] initWithCapacity:_itemTotalCount];
    for (unsigned i=0; i<_itemTotalCount; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
        UICollectionViewLayoutAttributes *attribute = [self centerForCellAtIndexPath:path];
        attributeArray[i] = attribute;
    }
    
}

- (UICollectionViewLayoutAttributes *)centerForCellAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger row = (NSInteger)( floorf((indexPath.row / _itemsPerRow)) );
    NSInteger col = indexPath.row % _itemsPerRow;
    CGFloat horiOffset = ((row % 2) != 0) ? 0 : _hexagonSize.width * 0.5f;
    CGFloat vertOffset = 0;
    
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.size = _hexagonSize;
    attributes.center = CGPointMake((col * _hexagonSize.width) + (0.5f * _hexagonSize.width) + horiOffset,
                                    row * 0.75f * _hexagonSize.height + 0.5f * _hexagonSize.height + vertOffset);
    
    return attributes;
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    
    NSLog(@"Flow Layout delegate is asking for rect:(%.1f,%.1f,%.1f,%.1f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    //list of containing indexPath
    NSArray *attributes = [self getContainedRect:rect fromAttributesArray:attributeArray];

    return attributes;
}

- (NSArray *)getContainedRect:(CGRect)rect fromAttributesArray:(NSArray *)attributesArray{
    NSMutableArray *containedRects = [[NSMutableArray alloc] init];
    for (UICollectionViewLayoutAttributes *att in attributesArray) {
        CGRect frame = att.frame;
        BOOL contain = CGRectIntersectsRect(rect, frame);
        if (contain) {
            [containedRects addObject:att];
        }
    }
    return containedRects;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return attributeArray[indexPath.row];
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
    NSInteger row = _itemsPerRow == 0?0:_itemTotalCount / _itemsPerRow;

    CGFloat contentWidth = _itemsPerRow * _hexagonSize.width;
    CGFloat contentHeight = ( (row * 0.75f) * _hexagonSize.height) + (0.5f + _hexagonSize.height);
    CGSize contentSize = CGSizeMake(contentWidth, contentHeight);
    return contentSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    NSInteger space = kCollectionViewCellWidth * CELL_SPACE_RATIO;
    return UIEdgeInsetsMake(space, space, space, space);
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity{
    double minDist = (double)NSIntegerMax;
    CGPoint newPoint;
    for (UICollectionViewLayoutAttributes *att in attributeArray) {
        CGPoint center = att.center;
        double distanceSq = pow((center.x + proposedContentOffset.x), 2) + pow((center.y + proposedContentOffset.y),2);
        if (distanceSq < minDist) {
            minDist = distanceSq;
            newPoint = center;
        }
    }
    CGPoint resultPoint = CGPointMake(-1*newPoint.x, -1*newPoint.y);
    
    NSLog(@"Changed from %@ to %@", proposedContentOffset, resultPoint);
    return resultPoint;
}
@end
