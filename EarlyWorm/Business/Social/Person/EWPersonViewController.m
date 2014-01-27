//
//  EWPersonViewController.m
//  EarlyWorm
//
//  Created by Lei on 9/5/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWPersonViewController.h"
#import "StackMob.h"
// Util
#import "EWUIUtil.h"
#import "MBProgressHUD.h"

// Model
#import "EWPerson.h"
#import "EWTaskItem.h"
#import "EWAlarmItem.h"
#import "EWMediaItem.h"
#import "NSDate+Extend.h"

//manager
#import "EWTaskStore.h"
#import "EWAlarmManager.h"
#import "EWPersonStore.h"
#import "EWMediaStore.h"
#import "EWStatisticsManager.h"

//view
#import "EWRecordingViewController.h"
#import "EWLogInViewController.h"

@interface EWPersonViewController (UITableView) <UITableViewDataSource, UITableViewDelegate>

@end


@implementation EWPersonViewController
@synthesize person, tableView;


- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn) name:kPersonLoggedIn object:nil];
    if (person) {
        [self initData];
        [self initView];
    }
    
}


- (void)initData {
    tasks = [[EWTaskStore sharedInstance] pastTasksByPerson:person];
    tasks = [tasks sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
    stats = [[EWStatisticsManager alloc] init];
    stats.person = person;
}



- (void)setPerson:(EWPerson *)p{
    person = p;
    [self initData];
    
    
}

- (void)initView {
    if (person == currentUser && !person.facebook) {
        self.loginBtn.alpha = 1;
    }else{
        self.loginBtn.alpha = 0;
    }
    //========table for tasks========
    
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.backgroundView = nil;
    
    //======= UI =======
    if (person) {
        [tableView reloadData];
        //UI
        self.profilePic.image = person.profilePic;
        self.name.text = person.name;
        self.location.text = person.city;
        
        [self.friends setTitle:[NSString stringWithFormat:@"%d", person.friends.count] forState:UIControlStateNormal];
        [self.aveTime setTitle:[NSString stringWithFormat:@"%d\"", [stats.aveWakeupTime integerValue]] forState:UIControlStateNormal];
        [self.achievements setTitle:[NSString stringWithFormat:@"%d", person.achievements.count] forState:UIControlStateNormal];
        
        EWTaskItem *t = tasks.firstObject;
        if (person.statement) {
            self.statement.text = person.statement;
        }else if (t.statement){
            self.statement.text = t.statement;
        }else{
            self.statement.text = @"No statement written by this owner";
        }
        
        [self.view setNeedsDisplay];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self initView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UI Events
- (IBAction)extProfile:(id)sender{
    [self.view setNeedsDisplay];
    NSLog(@"Info clicked");
}

- (IBAction)close:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)login:(id)sender {
    EWLogInViewController *loginVC = [[EWLogInViewController alloc] init];
    [loginVC loginInBackground];
}

- (void)addPerson{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add friend"
                                message:[NSString stringWithFormat:@"Add %@ as your friend?", person.name]
                                delegate:self
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:@"Cancel", nil];
    [alert show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if ([alertView.title isEqualToString:@"Add friend"]) {
        switch (buttonIndex) {
            case 0:
            {
                //OK
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                [currentUser addFriendsObject:person];
                [context saveOnSuccess:^{
                    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                    hud.mode = MBProgressHUDModeCustomView;
                    hud.labelText = @"Added";
                    [hud hide:YES afterDelay:1.5];
                } onFailure:^(NSError *error) {
                    [NSException raise:@"Error saving friendship" format:@"Reason: %@", error.description];
                }];
            }
                break;
                
            default:
                break;
        }
    }else if ([alertView.title isEqualToString:@"Unfriend"]){
        if (buttonIndex == 0) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [currentUser removeFriendedObject:person];
            [context saveOnSuccess:^{
                hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                hud.mode = MBProgressHUDModeCustomView;
                hud.labelText = @"Unfriended";
                [hud hide:YES afterDelay:1.5];
            } onFailure:^(NSError *error) {
                [NSException raise:@"Error saving friendship" format:@"Reason: %@", error.description];
            }];
        }
    }
}

- (void)unfriend{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unfriend"
                                                    message:[NSString stringWithFormat:@"Really unfriend %@?", person.name]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"Cancel", nil];
    [alert show];
}

@end



#pragma mark - TableView DataSource

@implementation EWPersonViewController(UITableView)
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    EWTaskItem *t = tasks[section];
    return [t.time date2MMDD];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //alarm shown in sections
    return tasks.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;//TODO
}

/*
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    NSInteger r = 30;
    CGRect rect = CGRectMake(0, 0, r, r);
    UIView *circleHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, r, r)];
 
//    circleHeader.alpha = 0.5;
//    circleHeader.layer.cornerRadius = r/2;
//    circleHeader.backgroundColor = [UIColor whiteColor];
 
    //Draw a circle
    // Get the contextRef
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    // Set the border width
    CGContextSetLineWidth(contextRef, 1.0);
    
    // Set the circle fill color to GREEN
    CGContextSetRGBFillColor(contextRef, 255.0, 255.0, 255.0, 0.6);
    
    // Set the cicle border color to BLUE
    CGContextSetRGBStrokeColor(contextRef, 255.0, 255.0, 255.0, 0.3);
    
    // Fill the circle with the fill color
    CGContextFillEllipseInRect(contextRef, rect);
    
    // Draw the circle border
    CGContextStrokeEllipseInRect(contextRef, rect);
    
    return circleHeader;
}
*/

//display cell
- (UITableViewCell *)tableView:(UITableView *)tableV cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"cell";
    UITableViewCell *cell = [tableV dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor whiteColor];
    }

    
    EWTaskItem *task = [tasks objectAtIndex:indexPath.section];
    if ([task.success boolValue]) {
        cell.textLabel.text = [task.completed date2String];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Woke up by %d users", task.waker.count];
    }else{
        cell.textLabel.text = [task.time date2String];
        cell.detailTextLabel.text = @"Did not wake up on time";
    }
    
    return cell;
}
//tap cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    /*
    EWRecordingViewController *controller = [[EWRecordingViewController alloc] initWithNibName:nil bundle:nil];
    controller.task = tasks[indexPath.row];
    [self presentViewController:controller animated:YES completion:NULL];
    
    //voice message
    EWMediaItem *media = [[EWMediaStore sharedInstance] createMedia];//with ramdom audio
    media.author = currentUser;
    [media addTasksObject:tasks[indexPath.row]];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    EWTaskItem *task = [tasks objectAtIndex:indexPath.row];
    hud.labelText = @"Sending";
    NSLog(@"Audio %@ sent to %@ on %@ successfully", media.audioKey, person.name, [task.time date2dayString]);
    //save
    NSManagedObjectContext *context = [[[SMClient defaultClient] coreDataStore] contextForCurrentThread];
    [context saveOnSuccess:^{
        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
        hud.mode = MBProgressHUDModeCustomView;
        hud.labelText = @"Sent";
        [hud hide:YES afterDelay:1.5];
        [context refreshObject:media mergeChanges:YES];
    } onFailure:^(NSError *error) {
        [NSException raise:@"Unable to send media" format:@"Reason: %@", error.description];
    }];*/
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"Accessory button tapped");
}


#pragma mark - USER LOGIN
- (void)userLoggedIn{
    NSLog(@"PersonVC: user logged in, starting refresh");
    [self initData];
    [self initView];
}

@end
