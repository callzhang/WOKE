//
//  EWViewController.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-8.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWViewController.h"
#import "EWDeviceInfo.h"

@interface EWViewController ()

@end

@implementation EWViewController

- (id)init {
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = kCustomWhite;

#ifdef __IPHONE_7_0
    if ([EWDeviceInfo isIOS7_Plus]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
#endif
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
