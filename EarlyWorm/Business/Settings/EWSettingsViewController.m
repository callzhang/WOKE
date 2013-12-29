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

//backend
#import "StackMob.h"

@interface EWSettingsViewController ()
//@property (strong, nonatomic) NSArray *options;
@property (strong, nonatomic) NSMutableDictionary *preference;

@end

@interface EWSettingsViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>
@end

@implementation EWSettingsViewController
@synthesize preference;

- (id)init {
    self = [super init];
    if (self) {
        self.title = LOCALSTR(@"Settings");
        self.tabBarItem.image = [UIImage imageNamed:@"pref_icon.png"];
        
        self.hidesBottomBarWhenPushed = NO;
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initData) name:kPersonLoggedIn object:nil];
        
        //core data
        context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initData];
    [self initView];
}

- (void)initData {
    //profile
    _person = [EWPersonStore sharedInstance].currentUser;
    preference = [_person.preference mutableCopy];
    //options
    //options = @{@"Offine Ringtone", @"Social interaction", @"Download connection", @"Bed time notification", @9.0, @"Privacy information"};
    //table view
    cellIdentifier = @"CellIdentifier";
}

- (void)initView {
    
    self.view.backgroundColor = kCustomGray;
    
    //UISegmentedControl
    UISegmentedControl *settingGroupController = [[UISegmentedControl alloc] initWithItems: @[@"Profile", @"Preference", @"About"]];
    settingGroupController.selectedSegmentIndex = 0;
    //settingGroupController.segmentedControlStyle = UISegmentedControlStyleBar;
    [settingGroupController addTarget:self
                               action:@selector(changeSettingGroup:)
                     forControlEvents:UIControlEventValueChanged];
    settingGroup = settingGroupProfile;
    self.navigationItem.titleView = settingGroupController;
    
    //TableView
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.backgroundView = nil;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
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

#pragma mark - RingtongSelectionDelegate
- (void)ViewController:(EWRingtoneSelectionViewController *)controller didFinishSelectRingtone:(NSString *)tone{
    //set ringtone
    preference[@"tone"] = tone;
    _person.preference = preference;
    [context saveOnSuccess:^{
        //
    } onFailure:^(NSError *error) {
        [NSException raise:@"Error in saving preference" format:@"Reason: %@", error.description];
    }];
}

@end

@implementation EWSettingsViewController (UITableView)


#pragma mark - setting group change
-(void)changeSettingGroup:(id)sender{
    settingGroup = [sender selectedSegmentIndex];
    NSLog(@"Setting group switched to %d", settingGroup);
    //refresh table
    [_tableView reloadData];
}

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
            return 6;
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
                    cell.detailTextLabel.text = _person.name;
                }
                    break;
                case 1: {
                    cell.textLabel.text = LOCALSTR(@"Profile Picture");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.imageView.image = _person.profilePic;
                }
                    break;
                case 2: {
                    cell.textLabel.text = LOCALSTR(@"ID");
                    cell.detailTextLabel.text = _person.username;
                }
                    break;
                case 3: {
                    cell.textLabel.text = LOCALSTR(@"Facebook ID");
                    cell.detailTextLabel.text = _person.username;
                }
                    break;
                case 4:{
                    cell.textLabel.text = LOCALSTR(@"Weibo ID");
                    cell.detailTextLabel.text = _person.weibo;
                }
                    break;
                case 5:{
                    cell.textLabel.text = LOCALSTR(@"City");
                    cell.detailTextLabel.text = _person.city;
                }
                    break;
                case 6: {
                    cell.textLabel.text = LOCALSTR(@"Region");
                    cell.detailTextLabel.text = _person.region;
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
                    cell.textLabel.text = LOCALSTR(@"Offine Ringtone");
                    NSArray *fileString = [preference[@"tone"] componentsSeparatedByString:@"."];
                    NSString *file = [fileString objectAtIndex:0];
                    cell.detailTextLabel.text = file;
                    break;
                }
                case 1: {
                    cell.textLabel.text = LOCALSTR(@"Social interaction");
                    cell.detailTextLabel.text = preference[@"SocialLevel"];
                }
                    break;
                case 2: {
                    cell.textLabel.text = LOCALSTR(@"Download connection");
                    cell.detailTextLabel.text = preference[@"DownloadConnection"];
                }
                    break;
                case 3: {
                    cell.textLabel.text = LOCALSTR(@"Bed time notification");
                    //switch
                    UISwitch *bedTimeNotifSwitch = [[UISwitch alloc] init];
                    bedTimeNotifSwitch.on = (BOOL)preference[@"BedTimeNotification"];
                    bedTimeNotifSwitch.tag = 3;
                    bedTimeNotifSwitch.onTintColor = kCustomGray;
                    [bedTimeNotifSwitch addTarget:self action:@selector(OnBedTimeNotificationSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = bedTimeNotifSwitch;
                    //cell.detailTextLabel.text = @"";
                }
                    break;
                case 4: {
                    cell.textLabel.text = LOCALSTR(@"Sleep duration");
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ hours", preference[@"SleepDuration"]];
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
    if (settingGroup == settingGroupProfile) {
        switch ( indexPath.row) {
            case 1:
                NSLog(@"Full screen image:???");
                break;
            case 7:{
                //log out
                [[SMClient defaultClient] logoutOnSuccess:^(NSDictionary *result) {
                    NSLog(@"Successfully logged out");
                    //present first time vc
                    EWLogInViewController *controller = [[EWLogInViewController alloc] init];
                    [self presentViewController:controller animated:YES completion:NULL];
                } onFailure:^(NSError *error) {
                    [NSException raise:@"Error in logging out" format:@"Reason: %@", error.description];
                }];
            }
                break;
                
            default:
                break;
        }
        
    }else if (settingGroup == settingGroupPreference){
        switch (indexPath.row) {
            case 0:  {//sound selection
                ringtoneVC = [[EWRingtoneSelectionViewController alloc] init];
                ringtoneVC.delegate = self;
                NSArray *ringtones = ringtoneNameList;
                ringtoneVC.selected = [ringtones indexOfObject:preference[@"tone"]];
                [self.navigationController pushViewController:ringtoneVC animated:YES];
            }
                break;
            default:
                break;
        }
    }
}

- (void)OnBedTimeNotificationSwitchChanged:(UISwitch *)sender{
    [_person.preference setObject:@(sender.on) forKey:@"BedTimeNotification"];
    if (sender.on == YES) {
        //schedule night notification
    }else{
        //cancel night notification
    }
}

@end
