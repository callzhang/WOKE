

#import <UIKit/UIKit.h>

#define kHexagonStructureChange         @"hexagon_structure_change"

@interface EWHexagonFlowLayout : UICollectionViewFlowLayout
@property (nonatomic) NSArray *attributeArray;
@property (nonatomic) NSInteger itemsPerRow;
@property (nonatomic) NSInteger itemTotalCount;
@property (nonatomic) CGSize hexagonSize;

- (void)resetLayoutWithRatio:(float)r;

@end
