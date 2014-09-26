//
//  EWSettingsViewController.m
//  EarlyWorm
//
//  Created by shenslu on 13-7-28.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWSettingsViewController.h"
#import "EWPerson.h"
#import "EWPersonStore.h"
#import "EWMediaViewCell.h"
#import "EWFirstTimeViewController.h"
#import "EWLogInViewController.h"
#import "EWUserManagement.h"
#import "EWSelectionViewController.h"
#import "EWTaskStore.h"
#import "RMDateSelectionViewController.h"
#import "AVManager.h"

static const NSArray *sleepDurations;
static const NSArray *socialLevels;
static const NSArray *pref;

@interface EWSettingsViewController ()
{
    NSString *selectedCellTitle;
    NSArray *ringtoneList;
}
//@property (strong, nonatomic) NSArray *options;
@property (strong, nonatomic) NSMutableDictionary *preference;

@end

@interface EWSettingsViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>
@end
@interface EWSelectionViewController()<UIPickerViewDataSource,UIPickerViewDelegate,EWSelectionViewControllerDelegate>

@end
@implementation EWSettingsViewController
@synthesize preference;


- (void)viewDidLoad {
    [super viewDidLoad];
    sleepDurations = @[@6, @6.5, @7.5, @8, @8.5, @9, @9.5, @10, @10.5, @11, @11.5, @12];
    socialLevels = @[kSocialLevelFriends, kSocialLevelEveryone];
    pref = @[@"Morning tone", @"Bed time notification", @"Sleep duration", @"Log out", @"About"];
    
    [self setTitle:@"Preferences"];

    [self initData];
    [self initView];
}
-(void)viewWillDisappear:(BOOL)animated{
    me.preference = [preference mutableCopy];
    [EWSync save];
}
- (void)initData {
    //profile
    preference = [me.preference mutableCopy]?:[kUserDefaults mutableCopy];
    settingGroup = settingGroupPreference;
    ringtoneList = ringtoneNameList;
    
}

- (void)initView {
    self.view.backgroundColor = [UIColor clearColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"More Button"] style:UIBarButtonItemStylePlain target:self action:@selector(about:)];
    
    //TableView
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.backgroundView = nil;
    _tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.1];
    if ([[UIDevice currentDevice].systemVersion doubleValue]>=7.0f) {
        
        _tableView.separatorInset = UIEdgeInsetsZero;// 这样修改，那条线就会占满
        
    }
    
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.view addSubview:_tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//refrash data after edited
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_tableView reloadData];
}

#pragma mark - IBAction
- (IBAction)onDone:(id)sender{
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
}

- (IBAction)about:(id)sender{
    //
}

#pragma mark - RingtongSelectionDelegate
- (void)ViewController:(EWRingtoneSelectionViewController *)controller didFinishSelectRingtone:(NSString *)tone{
    //set ringtone
    preference[@"DefaultTone"] = tone;
    me.preference = preference;
    [EWSync save];
}

@end

@implementation EWSettingsViewController (UITableView)


//#pragma mark - setting group change
//-(void)changeSettingGroup:(id)sender{
//    settingGroup = (settingGroupList)[sender selectedSegmentIndex];
//    NSLog(@"Setting group switched to %d", settingGroup);
//    //refresh table
//    [_tableView reloadData];
//}

#pragma mark - Cell Maker

- (UITableViewCell *)makeProfileCellInTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"profileCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"profileCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.backgroundColor = kCustomLightGray;
    }
    return cell;
}

- (UITableViewCell *)makePrefCellInTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingPreferenceCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"settingPreferenceCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.backgroundColor = kCustomLightGray;
    }
    return cell;
}

- (UITableViewCell *)makeAboutCellInTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingAboutCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"settingAboutCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.textColor = kCustomGray;
        cell.backgroundColor = kCustomLightGray;
    }
    return cell;
}

