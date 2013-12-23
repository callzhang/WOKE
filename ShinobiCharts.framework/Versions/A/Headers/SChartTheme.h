//
//  SChartTheme.h
//  SChart
//
//  Copyright 2011 Scott Logic Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SChartStyle;
@class SChartTitleStyle;
@class SChartMainTitleStyle;
@class SChartLegendStyle;
@class SChartAxisStyle;
@class SChartAxisStyle;
@class SChartCrosshairStyle;
@class SChartBoxGestureStyle;
@class SChartLineSeriesStyle;
@class SChartBandSeriesStyle;
@class SChartColumnSeriesStyle;
@class SChartBarSeriesStyle;
@class SChartDonutSeriesStyle;
@class SChartScatterSeriesStyle;
@class SChartOHLCSeriesStyle;
@class SChartCandlestickSeriesStyle;
@class SChartBubbleSeriesStyle;

/** Each ShinobiChart has a SChartTheme object that manages the look of the chart. Individual properties can still be set directly on elements of the chart, and these properties will take precedence over theme values, but the theme is a convenient way to manage chart styling. 
 
 ShinobiCharts come with two built-in themes - Light (SChartLightTheme) and Dark (SChartDarkTheme). 
 
 *Light Theme*: Brighter colors based on a white background<br>
 *Dark Theme*: Softer colors on a black background
 
 By default, a chart will use the light theme.
 
 Each theme contains a number of style objects that affect the look of certain aspects of the chart such as its axis, its title or its crosshair.  These style objects are exposed as properties on the theme.  If you go to the documentation for each style object property, it will explain which aspect of chart styling that property is responsible for.
 
 There are also a number of style objects for each series type.  Six series styles are provided out of the box by a chart.  If there are more series on the chart than that, the chart will loop through the style objects it has, using the first style object again once it has cycled through its available styles.
 
 To create custom themes, choose one of the two built-in themes that most matches your desired theme and customize. To switch the theme on a chart - simply set `chart.theme` to a new theme object.
 
 @available Standard
 @available Premium
 @sa ChartsUserGuide
 @sample ColumnChart
 @sample PieChart
 @sample FinancialChart
 */
@interface SChartTheme : NSObject

#pragma mark -
#pragma mark Initializing a theme
/** @name Initializing a theme */

/** Initializes and returns a newly allocated theme object with default settings.
 @return An initialized theme object or `nil` if the object couldn't be created.
 */
- (id)init;

/* DEPRECATED - This looks like a private method.  We will take this off the public API in a future commit. */
- (void)setStyles;

#pragma mark -
#pragma mark Individual style objects
/** @name Individual style objects */

/** Style options relating to the overall chart. 
 
 This includes properties such as:
 
 - The background color of the chart.
 - The border of the chart.
 
 If you wish to update the style of the chart, the best way is to edit the properties of this object.  For example, to change the background color of the chart view, you could use the following code:
 
    chart.theme.chartStyle.backgroundColor = [UIColor redColor];
    [chart applyTheme];
 
 The [ShinobiChart applyTheme] method tells the chart to redraw itself using the new settings in the theme.
 
 @see SChartStyle
 */
@property (nonatomic, retain) SChartStyle       *chartStyle;

/** Style options relating to the chart title. 
 
 This includes properties such as: 
 
 - The color, font and alignment of the title.
 - Whether the title overlaps with the chart.
 
 If you wish to update the style of the chart title, the best way is to edit the properties of this object.  For example, to change the text color of the chart title, you could use the following code:
 
    chart.theme.chartTitleStyle.textColor = [UIColor blueColor];
    [chart applyTheme];
 
 The [ShinobiChart applyTheme] method tells the chart to redraw itself using the new settings in the theme.
 
 @see SChartMainTitleStyle
 */
@property (nonatomic, retain) SChartMainTitleStyle  *chartTitleStyle;

/** Style options relating to the chart legend. 
 
 This includes properties such as:
 
 - The color and font of text in the legend.
 - The alignment of symbols in the legend.
 - The color of the legend border.
 - The corner radius of the legend.
 - The background color of the legend.
 - The padding around the legend.
 
 If you wish to update the style of the chart legend, the best way is to edit the properties of this object.  For example, to change the text color in the legend, you could use the following code:
 
    chart.theme.legendStyle.fontColor = [UIColor blueColor];
    [chart applyTheme];
 
 The [ShinobiChart applyTheme] method tells the chart to redraw itself using the new settings in the theme.
 
 @see SChartLegendStyle
 */
