
//
//  PBJHexagonFlowLayout.m
//
//  Created by Patrick Piemonte on 10/30/13.
//  Copyright (c) 2013. All rights reserved.
//

#import "PBJHexagonFlowLayout.h"
#import "EWUIUtil.h"



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

//Tells the layout object to update the current layout.
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

//get coordinate for cell at indexpath
- (UICollectionViewLayoutAttributes *)centerForCellAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger row = (NSInteger)( floorf((indexPath.row / _itemsPerRow)) );
    NSInteger col = indexPath.row % _itemsPerRow;
    CGFloat horiOffset = ((row % 2) != 0) ? 0 : _hexagonSize.width * 0.5f;
    CGFloat vertOffset = 0;
    
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.size = CGSizeMake(kCollectionViewCellWidth, kCollectionViewCellHeight);
    attributes.center = CGPointMake((col * _hexagonSize.width) + (0.5f * _hexagonSize.width) + horiOffset,
                                    row * 0.75f * _hexagonSize.height + 0.5f * _hexagonSize.height + vertOffset);
    
    return attributes;
}

//Returns the layout attributes for all of the cells and views in the specified rectangle.
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    
    //NSLog(@"Flow Layout delegate is asking for rect:(%.1f,%.1f,%.1f,%.1f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    //list of containing indexPath
    NSArray *attributes = [self getContainedRect:rect fromAttributesArray:attributeArray];
    
    //apply zoom
    CGRect bounds = self.collectionView.bounds;
    //bounds.origin.x += self.collectionView.contentInset.left;
    //bounds.origin.y += self.collectionView.contentInset.top;
    bounds.origin.y -= self.collectionView.frame.origin.y;//compensate the frame origin
    //only update cells in the screen
    NSArray *attributesNeedZoom = [self getContainedRect:bounds fromAttributesArray:attributeArray];
    
    CGPoint midBounds = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    for (UICollectionViewLayoutAttributes *attribute in attributesNeedZoom) {
        if (CGRectIntersectsRect(attribute.frame, bounds)) {
            //get real center
            CGRect cellFrame = CGRectMake(attribute.frame.origin.x, attribute.frame.origin.y, kCollectionViewCellWidth, kCollectionViewCellHeight);
            CGPoint cellCenter = CGPointMake(CGRectGetMidX(cellFrame), CGRectGetMidY(cellFrame));
            //calculate distance
            CGFloat distance = [EWUIUtil distanceOfPoint:midBounds toPoint:cellCenter];
            if (distance < _hexagonSize.width) {
                CGFloat normDistance = distance / _hexagonSize.width;
                CGFloat zoom = 1 + pow((1-normDistance),2)/4 ;
                attribute.transform3D = CATransform3DMakeScale(zoom, zoom, 1.0);
                //attribute.zIndex = round(zoom);
            }
        }
    }

    return attributes;
}


//判断是与矩阵重叠
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

//Returns the layout attributes for the item at the specified index path.
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return attributeArray[indexPath.row];
}


//Asks the layout object if the new bounds require a layout update.
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    //NSLog(@"New bounds asked for updated layout: (%0f,%0f,%0f,%0f)", newBounds.origin.x, newBounds.origin.y, newBounds.size.width, newBounds.size.height);
    return YES;
}

//- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context{
//    
//}

//Returns the width and height of the collection view’s contents.
- (CGSize)collectionViewContentSize
{
    NSInteger row = _itemsPerRow == 0?0:_itemTotalCount / _itemsPerRow;

    CGFloat contentWidth = _itemsPerRow * _hexagonSize.width;
    CGFloat contentHeight = ( (row * 0.75f) * _hexagonSize.height) + (0.5f + _hexagonSize.height);
    CGSize contentSize = CGSizeMake(contentWidth, contentHeight);
    return contentSize;
}

//Asks the delegate for the margins to apply to content in the specified section.
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    NSInteger space = kCollectionViewCellWidth * CELL_SPACE_RATIO;
    return UIEdgeInsetsMake(space, space, space, space);
}


//Returns the point at which to stop scrolling.
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity{
    
    //possible cell
    CGRect bounds = self.collectionView.bounds;
    CGPoint proposedCenter = CGPointMake(proposedContentOffset.x +bounds.size.width/2, proposedContentOffset.y + bounds.size.height/2);
    //NSLog(@"Proposed center (%f, %f)", proposedCenter.x, proposedCenter.y);
    CGRect proposedRect = CGRectMake(proposedCenter.x, proposedCenter.y, _hexagonSize.width, _hexagonSize.height);
    NSArray *possibleCells = [self layoutAttributesForElementsInRect:proposedRect];
    if (possibleCells.count == 0) {
        possibleCells = attributeArray;
    }
    //compare
    double minDist = (double)NSIntegerMax;
    CGPoint newPoint;//the center of the cell with cloest distance
    for (UICollectionViewLayoutAttributes *attribute in possibleCells) {
        //get real center
        CGRect cellFrame = CGRectMake(attribute.frame.origin.x, attribute.frame.origin.y, kCollectionViewCellWidth, kCollectionViewCellHeight);
        CGPoint center = CGPointMake(CGRectGetMidX(cellFrame), CGRectGetMidY(cellFrame));
        CGFloat distance = [EWUIUtil distanceOfPoint:proposedCenter toPoint:center];
        if (distance < minDist) {
            minDist = distance;
            newPoint = center;
            //NSLog(@"Candidate cell with distance of %f from (%f, %f)", distance, newPoint.x, newPoint.y);
        }
    }
    //NSLog(@"Adjusted center to (%f, %f)", newPoint.x, newPoint.y);
    return CGPointMake(newPoint.x - bounds.size.width/2, newPoint.y - bounds.size.height/2);
}
@end
