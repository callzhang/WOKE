

#import "EWSelectionViewController.h"
#import <QuartzCore/QuartzCore.h>

#define EW_PICKER_HEIGHT_PORTRAIT 150
#define EW_PICKER_HEIGHT_LANDSCAPE 100


@interface  EWSelectionViewController ()

@property (nonatomic, weak) UIViewController *rootViewController;

@property (nonatomic, weak) NSLayoutConstraint *xConstraint;
@property (nonatomic, weak) NSLayoutConstraint *yConstraint;
@property (nonatomic, weak) NSLayoutConstraint *widthConstraint;

@property (nonatomic, strong) UIView *titleLabelContainer;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;

@property (nonatomic, strong) UIButton *nowButton;

@property (nonatomic, strong) UIView *datePickerContainer;
@property (nonatomic, strong) NSLayoutConstraint *pickerHeightConstraint;

@property (nonatomic, strong) UIView *cancelAndSelectButtonContainer;
@property (nonatomic, strong) UIView *cancelAndSelectButtonSeperator;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *selectButton;

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) UIMotionEffectGroup *motionEffectGroup;

@property (nonatomic, copy) EWSelectionBlock selectedDateBlock;
@property (nonatomic, copy) EWCancelBlock cancelBlock;

@property (nonatomic, assign) BOOL hasBeenDismissed;

@end

@implementation EWSelectionViewController

@synthesize selectedBackgroundColor = _selectedBackgroundColor;

#pragma mark - Class
+ (instancetype)dateSelectionController {
    return [[EWSelectionViewController alloc] init];
}

static NSString *_localizedNowTitle = @"Now";
static NSString *_localizedCancelTitle = @"Cancel";
static NSString *_localizedSelectTitle = @"Select";

+ (NSString *)localizedTitleForNowButton {
    return _localizedNowTitle;
}

+ (NSString *)localizedTitleForCancelButton {
    return _localizedCancelTitle;
}

+ (NSString *)localizedTitleForSelectButton {
    return _localizedSelectTitle;
}

+ (void)setLocalizedTitleForNowButton:(NSString *)newLocalizedTitle {
    _localizedNowTitle = newLocalizedTitle;
}

+ (void)setLocalizedTitleForCancelButton:(NSString *)newLocalizedTitle {
    _localizedCancelTitle = newLocalizedTitle;
}

+ (void)setLocalizedTitleForSelectButton:(NSString *)newLocalizedTitle {
    _localizedSelectTitle = newLocalizedTitle;
}

