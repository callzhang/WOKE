//
//  TestShakeViewController.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-3.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "TestShakeViewController.h"
#import "EWShakeManager.h"

@interface TestShakeViewController ()

@property (nonatomic, strong) EWShakeManager *shakeManager;
@property (nonatomic, strong) UIView *squareView;

@end

@interface TestShakeViewController (EWShakeManager) <EWShakeManagerDelegate>
@end

@implementation TestShakeViewController

- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(OnCancel)];
    
    _squareView = [[UIView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    _squareView.backgroundColor = [UIColor redColor];
    [self.view addSubview:_squareView];
    
    _shakeManager = [[EWShakeManager alloc] init];
    _shakeManager.delegate = self;
    [_shakeManager register];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_shakeManager unregister];
}

#pragma mark - UIEvents 

- (void)OnCancel {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end

@implementation TestShakeViewController (EWShakeManager)

- (UIView *)currentView {
    return self.view;
}

- (void)EWShakeManagerDidShaked {
    
    if ([_squareView.backgroundColor isEqual:[UIColor redColor]]) {
        _squareView.backgroundColor = [UIColor greenColor];
    }
    else {
        _squareView.backgroundColor = [UIColor redColor];
    }
}

@end
