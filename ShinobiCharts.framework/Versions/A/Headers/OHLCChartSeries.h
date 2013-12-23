//
//  SChartGLView+OHLCChartSeries.h
//  Dev
//
//  Copyright (c) 2012 Scott Logic Ltd. All rights reserved.
//

#import "SChartGLCommon.h"

@interface SChartGLView (OHLCChartSeries)

- (void)drawOHLCPoints:(float *)series
             forSeries:(SChartSeries *)s
         forLinesIndex:(int *)linesIndex
   forOffsetLinesIndex:(int *)offsetLinesIndex
              withSize:(int)size
            withColors:(NSMutableArray *)colors
    withGradientColors:(NSMutableArray *)gradientColors
       withOrientation:(int)orientation
         withOHLCWidth:(float)ohlcWidth
        withTrunkWidth:(float)trunkWidth
          withArmWidth:(float)armWidth
        andTranslation:(const SChartGLTranslation *)transform;

@end