@property (nonatomic, retain) SChartLegendStyle      *legendStyle;

/** Style options relating to the x axis. 
 
 This includes properties such as:
 
 - The color and font of the axis title.
 - The position of the axis title.
 - The width and color of the axis.
 - The width and color of tick marks on the axis.
 - Whether tick marks are shown.
 - The color of grid lines on the chart for the x axis.
 - Whether grid lines are shown.
 
 If you wish to update the style of the x axis, the best way is to edit the properties of this object.  For example, to change the width of the axis, you could use the following code:
 
    chart.theme.xAxisStyle.lineColor = [UIColor redColor];
    [chart applyTheme];
 
 The [ShinobiChart applyTheme] method tells the chart to redraw itself using the new settings in the theme.
 
 @see SChartAxisStyle
 */
@property (nonatomic, retain) SChartAxisStyle        *xAxisStyle;

/** Style options relating to the y axis.
 
 This includes properties such as:
 
 - The color and font of the axis title.
 - The position of the axis title.
 - The width and color of the axis.
 - The width and color of tick marks on the axis.
 - Whether tick marks are shown.
 - The color of grid lines on the chart for the y axis.
 - Whether grid lines are shown.
 
 If you wish to update the style of the y axis, the best way is to edit the properties of this object.  For example, to change the width of the axis, you could use the following code:
 
    chart.theme.yAxisStyle.lineColor = [UIColor redColor];
    [chart applyTheme];
 
 The [ShinobiChart applyTheme] method tells the chart to redraw itself using the new settings in the theme.
 
 @see SChartAxisStyle
 */
@property (nonatomic, retain) SChartAxisStyle        *yAxisStyle;

/** Style options relating to the chart crosshair.
 
 This includes properties such as:
 
 - The color and width of crosshair lines.
 - The color and font of the crosshair tooltip.
 - The width and color of the crosshair tooltip border.
 
 If you wish to update the style of the crosshair, the best way is to edit the properties of this object.  For example, to change the width of the crosshair lines, you could use the following code:
 
    chart.theme.crosshairStyle.lineWidth = @(5);
    [self.chart applyTheme];
 
 The [ShinobiChart applyTheme] method tells the chart to redraw itself using the new settings in the theme.
 
 @see SChartCrosshairStyle
 */
@property (nonatomic, retain) SChartCrosshairStyle   *crosshairStyle;

/** Style options relating to the box gesture. 
 
 This includes properties such as:
 
 - The color of the box which is displayed.
 - The color of tracking lines.
 - The width of the lines on the box.
 - The width of the tracking lines.
 
 If you wish to update the style of box gestures, the best way is to edit the properties of this object.  For example, to change the width of the lines drawn around the box, you could use the following code:
 
    chart.theme.boxGestureStyle.boxLineWidth = 5.f;
 
 @see SChartBoxGestureStyle
 */
@property (nonatomic, retain) SChartBoxGestureStyle *boxGestureStyle;

#pragma mark -
#pragma mark Colors for this theme
/** @name Colors for this theme */

