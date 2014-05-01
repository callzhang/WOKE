

#import "EWHexagonFlowLayout.h"
#import "EWUIUtil.h"
#import "EWAppDelegate.h"

#define kCoordinateSystemPolar           @"polar"
#define kCoordinateSystemCartesian       @"cartesian"
#define kLevelCount                      @[@1, @6, @12, @18, @24, @30, @36, @42, @48]
#define kLevelTotal                     @[@0, @1, @7, @19, @37]

@interface EWHexagonFlowLayout ()
{
    NSInteger _itemsPerRow;
    NSInteger _itemTotalCount;
    CGSize _hexagonSize;
    BOOL applyZoomEffect;
    float adjWidth; //the true width of a hexagon, used to calculate coordinates
    NSString *coordinateSystem;
    CGPoint center;
}

@end

@implementation EWHexagonFlowLayout
@synthesize itemsPerRow = _itemsPerRow;
@synthesize itemTotalCount = _itemTotalCount;
@synthesize hexagonSize = _hexagonSize;

#pragma mark - UICollectionViewLayout Subclass hooks

- (void)prepareLayout
{
    [super prepareLayout];
    
    _itemTotalCount = [self.collectionView numberOfItemsInSection:0];
    if (_itemsPerRow == 0) _itemsPerRow = [self getLevel:_itemTotalCount] * 2 - 1;
    //if (_itemsPerRow == 0) _itemsPerRow = 4;
    adjWidth = sqrtf(3)/2 * kCollectionViewCellHeight * CELL_SPACE_RATIO;
    _hexagonSize = CGSizeMake(kCollectionViewCellWidth * CELL_SPACE_RATIO, kCollectionViewCellHeight * CELL_SPACE_RATIO);
    coordinateSystem = kCoordinateSystemPolar;
    [self getCollectionViewCenter];
    
    //precalculate the coordinates
    attributeArray = [[NSMutableArray alloc] initWithCapacity:_itemTotalCount];
    for (unsigned i=0; i<_itemTotalCount; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
        UICollectionViewLayoutAttributes *attribute = [self centerForCellAtIndexPath:path];
        attributeArray[i] = attribute;
    }
    
}

- (void)getCollectionViewCenter{
    UICollectionView *_collectionView = self.collectionView;
    float w = _collectionView.contentSize.width + _collectionView.contentInset.left + _collectionView.contentInset.right;
    float h = _collectionView.contentSize.height + _collectionView.contentInset.top + _collectionView.contentInset.bottom;
    
    float x = w/2 - _collectionView.contentInset.left - rootViewController.view.center.x;
    float y = h/2 - _collectionView.contentInset.top - rootViewController.view.center.y;
    
    center = CGPointMake(x, y);
}

- (NSInteger)getLevel:(NSInteger)x{
    //X is the number of the item, not the index, need to add 1 when passing by index
    NSArray *levelTotal = kLevelTotal;
    unsigned level;
    for (level = 1; level < levelTotal.count; level++) {
        NSInteger total = [(NSNumber *)levelTotal[level-1] integerValue];
        NSInteger total2 = [(NSNumber *)levelTotal[level] integerValue];
        if (total < x && x <= total2) {
            break;
        }
    }
    //NSLog(@"%dth item at level: %d", x, level);
    return level;
}

