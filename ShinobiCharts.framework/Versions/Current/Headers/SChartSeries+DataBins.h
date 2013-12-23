//
//  SChartSeries+DataBins.h
//  ShinobiCharts
//
//  Copyright 2013 Scott Logic Ltd. All rights reserved.
//
//

#import "SChartSeries.h"

@interface SChartSeries (DataBins)

- (int)numberOfDataPointsInBin;

- (void)setNumberOfDataPointsInBin:(int)numberOfDataPoints;

@end
