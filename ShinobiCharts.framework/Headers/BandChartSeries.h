//
//  SChartGLView+BandChartSeries.h
//  Dev
//
//  Copyright (c) 2012 Scott Logic Ltd. All rights reserved.
//

@interface SChartGLView (BandChartSeries)

- (void)drawBandSeriesFill:(float *)seriesHigh
                 forSeries:(SChartSeries *)s
              andLowSeries:(float *)seriesLow
                  forIndex:(int *)trianglesIndex
                  withSize:(int)size 
         withAreaColorHigh:(UIColor *)areaColorHigh 
          withAreaColorLow:(UIColor *)areaColorLow  
           withOrientation:(int)orientation 
            withNumCrosses:(int)numCrosses
            andTranslation:(const SChartGLTranslation *)transform;

@end