- (UICollectionViewLayoutAttributes *)centerForCellAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger x = indexPath.row;
    NSInteger col = 0;//x
    NSInteger row = 0;//y
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    NSInteger level0 = [self getLevel: _itemTotalCount];
    NSInteger level = [self getLevel:x +1];
    NSArray *levelTotal = kLevelTotal;
    
    //see: http://www.redblobgames.com/grids/hexagons/
    //“odd-r” horizontal layout
    if (x == 0) {
        row = level0;
        col = level0;
    }else{
        //when level is >1, edge step = level-1
        NSInteger edgeStep = level -1;
        NSInteger steps = x - [(NSNumber *)levelTotal[level-1] integerValue];
        //starting on the right most cell, which is col = 2 * level, row = level
        col = level0 + level - 1;
        row = level0;
        //skip if steps == 0 => first item skipped
        for (unsigned step = 1; step <= steps; step++) {
            //starting with 1, meaning second step
            //direction number
            NSInteger direction = floor((step-1) / edgeStep);//the direction from last one to this one
            switch (direction) {
                case 0:{
                    //south-west
                    if (row%2 == 0) {
                        //even row (Y)
                        col --;
                    }
                    row ++;
                }
                    break;
                    
                case 1:{
                    //west
                    col --;
                }
                    break;
                    
                case 2:{
                    //north-west
                    if (row%2 == 0) {
                        col--;
                    }
                    row--;
                }
                    break;
                    
                case 3:{
                    //north-east
                    if(row%2 != 0){
                        col++;
                    }
                    row--;
                }
                    break;
                case 4:{
                    //east
                    col++;
                }
                    break;
                case 5:{
                    //south east
                    if (row%2!=0) {
                        col++;
                    }
                    row++;
                }
                    break;
                default:
                    break;
            }
        }
        //get col and row
        
    }
    
    
    //col = indexPath.row % _itemsPerRow;
    CGFloat horiOffset = ((row % 2) != 0) ? 0 : adjWidth * 0.5f;
    CGFloat vertOffset = 0;
    
    
    attributes.size = CGSizeMake(kCollectionViewCellWidth, kCollectionViewCellHeight);
    attributes.center = CGPointMake((col * adjWidth) + (0.5f * adjWidth) + horiOffset,
                                    row * 0.75f * _hexagonSize.height + 0.5f * _hexagonSize.height + vertOffset);
    
    NSLog(@"%dth item has index of (%d, %d) and coordinate of (%f, %f)", x, col, row, attributes.center.x, attributes.center.y);
    
    return attributes;
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    
    //NSLog(@"Flow Layout delegate is asking for rect:(%.1f,%.1f,%.1f,%.1f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    //list of containing indexPath
    NSArray *attributes = [self getContainedRect:rect fromAttributesArray:attributeArray];
    
    if (applyZoomEffect) {
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
    }
    

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
    //NSLog(@"New bounds asked for updated layout: (%0f,%0f,%0f,%0f)", newBounds.origin.x, newBounds.origin.y, newBounds.size.width, newBounds.size.height);
    return applyZoomEffect ? YES : NO;
}

//- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context{
//    
//}

- (CGSize)collectionViewContentSize
{
    //NSInteger row = _itemsPerRow == 0?0:_itemTotalCount / _itemsPerRow;

    CGFloat contentWidth = _itemsPerRow * _hexagonSize.width;
    //CGFloat contentHeight = ( (row * 0.75f) * _hexagonSize.height) + (0.5f + _hexagonSize.height);
    CGFloat contentHeight = _itemsPerRow * adjWidth;
    CGSize contentSize = CGSizeMake(contentWidth, contentHeight);
    
    return contentSize;
}

//Asks the delegate for the margins to apply to content in the specified section.
//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
//    NSInteger space = kCollectionViewCellWidth * CELL_SPACE_RATIO;
//    return UIEdgeInsetsMake(space, space, space, space);
//}

//- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity{
//    
//    //possible cell
//    CGRect bounds = self.collectionView.bounds;
//    CGPoint proposedCenter = CGPointMake(proposedContentOffset.x +bounds.size.width/2, proposedContentOffset.y + bounds.size.height/2);
//    //NSLog(@"Proposed center (%f, %f)", proposedCenter.x, proposedCenter.y);
//    CGRect proposedRect = CGRectMake(proposedCenter.x, proposedCenter.y, _hexagonSize.width, _hexagonSize.height);
//    NSArray *possibleCells = [self layoutAttributesForElementsInRect:proposedRect];
//    if (possibleCells.count == 0) {
//        possibleCells = attributeArray;
//    }
//    //compare
//    double minDist = (double)NSIntegerMax;
//    CGPoint newPoint;//the center of the cell with cloest distance
//    for (UICollectionViewLayoutAttributes *attribute in possibleCells) {
//        //get real center
//        CGRect cellFrame = CGRectMake(attribute.frame.origin.x, attribute.frame.origin.y, kCollectionViewCellWidth, kCollectionViewCellHeight);
//        CGPoint center = CGPointMake(CGRectGetMidX(cellFrame), CGRectGetMidY(cellFrame));
//        CGFloat distance = [EWUIUtil distanceOfPoint:proposedCenter toPoint:center];
//        if (distance < minDist) {
//            minDist = distance;
//            newPoint = center;
//            //NSLog(@"Candidate cell with distance of %f from (%f, %f)", distance, newPoint.x, newPoint.y);
//        }
//    }
//    //NSLog(@"Adjusted center to (%f, %f)", newPoint.x, newPoint.y);
//    return CGPointMake(newPoint.x - bounds.size.width/2, newPoint.y - bounds.size.height/2);
//}
@end
