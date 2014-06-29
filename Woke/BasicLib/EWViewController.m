//
//  EWViewController.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-8.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWViewController.h"
#import "EWDeviceInfo.h"
#import "EWUIUtil.h"

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
    self.view.backgroundColor = [UIColor clearColor];
    [EWUIUtil addTransparantNavigationBarToViewController:self withLeftItem:nil rightItem:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
