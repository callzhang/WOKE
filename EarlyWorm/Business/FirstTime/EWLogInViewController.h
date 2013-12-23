//
//  EWLogInViewController.h
//  EarlyWorm
//
//  Created by Lei on 12/7/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "SMClient.h"

@interface EWLogInViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *btnLoginLogout;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) SMClient *client;
@property (weak, nonatomic) IBOutlet UIImageView *profileView;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UIButton *proceedBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
+ (EWLogInViewController *)sharedInstance;
- (IBAction)connect:(id)sender;
- (IBAction)check:(id)sender;
- (IBAction)proceed:(id)sender;

@end
