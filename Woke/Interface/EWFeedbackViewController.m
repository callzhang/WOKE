//
//  EWFeedbackViewController.m
//  Woke
//
//  Created by Lee on 7/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWFeedbackViewController.h"
#import "TestFlight.h"
#import "EWUIUtil.h"

#define titles                  @[@"Bug report", @"Feedback", @"Feature request"]
#define feedbackPlaceholder     @"Please provide feedback here..."

@interface EWFeedbackViewController ()

@end

@implementation EWFeedbackViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad{
    self.type.backgroundColor = [UIColor clearColor];
    self.type.dataSource = self;
    self.type.delegate = self;
    self.content.delegate = self;
    self.content.text = feedbackPlaceholder;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    UIBarButtonItem *confirmBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Confirm Button"] style:UIBarButtonItemStylePlain target:self action:@selector(submit:)];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Close Button"] style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    [EWUIUtil addTransparantNavigationBarToViewController:self withLeftItem:backBarButtonItem rightItem:confirmBarButtonItem];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)submit:(id)sender{
    NSString *type = titles[[self.type selectedRowInComponent:0]];
    NSString *content = self.content.text;
    NSString *feedback = [NSString stringWithFormat:@"%@: %@", type, content];
    
    [TestFlight submitFeedback:feedback];
    
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
}

- (IBAction)cancel:(id)sender{
    
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component{
    
    NSString *title = titles[row];
    NSAttributedString *type = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    return type;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return titles.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:feedbackPlaceholder]) {
        textView.text = @"";
        textView.textColor = [UIColor whiteColor]; //optional
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = feedbackPlaceholder;
        textView.textColor = [UIColor lightGrayColor]; //optional
    }
    [textView resignFirstResponder];
}
@end