+ (void)showDateSelectionViewController:(EWSelectionViewController *)aViewController fromViewController:(UIViewController *)rootViewController {
    aViewController.backgroundView.alpha = 0;
    [rootViewController.view addSubview:aViewController.backgroundView];
    
    [rootViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:aViewController.backgroundView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeTop multiplier:0 constant:0]];
    [rootViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:aViewController.backgroundView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeLeading multiplier:0 constant:0]];
    [rootViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:aViewController.backgroundView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [rootViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:aViewController.backgroundView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    
    [aViewController willMoveToParentViewController:rootViewController];
    [aViewController viewWillAppear:YES];
    
    [rootViewController addChildViewController:aViewController];
    [rootViewController.view addSubview:aViewController.view];
    
    [aViewController viewDidAppear:YES];
    [aViewController didMoveToParentViewController:rootViewController];
    
    //CGFloat height = RM_DATE_SELECTION_VIEW_HEIGHT_PORTAIT;
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        if(UIInterfaceOrientationIsLandscape(rootViewController.interfaceOrientation)) {
            //height = RM_DATE_SELECTION_VIEW_HEIGHT_LANDSCAPE;
            aViewController.pickerHeightConstraint.constant = EW_PICKER_HEIGHT_LANDSCAPE;
        } else {
            //height = RM_DATE_SELECTION_VIEW_HEIGHT_PORTAIT;
            aViewController.pickerHeightConstraint.constant = EW_PICKER_HEIGHT_PORTRAIT;
        }
    }
    
    aViewController.xConstraint = [NSLayoutConstraint constraintWithItem:aViewController.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    aViewController.yConstraint = [NSLayoutConstraint constraintWithItem:aViewController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    aViewController.widthConstraint = [NSLayoutConstraint constraintWithItem:aViewController.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    
    [rootViewController.view addConstraint:aViewController.xConstraint];
    [rootViewController.view addConstraint:aViewController.yConstraint];
    [rootViewController.view addConstraint:aViewController.widthConstraint];
    
    [rootViewController.view setNeedsUpdateConstraints];
    [rootViewController.view layoutIfNeeded];
    
    [rootViewController.view removeConstraint:aViewController.yConstraint];
    aViewController.yConstraint = [NSLayoutConstraint constraintWithItem:aViewController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeBottom multiplier:1 constant:-10];
    [rootViewController.view addConstraint:aViewController.yConstraint];
    
    [rootViewController.view setNeedsUpdateConstraints];
    
    CGFloat damping = 1.0f;
    CGFloat duration = 0.3f;
    if(!aViewController.disableBouncingWhenShowing) {
        damping = 0.6f;
        duration = 1.0f;
    }
    
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:damping initialSpringVelocity:1 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        aViewController.backgroundView.alpha = 1;
        
        [rootViewController.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

+ (void)dismissDateSelectionViewController:(EWSelectionViewController *)aViewController fromViewController:(UIViewController *)rootViewController {
    
    [rootViewController.view removeConstraint:aViewController.yConstraint];
    aViewController.yConstraint = [NSLayoutConstraint constraintWithItem:aViewController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    [rootViewController.view addConstraint:aViewController.yConstraint];
    
    [rootViewController.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        aViewController.backgroundView.alpha = 0;
        
        [rootViewController.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [aViewController willMoveToParentViewController:nil];
        [aViewController viewWillDisappear:YES];
        
        [aViewController.view removeFromSuperview];
        [aViewController removeFromParentViewController];
        
        [aViewController didMoveToParentViewController:nil];
        [aViewController viewDidDisappear:YES];
        
        [aViewController.backgroundView removeFromSuperview];
    }];
}

#pragma mark - Init and Dealloc
- (id)init {
    self = [super init];
    if(self) {
        [self setupUIElements];
    }
    return self;
}
-(id)initWithPickerDelegate:(id)vc;
{
    EWSelectionViewController *selectionVC = [[EWSelectionViewController alloc] init];
    selectionVC.picker.delegate =vc;
    selectionVC.picker.dataSource = vc;
    
    return selectionVC;
}
- (void)setupUIElements {
    //Instantiate elements
    self.titleLabelContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    
    self.nowButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.datePickerContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.picker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    
    self.cancelAndSelectButtonContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.cancelAndSelectButtonSeperator = [[UIView alloc] initWithFrame:CGRectZero];
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    //Add elements to their subviews
    [self.titleLabelContainer addSubview:self.titleLabel];
    
    [self.datePickerContainer addSubview:self.picker];
    
    [self.cancelAndSelectButtonContainer addSubview:self.cancelAndSelectButtonSeperator];
    [self.cancelAndSelectButtonContainer addSubview:self.cancelButton];
    [self.cancelAndSelectButtonContainer addSubview:self.selectButton];
    
    //Setup properties of elements
    self.titleLabelContainer.backgroundColor = [UIColor whiteColor];
    self.titleLabelContainer.layer.cornerRadius = 5;
    self.titleLabelContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = [UIColor grayColor];
    self.titleLabel.font = [UIFont systemFontOfSize:12];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    
    [self.nowButton setTitle:[EWSelectionViewController localizedTitleForNowButton] forState:UIControlStateNormal];
    [self.nowButton setTitleColor:[UIColor colorWithRed:0 green:122./255. blue:1 alpha:1] forState:UIControlStateNormal];
    [self.nowButton addTarget:self action:@selector(nowButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.nowButton.backgroundColor = [UIColor whiteColor];
    self.nowButton.layer.cornerRadius = 5;
    self.nowButton.clipsToBounds = YES;
    self.nowButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.datePickerContainer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    self.datePickerContainer.layer.cornerRadius = 5;
    self.datePickerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.picker.tintColor = [UIColor whiteColor];
    self.picker.alpha =    1;
    self.picker.layer.cornerRadius = 5;
    self.picker.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.cancelAndSelectButtonContainer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];

    self.cancelAndSelectButtonContainer.layer.cornerRadius = 5;
    self.cancelAndSelectButtonContainer.clipsToBounds = YES;
    self.cancelAndSelectButtonContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.cancelAndSelectButtonSeperator.backgroundColor = [UIColor lightGrayColor];
    self.cancelAndSelectButtonSeperator.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.cancelButton setTitle:[EWSelectionViewController localizedTitleForCancelButton] forState:UIControlStateNormal];
//    [self.cancelButton setTitleColor:[UIColor colorWithRed:0 green:122./255. blue:1 alpha:1] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [self.cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.layer.cornerRadius = 5;
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.selectButton setTitle:[EWSelectionViewController localizedTitleForSelectButton] forState:UIControlStateNormal];
//    [self.selectButton setTitleColor:[UIColor colorWithRed:0 green:122./255. blue:1 alpha:1] forState:UIControlStateNormal];
    [self.selectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [self.selectButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.selectButton.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
    self.selectButton.layer.cornerRadius = 5;
    self.selectButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.selectButton setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setupConstraints {
    UIView *pickerContainer = self.datePickerContainer;
    UIView *cancelSelectContainer = self.cancelAndSelectButtonContainer;
    UIView *seperator = self.cancelAndSelectButtonSeperator;
    UIButton *cancel = self.cancelButton;
    UIButton *select = self.selectButton;
    UIPickerView *picker = self.picker;
    UIView *labelContainer = self.titleLabelContainer;
    UILabel *label = self.titleLabel;
    UIButton *now = self.nowButton;
    
    NSDictionary *bindingsDict = NSDictionaryOfVariableBindings(cancelSelectContainer, seperator, pickerContainer, cancel, select, picker, labelContainer, label, now);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[pickerContainer]-(10)-|" options:0 metrics:nil views:bindingsDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[cancelSelectContainer]-(10)-|" options:0 metrics:nil views:bindingsDict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[pickerContainer]-(10)-[cancelSelectContainer(44)]-(0)-|" options:0 metrics:nil views:bindingsDict]];
    self.pickerHeightConstraint = [NSLayoutConstraint constraintWithItem:self.datePickerContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:EW_PICKER_HEIGHT_PORTRAIT];
    [self.view addConstraint:self.pickerHeightConstraint];
    
    [self.datePickerContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[picker]-(0)-|" options:0 metrics:nil views:bindingsDict]];
    [self.cancelAndSelectButtonContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[cancel]-(0)-[seperator(1)]-(0)-[select]-(0)-|" options:0 metrics:nil views:bindingsDict]];
    [self.cancelAndSelectButtonContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.cancelAndSelectButtonSeperator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.cancelAndSelectButtonContainer attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [self.datePickerContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[picker]-(0)-|" options:0 metrics:nil views:bindingsDict]];
    [self.cancelAndSelectButtonContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[cancel]-(0)-|" options:0 metrics:nil views:bindingsDict]];
    [self.cancelAndSelectButtonContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[seperator]-(0)-|" options:0 metrics:nil views:bindingsDict]];
    [self.cancelAndSelectButtonContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[select]-(0)-|" options:0 metrics:nil views:bindingsDict]];
    
    BOOL showTitle = self.titleLabel.text && self.titleLabel.text.length != 0;
    BOOL showNowButton = !self.hideNowButton;
    
    if(showNowButton) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[now]-(10)-|" options:0 metrics:nil views:bindingsDict]];
    }
    
    if(showTitle) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[labelContainer]-(10)-|" options:0 metrics:nil views:bindingsDict]];
        
        [self.titleLabelContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[label]-(10)-|" options:0 metrics:nil views:bindingsDict]];
        [self.titleLabelContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[label]-(10)-|" options:0 metrics:nil views:bindingsDict]];
    }
    
    if(showNowButton && showTitle) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[labelContainer]-(10)-[now(44)]-(10)-[pickerContainer]" options:0 metrics:nil views:bindingsDict]];
    } else if(showNowButton && !showTitle) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[now(44)]-(10)-[pickerContainer]" options:0 metrics:nil views:bindingsDict]];
    } else if(!showNowButton && showTitle) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[labelContainer]-(10)-[pickerContainer]" options:0 metrics:nil views:bindingsDict]];
    } else if(!showNowButton && !showTitle) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[pickerContainer]" options:0 metrics:nil views:bindingsDict]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.layer.masksToBounds = YES;
    
    if(self.titleLabel.text && self.titleLabel.text.length != 0)
        [self.view addSubview:self.titleLabelContainer];
    
    if(!self.hideNowButton)
        [self.view addSubview:self.nowButton];
    
    [self.view addSubview:self.datePickerContainer];
    [self.view addSubview:self.cancelAndSelectButtonContainer];
    
    [self setupConstraints];
    
    if(self.tintColor) {
        [self.nowButton setTitleColor:self.tintColor forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:self.tintColor forState:UIControlStateNormal];
        [self.selectButton setTitleColor:self.tintColor forState:UIControlStateNormal];
    }
    
    if(self.backgroundColor) {
        self.titleLabelContainer.backgroundColor = self.backgroundColor;
        self.nowButton.backgroundColor = self.backgroundColor;
        self.datePickerContainer.backgroundColor = self.backgroundColor;
        self.cancelAndSelectButtonContainer.backgroundColor = self.backgroundColor;
    }
    
    if(self.selectedBackgroundColor) {
        [self.nowButton setBackgroundImage:[self imageWithColor:self.selectedBackgroundColor] forState:UIControlStateHighlighted];
        [self.cancelButton setBackgroundImage:[self imageWithColor:self.selectedBackgroundColor] forState:UIControlStateHighlighted];
        [self.selectButton setBackgroundImage:[self imageWithColor:self.selectedBackgroundColor] forState:UIControlStateHighlighted];
    }
    
    if(!self.disableMotionEffects)
        [self addMotionEffects];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [super viewDidDisappear:animated];
    
    self.hasBeenDismissed = NO;
}

#pragma mark - Orientation
- (void)didRotate {
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            self.pickerHeightConstraint.constant = EW_PICKER_HEIGHT_LANDSCAPE;
        } else {
            self.pickerHeightConstraint.constant = EW_PICKER_HEIGHT_PORTRAIT;
        }
        
        [self.picker setNeedsUpdateConstraints];
        [self.picker layoutIfNeeded];
        
        [self.rootViewController.view setNeedsUpdateConstraints];
        __weak EWSelectionViewController *blockself = self;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [blockself.rootViewController.view layoutIfNeeded];
        } completion:^(BOOL finished) {
        }];
    }
}

#pragma mark - Helper
- (void)addMotionEffects {
    [self.view addMotionEffect:self.motionEffectGroup];
}

- (void)removeMotionEffects {
    [self.view removeMotionEffect:self.motionEffectGroup];
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Properties
- (void)setDisableMotionEffects:(BOOL)newDisableMotionEffects {
    if(_disableMotionEffects != newDisableMotionEffects) {
        _disableMotionEffects = newDisableMotionEffects;
        
        if(newDisableMotionEffects) {
            [self removeMotionEffects];
        } else {
            [self addMotionEffects];
        }
    }
}

- (UIMotionEffectGroup *)motionEffectGroup {
    if(!_motionEffectGroup) {
        UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        verticalMotionEffect.minimumRelativeValue = @(-10);
        verticalMotionEffect.maximumRelativeValue = @(10);
        
        UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        horizontalMotionEffect.minimumRelativeValue = @(-10);
        horizontalMotionEffect.maximumRelativeValue = @(10);
        
        _motionEffectGroup = [UIMotionEffectGroup new];
        _motionEffectGroup.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
    }
    
    return _motionEffectGroup;
}

- (UIView *)backgroundView {
    if(!_backgroundView) {
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        _backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewTapped:)];
        [_backgroundView addGestureRecognizer:tapRecognizer];
    }
    
    return _backgroundView;
}

- (void)setTintColor:(UIColor *)newTintColor {
    if(_tintColor != newTintColor) {
        _tintColor = newTintColor;
        
        [self.nowButton setTitleColor:newTintColor forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:newTintColor forState:UIControlStateNormal];
        [self.selectButton setTitleColor:newTintColor forState:UIControlStateNormal];
    }
}

- (void)setBackgroundColor:(UIColor *)newBackgroundColor {
    if(_backgroundColor != newBackgroundColor) {
        _backgroundColor = newBackgroundColor;
        
        self.titleLabelContainer.backgroundColor = newBackgroundColor;
        self.nowButton.backgroundColor = newBackgroundColor;
        self.datePickerContainer.backgroundColor = newBackgroundColor;
        self.cancelAndSelectButtonContainer.backgroundColor = newBackgroundColor;
    }
}

- (UIColor *)selectedBackgroundColor {
    if(!_selectedBackgroundColor) {
        self.selectedBackgroundColor = [UIColor colorWithWhite:230./255. alpha:1];
    }
    
    return _selectedBackgroundColor;
}

- (void)setSelectedBackgroundColor:(UIColor *)newSelectedBackgroundColor {
    if(_selectedBackgroundColor != newSelectedBackgroundColor) {
        _selectedBackgroundColor = newSelectedBackgroundColor;
        
        [self.nowButton setBackgroundImage:[self imageWithColor:newSelectedBackgroundColor] forState:UIControlStateHighlighted];
        [self.cancelButton setBackgroundImage:[self imageWithColor:newSelectedBackgroundColor] forState:UIControlStateHighlighted];
        [self.selectButton setBackgroundImage:[self imageWithColor:newSelectedBackgroundColor] forState:UIControlStateHighlighted];
    }
}

#pragma mark - Presenting
- (void)show {
    [self showWithSelectionHandler:nil];
}

- (void)showWithSelectionHandler:(EWSelectionBlock)selectionBlock {
    [self showWithSelectionHandler:selectionBlock andCancelHandler:nil];
}

- (void)showWithSelectionHandler:(EWSelectionBlock)selectionBlock andCancelHandler:(EWCancelBlock)cancelBlock {
    self.selectedDateBlock = selectionBlock;
    self.cancelBlock = cancelBlock;
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *currentViewController = keyWindow.rootViewController;
    
    while (currentViewController.presentedViewController) {
        currentViewController = currentViewController.presentedViewController;
    }
    
    [self showFromViewController:currentViewController];
}

- (void)showFromViewController:(UIViewController *)aViewController {
    if([aViewController isKindOfClass:[UITableViewController class]]) {
        if(aViewController.navigationController) {
            NSLog(@"Warning: -[RMDateSelectionViewController showFromViewController:] has been called with an instance of UITableViewController as argument. Trying to use the navigation controller of the UITableViewController instance instead.");
            aViewController = aViewController.navigationController;
        } else {
            NSLog(@"Error: -[RMDateSelectionViewController showFromViewController:] has been called with an instance of UITableViewController as argument. Showing the date selection view controller from an instance of UITableViewController is not possible due to some internals of UIKit. To prevent your app from crashing, showing the date selection view controller will be canceled.");
            return;
        }
    }
    
    self.rootViewController = aViewController;
    [EWSelectionViewController showDateSelectionViewController:self fromViewController:aViewController];
}

- (void)dismiss {
    [EWSelectionViewController dismissDateSelectionViewController:self fromViewController:self.rootViewController];
}

#pragma mark - Actions
- (IBAction)doneButtonPressed:(id)sender {
    if(!self.hasBeenDismissed) {
        self.hasBeenDismissed = YES;
        
        [self.delegate dateSelectionViewController:self];
        if (self.selectedDateBlock) {
            self.selectedDateBlock(self);
        }
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:0.1];
    }
}

- (IBAction)cancelButtonPressed:(id)sender {
    if(!self.hasBeenDismissed) {
        self.hasBeenDismissed = YES;
        
        [self.delegate dateSelectionViewControllerDidCancel:self];
        if (self.cancelBlock) {
            self.cancelBlock(self);
        }
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:0.1];
    }
}


- (IBAction)backgroundViewTapped:(UIGestureRecognizer *)sender {
    if(!self.backgroundTapsDisabled && !self.hasBeenDismissed) {
        self.hasBeenDismissed = YES;
        
        [self.delegate dateSelectionViewControllerDidCancel:self];
        if (self.cancelBlock) {
            self.cancelBlock(self);
        }
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:0.1];
    }
}

@end
