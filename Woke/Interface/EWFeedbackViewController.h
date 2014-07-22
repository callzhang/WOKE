//
//  EWFeedbackViewController.h
//  Woke
//
//  Created by Lee on 7/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EWFeedbackViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIPickerView *type;
@property (weak, nonatomic) IBOutlet UITextView *content;

@end
