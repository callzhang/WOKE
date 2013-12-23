#import "SChartPointStruct.h"

typedef struct SChartSeriesDistanceInfo
{
    double distance;
    SChartInternalDataPoint *__unsafe_unretained point;
    SChartCartesianSeries *__unsafe_unretained const series;
    SChartPoint resolvedPoint;
} SChartSeriesDistanceInfo;
