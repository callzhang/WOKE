//
//  EWSocialViewController.m
//  EarlyWorm
//
//  Created by shenslu on 13-7-11.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWSocialViewController.h"

// Util
#import "NSDate+Extend.h"
#include <stdlib.h>

// View
#import "EWGroupCell.h"
#import "EWGroupStore.h"
#import "EWGroup.h"

// Model
#import "EWPersonStore.h"
#import "EWPersonCell.h"
#import "EWPerson.h"

#import "EWTaskItem.h"
#import "EWTaskStore.h"

// Business
#import "EWDetailPersonViewController.h"

//backend
#import "StackMob.h"

@interface EWSocialViewController ()

@end

@implementation EWSocialViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = LOCALSTR(@"Around Me");
        self.tabBarItem.image = [UIImage imageNamed:@"social_icon.png"];
        
        self.hidesBottomBarWhenPushed = NO;
        //data
        context = [[SMClient defaultClient].coreDataStore contextForCurrentThread];
        
        //listener
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadData) name:kPersonLoggedIn object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //default page
    socialList = socialViewNews;
    
    //progress hud
    /*
    refreshHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:refreshHUD];
    refreshHUD.delegate = self;
     */
    
    //UISegmentedControl
    UISegmentedControl *taskGroupController = [[UISegmentedControl alloc] initWithItems:@[@"News", @"Around Me", @"Groups"]];
    taskGroupController.selectedSegmentIndex = 0;
    //taskGroupController.segmentedControlStyle = UISegmentedControlStyleBar;
    [taskGroupController addTarget:self
                            action:@selector(changeTaskGroup:)
                  forControlEvents:UIControlEventValueChanged];
    
    self.navigationItem.titleView = taskGroupController;
    //nav item
    [self changeTaskGroup:taskGroupController];
    
    //register nib
    //load MediaViewCell
    UINib *groupNib = [UINib nibWithNibName:@"EWGroupCell" bundle:nil];
    [self.tableView registerNib:groupNib forCellReuseIdentifier:@"GroupCell"];
    
    // person Cell
    UINib *personNib = [UINib nibWithNibName:@"EWPersonCell" bundle:nil];
    [self.tableView registerNib:personNib forCellReuseIdentifier:@"PersonCell"];
    
    //data
    [self loadData];

}

- (void)viewWillAppear:(BOOL)animated{
    //[super viewWillAppear:animated]; no need to call super
    [self loadData];
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //    [self loadData];
    //});
}

- (void)loadData{
    me = [EWPersonStore sharedInstance].currentUser;
    NSSet *friendsSet = me.friends;
    friends = [friendsSet allObjects];
    NSMutableSet *everyoneSet = [NSMutableSet setWithArray:[[EWPersonStore sharedInstance] everyone]];
    [everyoneSet minusSet:me.friends];
    everyone = [everyoneSet allObjects];//exclude friends
    nNews = friends.count; //TODO: currently the only news if friends' alarm time
    nAroundMe = (everyone.count>20) ? 20:everyone.count; //arbitrage number
    nGroup = 1; //wakeup together group
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
    
    //save
    //[EWPersonStore.sharedInstance save];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UI events
-(void)changeTaskGroup:(id)sender{
    socialList = [sender selectedSegmentIndex];
    if (socialList == socialViewNews) {
        //nav item
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onNewActions)];
    }else if (socialList == socialViewEveryone) {
        //nav item
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onSearchPerson)];
    }else if(socialList == socialViewGroups){
        //nav item
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onGroup)];
    }
    NSLog(@"Task group switched to %d", socialList);
    
    //refresh table
    [self.tableView reloadData];
}


//page switch
- (void)onNewsActions{
    refreshHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSLog(@"News page refresh");
}



- (void)onSearchPerson{
    refreshHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    
    
}
/*
- (void)onAddTask {
    EWAddTaskViewController *controller = [[EWAddTaskViewController alloc] init];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    [self presentViewController:navigationController animated:YES completion:^{}];
}
*/
- (void)onSearchGroup{
    refreshHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSLog(@"Group page");
}
@end

@implementation EWSocialViewController (UITableView)

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return @"Friends";
    }else if (section == 1){
        return @"Everyone";
    }
    return nil;
}

#pragma mark - Cell Maker