/** Black palette color.
 
 This is used for:
 
 - The color of the box displayed during box gestures.
 - The text color on the chart title and the axis titles.
 - The color of the legend text and border.
 - The color of axis tick marks and labels.
 - The outline drawn for candlestick chart series.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *blackColor;

/** Black palette color with reduced alpha. 
 
 This is used for tracking lines on box gestures, and for the major grid lines on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *blackColorLowAlpha;

/** Red palette color. 
 
 This is used for:
 
 - Area fill underneath the first line series on the chart.
 - The color of the first bar/column series on the chart.
 - The color of falling data points in the first candlestick series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *redColorDark;

/** Red palette color with increased brightness. 
 
 This is used for:
 
 - The line color of the first line series on the chart.
 - The color of the lower limiting line of the first band series on the chart.
 - The color of the first bar/column series on the chart.
 - The color of points in the first scatter series on the chart.
 - The color of falling data points in the first OHLC series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *redColorLight;

/** Red palette color with increased brightness.
 
 This is used for:
 
 - The color of falling data points in the first OHLC series on the chart.
 - The color of falling data points in the first candlestick series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *redColorBrightLight;

/** Green palette color. 
 
 This is used for:
 
 - The area fill color underneath the second line series on the chart.
 - The color of the second bar/column series on the chart.
 - The color of rising data points in the first OHLC series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *greenColorDark;

/** Green palette color with increased brightness. 
 
 This is used for:
 
 - The line color of the second line series on the chart.
 - The color of the upper limiting line in the first band series on the chart.
 - The color of points in the first band series on the chart.
 - The color of the second bar/column series on the chart.
 - The color of points in the second scatter series on the chart.
 - The color of rising data points in the first OHLC series on the chart.
 - The color of rising data points in the first candlestick series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *greenColorLight;

/** Green palette color with increased brightness. 
 
 This is used for the color of rising data points in the first candlestick series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *greenColorBrightLight;

/** Blue palette color. 
 
 This is used for:
 
 - The area fill color underneath the third line series on the chart.
 - The color of the third bar/column series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *blueColorDark;

/** Blue palette color with increased brightness. 
 
 This is used for:
 
 - The color of the third line series on the chart.
 - The color of the lower limiting line in the second band series on the chart.
 - The color of the third bar/column series on the chart.
 - The color of points in the third scatter series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *blueColorLight;

/** Orange palette color. 
 
 This is used for:
 
 - The area fill color underneath the fourth line series on the chart.
 - The color of the fourth bar/column series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *orangeColorDark;

/** Orange palette color with increased brightness.
 
 This is used for:
 
 - The color of the fourth line series on the chart.
 - The color of the upper limiting line in the second band series on the chart.
 - The color of points in the second band series on the chart.
 - The color of the fourth bar/column series on the chart.
 - The color of the fourth scatter series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *orangeColorLight;

/** Purple palette color.
 
 This is used for:
 
 - The area fill color below the fifth line series on the chart.
 - The color of the fifth bar/column series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *purpleColorDark;

/** Purple palette color with increased brightness.
 
 This is used for:
 
 - The color of the fifth line series on the chart.
 - The color of the lower limiting line on the third band series on the chart.
 - The color of the fifth bar/column series on the chart.
 - The color of the fifth scatter series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *purpleColorLight;

/** Yellow palette color. 
 
 This is used for:
 
 - The area fill color below the sixth line series on the chart.
 - The color of the sixth bar/column series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *yellowColorDark;

/** Yellow palette color with increased brightness. 
 
 This is used for:
 
 - The color of the sixth line series on the chart.
 - The color of the upper limiting line on the third band series on the chart.
 - The color of points in the third band series on the chart.
 - The color of the sixth bar/column series on the chart.
 - The color of the sixth scatter series on the chart.
 
 The theme color properties are included to allow you to access the colors used within the theme, and use them elsewhere in your app.
 */
@property (nonatomic, retain, readonly) UIColor *yellowColorLight;

#pragma mark -
#pragma mark Fonts
/** @name Fonts */

/** The name of the bold font to use within the theme. */
@property (nonatomic, retain) NSString *boldFontName;

/** The name of the regular font to use within the theme. 
 
 The regular font is used for:
 
 - The chart title.
 - The axis titles.
 - Text in the legend.
 - Text in the crosshair tooltip.
 - Labels in the first donut series on the chart.
 */
@property (nonatomic, retain) NSString *regularFontName;

/** The name of the light font to use within the theme. 
 
 The light font is used for labels on major axis ticks.
 */
@property (nonatomic, retain) NSString *lightFontName;

#pragma mark -
#pragma mark Managing series styles
/** @name Managing series styles */
/** Default line width for all line series 
 
 Use this setting to apply a consistent line width across all line series.  After setting this value call [ShinobiChart applyTheme] on your chart.  This value will be used by default.  If you have explicitly set the line width on a line series, that value will take precedence over the default.
 */
@property (nonatomic, retain) NSNumber *lineWidth;

/** Default line width for all column series
 
 Use this setting to apply a consistent line width across all column series. After setting this value call [ShinobiChart applyTheme] on your chart.  This value will be used by default.  If you have explicitly set the column line width on your series, that value will take precedence over the default.
 */
@property (nonatomic, retain) NSNumber *columnLineWidth;

/** Default line width for all bar series
 
 Use this setting to apply a consistent line width across all bar series.  After setting this value call [ShinobiChart applyTheme] on your chart.  This value will be used by default.  If you have explicitly set the bar width on your series, that value will take precedence over the default.
 */
@property (nonatomic, retain) NSNumber *barLineWidth;

