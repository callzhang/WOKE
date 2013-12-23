//
//  SChartCandlestickSeries.h
//  SChart
//
//  Copyright (c) 2012 Scott Logic Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SChartOHLCSeries.h"
#import "SChartCandlestickSeriesStyle.h"

/** `SChartCandlestickSeries` is a type of `SChartSeries` which displays Open-High-Low-Close data on a chart.
 
 Each data point in a candlestick series is visualised as a thick candle between the open and close values, with 'wicks' indicating the high and low positions.
 
 Data points in a candlestick series will contain multiple values.  This means that they will be instances of `SChartMultiXDataPoint` or `SChartMultiYDataPoint`, depending on the orientation of the series.  The keys for the values in each data point will be `SChartCandlestickKeyOpen`, `SChartCandlestickKeyHigh`, `SChartCandlestickKeyLow` and `SChartCandlestickKeyClose`.
 
 In order to provide the Open, High, Low, and Close values to the chart, the data points in the candlestick series should implement either the `[SChartData sChartXValueForKey:]` method or the `[SChartData sChartYValueForKey:]` method on the `SChartData` protocol, depending on the series orientation.
 
 The series contains an instance of `SChartCandlestickSeriesStyle`, which manages the appearance of the series on the chart.
 
 @available Premium
 @sa ChartsUserGuide
 @sample FinancialChart
 */
@interface SChartCandlestickSeries : SChartOHLCSeries

#pragma mark -
#pragma mark Styling
/**@name Styling */

/** Manages the appearance of the candlestick series on the chart.
 
 The default settings of the style are inherited from the chart theme.  You can tweak the appearance of the series by modifying the style.
 
 @see SChartCandlestickSeriesStyle
 */
-(SChartCandlestickSeriesStyle *)style;

/** Sets the style object for the candlestick series.
 
 @param style The new style object to use for the candlestick series.
 @see style
 */
-(void)setStyle:(SChartCandlestickSeriesStyle *)style;

/** Manages the appearance of the candlestick series when it is selected.
 
 Style settings in this object will be applied when the series is marked as selected (or a point is selected).
 
 The default settings of the style are inherited from the chart theme.  You can tweak the appearance of the series by modifying the style.
 
 @see SChartCandlestickSeriesStyle
 */
-(SChartCandlestickSeriesStyle *)selectedStyle;

/** Sets the style object for the candlestick series when it is selected.
 
 @param selectedStyle The new style object to use.
 @see selectedStyle
 */
-(void)setSelectedStyle:(SChartCandlestickSeriesStyle *)selectedStyle;

@end
