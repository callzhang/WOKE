//
//  EWHistoryViewController.m
//  EarlyWorm
//
//  Created by shenslu on 13-10-4.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWHistoryViewController.h"

// Util
#import "EWUIUtil.h"

@interface EWHistoryViewController ()

@property (nonatomic, strong) UIView *contentView;
//@property (nonatomic, strong) ShinobiChart *chartView;

@end

@interface EWHistoryViewController (Chart)
@end

@implementation EWHistoryViewController
@synthesize contentView = _contentView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = LOCALSTR(@"History_Title");
    }
    return self;
}

- (void)initData {
    
}

- (void)initView {
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradient_bg.png"]];
    
    UIView *topToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, EWScreenWidth, 44)];
    topToolBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:topToolBar];
    
    
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, topToolBar.bottom, EWScreenWidth, EWContentHeight-topToolBar.height)];
    _contentView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_contentView];
    
    // Test
    [self reloadChartView];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initData];
    [self initView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Call Event

- (void)initChartView {
    /*
    _chartView = [[ShinobiChart alloc] initWithFrame:CGRectMake(0, 0, EWScreenWidth, 300)];
    _chartView.title = @"Your Wake Up History";
    _chartView.licenseKey = kChartLicenseKey;
    
    //auto resize
    //_chart.autoresizingMask = ~UIViewAutoresizingNone;
    //add a pair ox axes
    SChartNumberAxis *xAxis = [[SChartNumberAxis alloc] init];
    xAxis.title = @"Date";
    
    SChartNumberAxis *yAxis = [[SChartNumberAxis alloc] init];
    yAxis.rangePaddingHigh = @(0.1);
    yAxis.rangePaddingLow = @(0.1);
    yAxis.title = @"History";
    // enable gestures
    yAxis.enableGesturePanning = YES;
    yAxis.enableGestureZooming = YES;
    xAxis.enableGesturePanning = YES;
    xAxis.enableGestureZooming = YES;
    _chartView.xAxis = xAxis;
    _chartView.yAxis = yAxis;
    
    _chartView.datasource = self;
    //show legend
    _chartView.legend.hidden = (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone);
    
    [self.contentView addSubview:_chartView];*/
}

- (void)reloadChartView {
    [self initChartView];
//    UIView *chartView = nil;
//    [self.contentView addSubview:chartView];
}

@end

@implementation EWHistoryViewController (Chart)

@end
