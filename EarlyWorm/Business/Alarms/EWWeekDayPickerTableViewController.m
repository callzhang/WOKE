//
//  EWWeekDayPickerTableViewController.m
//  EarlyWorm
//
//  Created by Lei on 9/4/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWWeekDayPickerTableViewController.h"

@interface EWWeekDayPickerTableViewController ()

@end

@implementation EWWeekDayPickerTableViewController
@synthesize repeatString;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _dataSouce = @[@"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", @"Sunday"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (repeatString == nil) {
        _selectedDays = [NSMutableArray arrayWithObjects:@"NO", @"NO", @"NO", @"NO", @"NO", @"NO", @"NO", nil];
    }
    else{
        _selectedDays = [repeatString repeatArray];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.delegate viewController:self didFinishPickDays:repeatString];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *weekdayCell = @"weekdayCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:weekdayCell];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:weekdayCell];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    // Configure the cell...
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    NSString *day = [_dataSouce objectAtIndex:indexPath.row];
    cell.textLabel.text = day;
    if ([[_selectedDays objectAtIndex:indexPath.row] isEqual:@"YES"]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[_selectedDays objectAtIndex:indexPath.row] isEqual:@"YES"]) {
        [_selectedDays setObject:@"NO" atIndexedSubscript:indexPath.row];
    }else{
        [_selectedDays setObject:@"YES" atIndexedSubscript:indexPath.row];
    }
    
    repeatString = [self selectedDays2String:_selectedDays];
    NSLog(@"Days repeat: %@", repeatString);
    [tableView reloadData];
}

#pragma mark - Type transfer

- (NSString *)selectedDays2String:(NSArray *)array {
    
    if ([array isEqual:[NSArray arrayWithObjects:@"YES",@"YES",@"YES",@"YES",@"YES",@"YES",@"YES", nil]]) {
        return @"Everyday";
    }
    else if([array isEqual:@[@"YES",@"YES",@"YES",@"YES",@"YES", @"NO", @"NO"]]) {
        return @"Weekday";
    }
    
    NSString *string = @"";

    for (NSInteger i=0; i<array.count; i++) {
        if ([[array objectAtIndex:i] isEqual:@"YES"]) {
            if ([string isEqual:@""]) {
                string = [_dataSouce objectAtIndex:i];
            }else{
                string = [string stringByAppendingFormat:@", %@", [_dataSouce objectAtIndex:i]];
            }
        }
    }
    
    return string;
}

@end