#pragma mark - DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    switch (settingGroup) {
        case settingGroupProfile: {
            return 1;
        }
        break;
        case settingGroupPreference: {
            return 1;
        }
        break;
        default: {//settingGroupAbout
            return 1;
        }
        break;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (settingGroup) {
        case settingGroupProfile:
            return 8;
            break;
        case settingGroupPreference:
            return pref.count;
            break;
        default: //settingGroupAbout
            return 1;
            break;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    cell= [self makePrefCellInTableView:tableView];
    
    NSString *title = LOCALSTR(pref[indexPath.row]);
    cell.textLabel.text = title;
    if ([title isEqualToString:@"Morning tone"]) {
        NSArray *fileString = [preference[@"DefaultTone"] componentsSeparatedByString:@"."];
        NSString *file = [fileString objectAtIndex:0];
        cell.detailTextLabel.text = file;

    }else if ([title isEqualToString:@"Bed time notification"]){
        //switch
        UISwitch *bedTimeNotifSwitch = [[UISwitch alloc] init];
        bedTimeNotifSwitch.tintColor = [UIColor grayColor];
        bedTimeNotifSwitch.onTintColor = [UIColor greenColor];
        bedTimeNotifSwitch.on = (BOOL)preference[@"BedTimeNotification"];
        bedTimeNotifSwitch.tag = 3;
        
        [bedTimeNotifSwitch addTarget:self action:@selector(OnBedTimeNotificationSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = bedTimeNotifSwitch;
        //cell.detailTextLabel.text = @"";
    }else if ([title isEqualToString:@"Sleep duration"]){
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ hours", preference[@"SleepDuration"]];
    }else if ([title isEqualToString:@"Log out"]){
        //
    }else if ([title isEqualToString:@"About"]){
        //
    }

    return cell;
}

#pragma mark - Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //pref = @[@"Morning tone", @"Bed time notification", @"Sleep duration", @"Log out", @"About"];
    NSString *title = pref[indexPath.row];
    selectedCellTitle = title;
    if ([title isEqualToString:@"Morning tone"]){
                
        EWSelectionViewController *selectionVC = [[EWSelectionViewController alloc] initWithPickerDelegate:self];
        selectionVC.hideNowButton = YES;
        //You can enable or disable bouncing and motion effects
        //dateSelectionVC.disableBouncingWhenShowing = YES;
        //dateSelectionVC.disableMotionEffects = YES;
        //                    [selectionVC show];
        
        [selectionVC showWithSelectionHandler:^(EWSelectionViewController *vc) {
            NSUInteger row =[vc.picker selectedRowInComponent:0];
            UILabel *titleLabel = (UILabel *)[vc.picker viewForRow:row forComponent:0];
            self.preference[@"DefaultTone"] = titleLabel.text;
            [_tableView reloadData];
            [[AVManager sharedManager] stopAllPlaying];
            
        } andCancelHandler:^(EWSelectionViewController *vc) {
            [[AVManager sharedManager] stopAllPlaying];
            NSLog(@"Date selection was canceled (with block)");
            
        }];

        
    }else if ([title isEqualToString:@"Social"]){//depreciated
        EWSelectionViewController *selectionVC = [[EWSelectionViewController alloc] initWithPickerDelegate:self];
        selectionVC.hideNowButton = YES;
        //You can enable or disable bouncing and motion effects
        //dateSelectionVC.disableBouncingWhenShowing = YES;
        //dateSelectionVC.disableMotionEffects = YES;
//                    [selectionVC show];
    
        [selectionVC showWithSelectionHandler:^(EWSelectionViewController *vc) {
            NSUInteger row =[vc.picker selectedRowInComponent:0];
            NSString *level = socialLevels[row];
            self.preference[@"SocialLevel"] = level;
            [_tableView reloadData];
            NSLog(@"Successfully selected date: %ld (With block)",(long)[vc.picker selectedRowInComponent:0]);
            
       } andCancelHandler:^(EWSelectionViewController *vc) {
           
           NSLog(@"Date selection was canceled (with block)");

        }];

    }else if ([title isEqualToString:@"Sleep duration"]){
        EWSelectionViewController *selectionVC = [[EWSelectionViewController alloc] initWithPickerDelegate:self];
        selectionVC.hideNowButton = YES;
        
        //You can enable or disable bouncing and motion effects
        //dateSelectionVC.disableBouncingWhenShowing = YES;
        //dateSelectionVC.disableMotionEffects = YES;
//                [selectionVC show];
        [selectionVC showWithSelectionHandler:^(EWSelectionViewController *vc) {
            NSUInteger row =[vc.picker selectedRowInComponent:0];
            
            float d = [(NSNumber *)sleepDurations[row] floatValue];
            float d0 = [(NSNumber *)preference[kSleepDuration] floatValue];
            if (d != d0) {
                NSLog(@"Sleep duration changed from %f to %f", d0, d);
                preference[kSleepDuration] = @(d);
                me.preference = preference.copy;
                [_tableView reloadData];
                [EWTaskStore updateSleepNotification];
            }
            

            } andCancelHandler:^(EWSelectionViewController *vc) {
                NSLog(@"Date selection was canceled (with block)");

        }];

    }else if ([title isEqualToString:@"Log out"]){
        
        [[[UIAlertView alloc] initWithTitle:@"Log out" message:@"Do you want to log out?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Log out", nil] show];
        
    }else if ([title isEqualToString:@"About"]){
        
        NSString *v = kAppVersion;
        NSString *context = [NSString stringWithFormat:@"Woke \n Version: %@ \n WokeAlarm.com", v];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"About" message:context delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo200"]];
        image.frame = CGRectMake(200, 50, 80, 80);
        [alert addSubview:image];
        [alert show ];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)OnBedTimeNotificationSwitchChanged:(UISwitch *)sender{
    [preference setObject:@(sender.on) forKey:kBedTimeNotification];
    me.preference = preference;
    [EWSync save];
    
    //schedule sleep notification
    if (sender.on == YES) {
        [EWTaskStore updateSleepNotification];
    }else{
        [EWTaskStore cancelSleepNotification];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if ([alertView.title isEqualToString:@"Log out"]) {
        if (buttonIndex == 1) {
            [self dismissViewControllerAnimated:YES completion:^{
                //log out
                [EWUserManagement logout];
            }];
            
        }
    }

}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
}

@end
@implementation EWSettingsViewController (UIPickView)
#pragma mark - PickDelegate&&DateSource 

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ([selectedCellTitle isEqualToString:@"Morning tone"]) {
        return ringtoneList.count;
    }else if ([selectedCellTitle isEqualToString:@"Sleep duration"]) {
        return sleepDurations.count;
    }
    return 0;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ([selectedCellTitle isEqualToString:@"Morning tone"]) {
        NSString *tone = [ringtoneList objectAtIndex:row];
        [AVManager.sharedManager playSoundFromFile:tone];
    }
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, 44)];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
    
    NSString *titleString = @"";
    
    if ([selectedCellTitle isEqualToString:@"Morning tone"]) {
        titleString = ringtoneList[row];
    }else if ([selectedCellTitle isEqualToString:@"Sleep duration"]) {
        titleString = [NSString stringWithFormat:@"%@ hours",sleepDurations[row]];
    }
    
    label.text = titleString;
    return label; 
}
@end