- (UITableViewCell *)makeNewsCellInTableView:(UITableView *)tableView{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewsCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"NewsCell"];
    }
    return cell;
}

- (EWGroupCell *)makeGroupCellInTableView:(UITableView *)tableView {
    EWGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupCell"];
    if (!cell) {
        cell = [[EWGroupCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"GroupCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        // set backgroundColor
        cell.contentView.backgroundColor = kCustomLightGray;
    }
    return cell;
}

- (EWPersonCell *)makePersonCell:(UITableView *)tableView{
    EWPersonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PersonCell"];
    if (!cell) {
        cell = [[EWPersonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PersonCell"];
        // set backgroundColor
        cell.contentView.backgroundColor = [UIColor whiteColor];
        cell.backgroundView.backgroundColor = kCustomLightGray;
        cell.backgroundColor = kCustomLightGray;
    }
    return  cell;
}


#pragma mark - DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    switch (socialList) {
        case socialViewNews:
            return 1;
            break;
        case socialViewEveryone:
            return 2;
            break;
        case socialViewGroups:
            return 1;
            break;
        default:
            break;
    }
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (socialList){
        case socialViewNews:
            return nNews;
            break;
        case socialViewEveryone:
            if (section == 0) {
                return friends.count;
            }else if(section == 1){
                return nAroundMe;
            }
            return 0;
            break;
        case socialViewGroups:
            return nGroup;
            break;
        default:
            break;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (socialList == socialViewEveryone) {
        return 120;
    }
    else if (socialList == socialViewGroups) {
        return 90;
    }
    return self.tableView.rowHeight;
}

//cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (socialList == socialViewNews) {
        UITableViewCell *cell = [self makeNewsCellInTableView:tableView];
        EWPerson *person = [friends objectAtIndex:indexPath.row];
        EWTaskItem *task = [EWTaskStore.sharedInstance nextTaskAtDayCount:0 ForPerson:person];
        //name
        if (person.name) {
            cell.textLabel.text = person.name;
        } else {
            cell.textLabel.text = person.username;
        }
        //profile pic
        if (person.profilePic) {
            cell.imageView.image = person.profilePic;
        }else{
            cell.imageView.image = [UIImage imageNamed:@"profile.png"];
        }
        //alarm
        if (task) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Next alarm: %@", [task.time date2detailDateString]];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }else{
            cell.detailTextLabel.text = @"No alarm set for tomorrow";
        }
        return cell;
    }else if (socialList == socialViewEveryone) {
        EWPersonCell *cell = [self makePersonCell:tableView];
        EWPerson *person;
        if (indexPath.section == 0) {
            //friends list
            person = [friends objectAtIndex:indexPath.row];
        }else if(indexPath.section == 1){
            //everyone list
            person = [everyone objectAtIndex:indexPath.row];
        }
        
        EWTaskItem *task = [EWTaskStore.sharedInstance nextTaskAtDayCount:0 ForPerson:person];
        // Configure the cell...
        //name
        if (person.name) {
            cell.name.text = person.name;
        } else {
            cell.name.text = person.username;
        }
        //image
        if (person.profilePic) {
            cell.image.image = person.profilePic;
        }else{
            cell.image.image = [UIImage imageNamed:@"profile.png"];
        }
        cell.location.text = person.city;
        //Next activity
        if (task) {
            cell.time.text = [task.time date2String];
            cell.description.text = task.statement;
        }
        return cell;
    }
    else if (socialList == socialViewGroups) {
        EWGroupCell *cell = [self makeGroupCellInTableView:tableView];
        //EWGroup *group = [EWGroupStore.sharedInstance autoGroup];
        //cell.group = group;
        return cell;
    }
    return nil;
}

#pragma mark - delegate
- (void)tableView:(UITableViewController *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (socialList == socialViewNews) {
        //send voice tone
        //unsigned r = arc4random() % 6;
    } else if (socialList == socialViewEveryone) {
        //view person
        
        EWDetailPersonViewController *controller = [[EWDetailPersonViewController alloc] init];
        if (indexPath.section == 0) {
            controller.person = friends[indexPath.row];
        }else if (indexPath.section == 1){
            controller.person = everyone[indexPath.row];
        }
        
        
        [self.navigationController pushViewController:controller animated:YES];
        
    }
    else if(socialList == socialViewGroups){
        //
    }
}

@end
