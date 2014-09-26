//
//  EWRingtoneSelectionViewController.m
//  EarlyWorm
//
//  Created by Lei on 8/19/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWRingtoneSelectionViewController.h"
#import "AVManager.h"




@interface EWRingtoneSelectionViewController ()

@end

@implementation EWRingtoneSelectionViewController
@synthesize ringtoneList;
@synthesize selected;
@synthesize delegate;
//@synthesize prefArray;

- (id)init
{
    self = [super init];
    if (self) {
        ringtoneList = ringtoneNameList;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDone)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//save editing
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    //save
    [self.delegate ViewController:self didFinishSelectRingtone:ringtoneList[selected]];
    //stop play
    [AVManager.sharedManager stopAllPlaying];
    //save to defaults
    [NSUserDefaults.standardUserDefaults setObject:ringtoneList[selected] forKey:@"OfflineTone"];
    
}

- (void)onDone{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return ringtoneList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.backgroundColor = kCustomLightGray;
    }
    // Configure the cell...
    if (selected > 100) {
        NSLog(@"Something wrong when getting the music index. Action abord");
    }else{
        if ([ringtoneList[selected] isEqualToString: [ringtoneList objectAtIndex:indexPath.row]]) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
    }
    NSArray *fileString = [ringtoneList[indexPath.row] componentsSeparatedByString:@"."];
    NSString *file = fileString[0];
    cell.textLabel.text = file;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *tone = [ringtoneList objectAtIndex:indexPath.row];
    selected = indexPath.row;
    [AVManager.sharedManager playSoundFromFileName:tone];
}

@end
