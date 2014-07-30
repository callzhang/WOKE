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

@interface EWSettingsViewController ()
{
    NSUInteger selectedCellNum;
    NSArray *ringtoneList ;
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
    [self setTitle:@"Preferences"];

    [self initData];
    [self initView];
}
-(void)viewWillDisappear:(BOOL)animated{
    me.preference = [preference mutableCopy];
    [EWDataStore save];
}
- (void)initData {
    //profile
    preference = [me.preference mutableCopy];
    settingGroup = settingGroupPreference;
    ringtoneList = ringtoneNameList
    
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
    [EWDataStore save];
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
            return 4;
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
    switch (settingGroup) {
        case settingGroupProfile: {
            cell= [self makeProfileCellInTableView:tableView];
            switch (indexPath.row){
                case 0: {
                    cell.textLabel.text = LOCALSTR(@"Name");
                    cell.detailTextLabel.text = me.name;
                }
                    break;
                case 1: {
                    cell.textLabel.text = LOCALSTR(@"Profile Picture");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.imageView.image = me.profilePic;
                }
                    break;
                case 2: {
                    cell.textLabel.text = LOCALSTR(@"ID");
                    cell.detailTextLabel.text = me.username;
                }
                    break;
                case 3: {
                    cell.textLabel.text = LOCALSTR(@"Facebook ID");
                    cell.detailTextLabel.text = me.facebook;
                }
                    break;
                case 4:{
                    cell.textLabel.text = LOCALSTR(@"Weibo ID");
                    cell.detailTextLabel.text = me.weibo;
                }
                    break;
                case 5:{
                    cell.textLabel.text = LOCALSTR(@"City");
                    cell.detailTextLabel.text = me.city;
                }
                    break;
                case 6: {
                    cell.textLabel.text = LOCALSTR(@"Region");
                    cell.detailTextLabel.text = me.region;
                }
                    break;
                case 7:{
                    cell.textLabel.text = LOCALSTR(@"Log out");
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case settingGroupPreference: {
            cell= [self makePrefCellInTableView:tableView];
            switch (indexPath.row){//options[indexPath.row]
                case 0: {
                    cell.textLabel.text = LOCALSTR(@"Alarm sound");
                    NSArray *fileString = [preference[@"DefaultTone"] componentsSeparatedByString:@"."];
                    NSString *file = [fileString objectAtIndex:0];
                    cell.detailTextLabel.text = file;
                    break;
                }
                case 1: {
                    cell.textLabel.text = LOCALSTR(@"Who can send me voice");
                    cell.detailTextLabel.text = preference[@"SocialLevel"];
                }
                    break;
                case 2: {
                    cell.textLabel.text = LOCALSTR(@"Bed time notification");
                    //switch
                    UISwitch *bedTimeNotifSwitch = [[UISwitch alloc] init];
                    bedTimeNotifSwitch.tintColor = [UIColor grayColor];
                    bedTimeNotifSwitch.onTintColor = [UIColor greenColor];
                    bedTimeNotifSwitch.on = (BOOL)preference[@"BedTimeNotification"];
                    bedTimeNotifSwitch.tag = 3;
                    
                    [bedTimeNotifSwitch addTarget:self action:@selector(OnBedTimeNotificationSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = bedTimeNotifSwitch;
                    //cell.detailTextLabel.text = @"";

                    
                                    }
                    break;
                case 3: {
                    cell.textLabel.text = LOCALSTR(@"Sleep duration");
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ hours", preference[@"SleepDuration"]];
                    
                                    }
                    break;
                case 4: {
                    
                    cell.textLabel.text = LOCALSTR(@"Download connection");
                    cell.detailTextLabel.text = preference[@"DownloadConnection"];

                }
                    break;
                case 5: {
                    cell.textLabel.text = LOCALSTR(@"Privacy");
                    cell.detailTextLabel.text = preference[@"PrivacyLevel"];
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case settingGroupAbout: {
            cell= [self makeAboutCellInTableView:tableView];
            switch (indexPath.section) {
                case 0: {
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    cell.backgroundColor = kCustomWhite;
                    cell.textLabel.textColor = kCustomGray;
                    cell.textLabel.text = [NSString stringWithFormat:@"关于%@", LOCALSTR(@"EarlyWorm")];
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", LOCALSTR(@"Setting_Version"), kAppVersion];
                }
                    break;
                default:
                    break;
            }
        }
        break;
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    selectedCellNum = indexPath.row;
    if (settingGroup == settingGroupProfile) {
        switch ( indexPath.row) {
            case 1:
                NSLog(@"Full screen image:???");
                break;
            case 7:{
                //alert
                [[[UIAlertView alloc] initWithTitle:@"Log out" message:@"Log out?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil] show];
                            }
                break;
            
            default:
                break;
        }
        
    }else if (settingGroup == settingGroupPreference){
        switch (indexPath.row) {
            case 0:  {//sound selection
//                ringtoneVC = [[EWRingtoneSelectionViewController alloc] init];
//                ringtoneVC.delegate = self;
//                NSArray *ringtones = ringtoneNameList;
//                ringtoneVC.selected = [ringtones indexOfObject:preference[@"DefaultTone"]];
//           
//                
//                [self.navigationController pushViewController:ringtoneVC animated:YES];
                
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

                
            }
                break;
            case 1:  {
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
            }
                break;
            case 3:{
                
            }
            case 4:
            {
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

            }
                break;
            default:
                break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)OnBedTimeNotificationSwitchChanged:(UISwitch *)sender{
    [preference setObject:@(sender.on) forKey:kBedTimeNotification];
    me.preference = preference;
    [EWDataStore save];
    
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
    switch (selectedCellNum) {
        case 0:
            return ringtoneList.count;
        case 1:
            return socialLevels.count;
            break;
        case 3:
            return sleepDurations.count;
        default:
            break;
    }
    return 0;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (selectedCellNum) {
        case 0:{
        NSString *tone = [ringtoneList objectAtIndex:row];
        [AVManager.sharedManager playSoundFromFile:tone];
        }
            break;
            
        default:
            break;
    }
    
}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, 44)];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
    
    NSString *titleString = @"";
    switch (selectedCellNum) {
        case 0:{
            
            
            titleString = ringtoneList[row];

        }
            break;
        case 1:{
            titleString = socialLevels[row];
        }
            break;
        case 3:{
            titleString = [NSString stringWithFormat:@"%@ hours",sleepDurations[row]];
        }
            break;
        default:
            break;
    }
    label.text = titleString;
    return label; 
}
@end
