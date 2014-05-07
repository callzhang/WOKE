

#import "EWHexagonFlowLayout.h"
#import "EWUIUtil.h"
#import "EWAppDelegate.h"

#define kCoordinateSystemPolar              @"polar"
#define kCoordinateSystemCartesian          @"cartesian"
#define kLevelCount                         @[@1, @6, @12, @18, @24, @30, @36, @42, @48]
#define kLevelTotal                         @[@0, @1, @7, @19, @37, @61, @91]
#define kDynamic                            NO
#define kZoomEffect                         NO

@interface EWHexagonFlowLayout ()
{
    NSInteger _itemsPerRow;
    NSInteger _itemTotalCount;
    CGSize _hexagonSize;
    float adjWidth; //the true width of a hexagon, used to calculate coordinates
    CGPoint center;
    CGFloat latestDeltaX;
    CGFloat latestDeltaY;
}
@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic, strong) NSMutableSet *visibleIndexPathsSet;
@end

@implementation EWHexagonFlowLayout
@synthesize itemsPerRow = _itemsPerRow;
@synthesize itemTotalCount = _itemTotalCount;
@synthesize hexagonSize = _hexagonSize;

#pragma mark - UICollectionViewLayout Subclass hooks


- (void)prepareLayout
{
    [super prepareLayout];
    
    //cell size
    adjWidth = 140;
    _hexagonSize = CGSizeMake(kCollectionViewCellWidth * CELL_SPACE_RATIO, kCollectionViewCellHeight * CELL_SPACE_RATIO);
    self.itemSize = CGSizeMake(_hexagonSize.width, _hexagonSize.height);
    
    
    //get itemPerRow
    _itemTotalCount = [self.collectionView numberOfItemsInSection:0];
    if (_itemsPerRow == 0) _itemsPerRow = [self getLevel:_itemTotalCount] * 2 - 1;
    
    //coordinate system, currently do not use polar system
    //coordinateSystem = kCoordinateSystemPolar;
    //[self getCollectionViewCenter];
    
    //pre-calculate the coordinates and save to attribute array
    if (!attributeArray) {
        attributeArray = [[NSMutableArray alloc] initWithCapacity:_itemTotalCount];
        for (unsigned i=0; i<_itemTotalCount; i++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            UICollectionViewLayoutAttributes *attribute = [self centerForCellAtIndexPath:path];
            attributeArray[i] = attribute;
        }
    }
    
    if (kDynamic) {
        // ====== Dynamic Animator =======
        
        //init dynamic animator
        if (!self.dynamicAnimator) {
            self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];
        }
        if (!self.visibleIndexPathsSet) {
            self.visibleIndexPathsSet = [NSMutableSet set];
        }
        
        // Need to expand our actual visible rect slightly to avoid flickering.
        CGRect visibleRect = CGRectInset((CGRect){.origin = self.collectionView.bounds.origin, .size = self.collectionView.frame.size}, -100, -100);
        
        NSArray *itemsInVisibleRectArray = [self layoutAttributesForElementsInRect:visibleRect];
        
        NSSet *itemsIndexPathsInVisibleRectSet = [NSSet setWithArray:[itemsInVisibleRectArray valueForKey:@"indexPath"]];
        
        // Step 1: Remove any behaviours that are no longer visible.
        NSArray *noLongerVisibleBehaviours = [self.dynamicAnimator.behaviors filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIAttachmentBehavior *behaviour, NSDictionary *bindings) {
            BOOL currentlyVisible = [itemsIndexPathsInVisibleRectSet member:[[[behaviour items] firstObject] indexPath]] != nil;
            return !currentlyVisible;
        }]];
        
        [noLongerVisibleBehaviours enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
            [self.dynamicAnimator removeBehavior:obj];
            [self.visibleIndexPathsSet removeObject:[[[obj items] firstObject] indexPath]];
        }];
        
        // Step 2: Add any newly visible behaviours.
        // A "newly visible" item is one that is in the itemsInVisibleRect(Set|Array) but not in the visibleIndexPathsSet
        NSArray *newlyVisibleItems = [itemsInVisibleRectArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *item, NSDictionary *bindings) {
            BOOL currentlyVisible = [self.visibleIndexPathsSet member:item.indexPath] != nil;
            return !currentlyVisible;
        }]];
        
        
        // Step 3. Modify center location
        CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];
        
        [newlyVisibleItems enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *item, NSUInteger idx, BOOL *stop) {
            CGPoint centerOfCell = item.center;
            UIAttachmentBehavior *springBehaviour = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:centerOfCell];
            
            springBehaviour.length = 0.0f;
            springBehaviour.damping = 0.8f;
            springBehaviour.frequency = 1.0f;
            
            // If our touchLocation is not (0,0), we'll need to adjust our item's center "in flight"
            if (!CGPointEqualToPoint(CGPointZero, touchLocation)) {
                CGFloat yDistanceFromTouch = fabsf(touchLocation.y - springBehaviour.anchorPoint.y);
                CGFloat xDistanceFromTouch = fabsf(touchLocation.x - springBehaviour.anchorPoint.x);
                CGFloat scrollResistance = (yDistanceFromTouch + xDistanceFromTouch) / 1500.0f;
                
                
                centerOfCell.y += latestDeltaY * scrollResistance;
                centerOfCell.x += latestDeltaX * scrollResistance;
                item.center = centerOfCell;
            }
            
            [self.dynamicAnimator addBehavior:springBehaviour];
            [self.visibleIndexPathsSet addObject:item.indexPath];
        }];
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
    CGFloat horiOffset = ((row % 2) == 0) ? 0 : adjWidth * 0.5f;
    CGFloat vertOffset = 0;
    
    
    attributes.size = CGSizeMake(kCollectionViewCellWidth, kCollectionViewCellHeight);
    attributes.center = CGPointMake((col * adjWidth) + horiOffset,
                                    row * 0.75f * _hexagonSize.height + vertOffset);
    
    //NSLog(@"%dth item has index of (%d, %d) and coordinate of (%f, %f)", x, col, row, attributes.center.x, attributes.center.y);
    
    return attributes;
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    
    //list of containing indexPath
    NSArray *attributes = [self getContainedRect:rect fromAttributesArray:attributeArray];
    
    if (kZoomEffect) {
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
    rect = CGRectInset(rect, -100, -100);
    NSMutableArray *containedAttibutes = [[NSMutableArray alloc] init];
    for (UICollectionViewLayoutAttributes *att in attributesArray) {
        CGRect frame = att.frame;
        BOOL contain = CGRectIntersectsRect(rect, frame);
        if (contain) {
            [containedAttibutes addObject:att];
        }
    }
    return containedAttibutes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return attributeArray[indexPath.row];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    if (kDynamic) {
        CGFloat deltaX = newBounds.origin.x - self.collectionView.bounds.origin.x;
        CGFloat deltaY = newBounds.origin.y - self.collectionView.bounds.origin.y;
        latestDeltaX = deltaX;
        latestDeltaY = deltaY;
        
        CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];
        
        [self.dynamicAnimator.behaviors enumerateObjectsUsingBlock:^(UIAttachmentBehavior *springBehaviour, NSUInteger idx, BOOL *stop) {
            CGFloat yDistanceFromTouch = fabsf(touchLocation.y - springBehaviour.anchorPoint.y);
            CGFloat xDistanceFromTouch = fabsf(touchLocation.x - springBehaviour.anchorPoint.x);
            CGFloat scrollResistance = (yDistanceFromTouch + xDistanceFromTouch) / 1500.0f;
            
            UICollectionViewLayoutAttributes *item = [springBehaviour.items firstObject];
            CGPoint centerOfCell = item.center;
            centerOfCell.y += deltaX * scrollResistance;
            centerOfCell.x += deltaY * scrollResistance;
            item.center = centerOfCell;
            
            [self.dynamicAnimator updateItemUsingCurrentState:item];
        }];

    }
    
    //return NO
    return kZoomEffect ? YES : NO;
}

//- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context{
//    
//}

- (CGSize)collectionViewContentSize
{
    //NSInteger row = _itemsPerRow == 0?0:_itemTotalCount / _itemsPerRow;

    CGFloat contentWidth = (_itemsPerRow+1) * _hexagonSize.width;
    //CGFloat contentHeight = ( (row * 0.75f) * _hexagonSize.height) + (0.5f + _hexagonSize.height);
    CGFloat contentHeight = (_itemsPerRow+1) * adjWidth;
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