/** Default outline or 'crust' thickness for all donut series
  
 Use this setting to apply a consistent crust thickness across all donut series.  After setting this value call [ShinobiChart applyTheme] on your chart.  This value will be used by default.  If you have explicitly set the donut crust thickness on your series, that value will take precedence over the default.
 */
@property (nonatomic, retain) NSNumber *donutCrustThickness;

/** Default outline or 'crust' thickness for all pie series

 Use this setting to apply a consistent crust thickness across all pie series.  After setting this value call [ShinobiChart applyTheme] on your chart.  This value will be used by default.  If you have explicitly set the pie crust thickness on your series, that value will take precedence over the default.
 */
@property (nonatomic, retain) NSNumber *pieCrustThickness;

#pragma mark -
#pragma mark - Series styles
/** @name Series styles */

/** Adds a series style to the array of line series styles contained within the theme.
 
 The theme contains two sets of series styles - one for series in their normal state, and one for when they are selected.  When you add a series style to the theme, you can specify when it should be used on a series using the `selected` parameter.
 @param newStyle The series style to add to the theme.
 @param selected If this is set to `YES`, the style will be used for series when they are selected.
 */
- (void)addLineSeriesStyle:(SChartLineSeriesStyle *)newStyle asSelected:(BOOL)selected;

/** Stores the series style in the array of band series styles
 
 The theme contains two sets of series styles - one for series in their normal state, and one for when they are selected.  When you add a series style to the theme, you can specify when it should be used on a series using the `selected` parameter.
 @param newStyle The series style to add to the theme.
 @param selected If this is set to `YES`, the style will be used for series when they are selected.
 */
- (void)addBandSeriesStyle:(SChartBandSeriesStyle *)newStyle asSelected:(BOOL)selected;

/** Stores the series style in the array of column series styles
 
 The theme contains two sets of series styles - one for series in their normal state, and one for when they are selected.  When you add a series style to the theme, you can specify when it should be used on a series using the `selected` parameter.
 @param newStyle The series style to add to the theme.
 @param selected If this is set to `YES`, the style will be used for series when they are selected.
 */
- (void)addColumnSeriesStyle:(SChartColumnSeriesStyle *)newStyle asSelected:(BOOL)selected;

/** Stores the series style in the array of bar series styles
 
 The theme contains two sets of series styles - one for series in their normal state, and one for when they are selected.  When you add a series style to the theme, you can specify when it should be used on a series using the `selected` parameter.
 @param newStyle The series style to add to the theme.
 @param selected If this is set to `YES`, the style will be used for series when they are selected.
 */
- (void)addBarSeriesStyle:(SChartBarSeriesStyle *)newStyle asSelected:(BOOL)selected;

/** Encodes the donut series style object and stores in the array of donut series styles. 
 
 The theme contains two sets of series styles - one for series in their normal state, and one for when they are selected.  When you add a series style to the theme, you can specify when it should be used on a series using the `selected` parameter.
 @param newStyle The series style to add to the theme.
 @param selected If this is set to `YES`, the style will be used for series when they are selected.*/
- (void)addDonutSeriesStyle:(SChartDonutSeriesStyle *)newStyle asSelected:(BOOL)selected;

/** Stores the series style in the array of scatter series styles
  
 The theme contains two sets of series styles - one for series in their normal state, and one for when they are selected.  When you add a series style to the theme, you can specify when it should be used on a series using the `selected` parameter.
 @param newStyle The series style to add to the theme.
 @param selected If this is set to `YES`, the style will be used for series when they are selected.
 */
- (void)addScatterSeriesStyle:(SChartScatterSeriesStyle *)newStyle asSelected:(BOOL)selected;

/** Stores the series style in the array of ohlc series styles
 
 The theme contains two sets of series styles - one for series in their normal state, and one for when they are selected.  When you add a series style to the theme, you can specify when it should be used on a series using the `selected` parameter.
 @param newStyle The series style to add to the theme.
 @param selected If this is set to `YES`, the style will be used for series when they are selected.
 */
- (void)addOHLCSeriesStyle:(SChartOHLCSeriesStyle *)newStyle asSelected:(BOOL)selected;

/** Stores the series style in the array of candlestick series styles
 
 The theme contains two sets of series styles - one for series in their normal state, and one for when they are selected.  When you add a series style to the theme, you can specify when it should be used on a series using the `selected` parameter.
 @param newStyle The series style to add to the theme.
 @param selected If this is set to `YES`, the style will be used for series when they are selected.
 */
