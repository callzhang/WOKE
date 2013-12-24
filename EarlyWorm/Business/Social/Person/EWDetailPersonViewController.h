//
//  EWDetailPersonViewController.h
//  EarlyWorm
//
//  Created by Lei on 9/5/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EWPerson;
@class EWTaskItem;
@class ShinobiChart;

@interface EWDetailPersonViewController : EWViewController<UIAlertViewDelegate> {
    //ShinobiChart *_chart;
    NSArray *tasks;
    EWPerson *me;
}
//PersonInfoView
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *level;
@property (weak, nonatomic) IBOutlet UILabel *statement;
- (IBAction)extProfile:(id)sender;

@property (nonatomic) EWPerson *person;
@end
