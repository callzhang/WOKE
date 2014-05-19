

#import <UIKit/UIKit.h>

@interface EWHexagonFlowLayout : UICollectionViewFlowLayout
@property (nonatomic) NSArray *attributeArray;
@property (nonatomic) NSInteger itemsPerRow;
@property (nonatomic) NSInteger itemTotalCount;
@property (nonatomic) CGSize hexagonSize;

@end
