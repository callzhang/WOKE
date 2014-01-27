//
//  EWLogInViewController.h
//  EarlyWorm
//
//  Created by Lei on 12/7/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface EWLogInViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *btnLoginLogout;
@property (weak, nonatomic) IBOutlet UIImageView *profileView;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UIButton *proceedBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;


+ (EWLogInViewController *)sharedInstance;
- (IBAction)connect:(id)sender; //register fb
- (IBAction)check:(id)sender;
- (IBAction)proceed:(id)sender;

- (void)loginInBackground;

@end
