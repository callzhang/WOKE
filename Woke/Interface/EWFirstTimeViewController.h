//
//  EWFirstTimeViewController.h
//  EarlyWorm
//
//  Created by Lei on 11/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWViewController.h"
#import "MBProgressHUD.h"



@interface EWFirstTimeViewController : EWViewController <MBProgressHUDDelegate>{
    MBProgressHUD *refreshHUD;
}

- (IBAction)start:(id)sender;

@end