- (void)addCandlestickSeriesStyle:(SChartCandlestickSeriesStyle *)newStyle asSelected:(BOOL)selected;

/** Returns the line series style for the specified series on the chart.
 @param seriesIndex The index of the series on the chart.
 @param selected If set to `YES`, this method returns the selected style for the series.  If not, this method returns the normal style for the series.
 @return The style to use for the given series.
 */
- (SChartLineSeriesStyle *)lineSeriesStyleForSeriesAtIndex:(int)seriesIndex selected:(BOOL)selected;

/** Returns the band series style for the specified series on the chart. 
 
 @param seriesIndex The index of the series on the chart.
 @param selected If set to `YES`, this method returns the selected style for the series.  If not, this method returns the normal style for the series.
 @return The style to use for the given series.
 */
- (SChartBandSeriesStyle *)bandSeriesStyleForSeriesAtIndex:(int)seriesIndex selected:(BOOL)selected;

/** Returns the column series style for the specified series on the chart. 
 
 @param seriesIndex The index of the series on the chart.
 @param selected If set to `YES`, this method returns the selected style for the series.  If not, this method returns the normal style for the series.
 @return The style to use for the given series.
 */
- (SChartColumnSeriesStyle *)columnSeriesStyleForSeriesAtIndex:(int)seriesIndex selected:(BOOL)selected;

/** Returns the bar series style for the specified series on the chart. 
 
 @param seriesIndex The index of the series on the chart.
 @param selected If set to `YES`, this method returns the selected style for the series.  If not, this method returns the normal style for the series.
 @return The style to use for the given series.
 */
- (SChartBarSeriesStyle *)barSeriesStyleForSeriesAtIndex:(int)seriesIndex selected:(BOOL)selected;

/** Returns the donut series style for the specified series on the chart. 
 
 @param seriesIndex The index of the series on the chart.
 @param selected If set to `YES`, this method returns the selected style for the series.  If not, this method returns the normal style for the series.
 @return The style to use for the given series.
 */
- (SChartDonutSeriesStyle *)donutSeriesStyleForSeriesAtIndex:(int)seriesIndex selected:(BOOL)selected;

/** Returns the scatter series style for the specified series on the chart.
 
 @param seriesIndex The index of the series on the chart.
 @param selected If set to `YES`, this method returns the selected style for the series.  If not, this method returns the normal style for the series.
 @return The style to use for the given series.
 */
- (SChartScatterSeriesStyle *)scatterSeriesStyleForSeriesAtIndex:(int)seriesIndex selected:(BOOL)selected;


/** Returns the bubble series style for the specified series on the chart.
 
 @param seriesIndex The index of the series on the chart.
 @param selected If set to `YES`, this method returns the selected style for the series.  If not, this method returns the normal style for the series.
 @return The style to use for the given series.
 */
- (SChartBubbleSeriesStyle *)bubbleSeriesStyleForSeriesAtIndex:(int)seriesIndex selected:(BOOL)selected;

/** Returns the OHLC series style for the specified series on the chart. 
 
 @param seriesIndex The index of the series on the chart.
 @param selected If set to `YES`, this method returns the selected style for the series.  If not, this method returns the normal style for the series.
 @return The style to use for the given series.
 */
- (SChartOHLCSeriesStyle *)ohlcSeriesStyleForSeriesAtIndex:(int)seriesIndex selected:(BOOL)selected;

/** Returns the candlestick series style for the specified series on the chart.
 
 @param seriesIndex The index of the series on the chart.
 @param selected If set to `YES`, this method returns the selected style for the series.  If not, this method returns the normal style for the series.
 @return The style to use for the given series.
 */
- (SChartCandlestickSeriesStyle *)candlestickSeriesStyleForSeriesAtIndex:(int)seriesIndex selected:(BOOL)selected;

/* DEPRECATED - We will move this off the public API in a future commit. */
-(void)configureLineSeriesStyle:(SChartLineSeriesStyle *)style;

/* DEPRECATED - We will move this off the public API in a future commit. */
-(void)configureBarSeriesStyle:(SChartBarSeriesStyle *)style;

/* DEPRECATED - We will move this off the public API in a future commit. */
-(void)configureColumnSeriesStyle:(SChartColumnSeriesStyle *)style;

/* DEPRECATED - We will move this off the public API in a future commit. */
-(void)configureScatterSeriesStyle:(SChartScatterSeriesStyle *)style;

@end
