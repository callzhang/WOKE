//
//  PersonViewCell.m
//  EarlyWorm
//
//  Created by Lei Zhang on 7/28/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWMediaViewCell.h"
#import "EWWakeUpViewController.h"
#import "AVManager.h"

@implementation EWMediaViewCell
@synthesize controller, tableView, media;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.title.text = @"早上好";
        self.description.text = @"早上的虫子更好";
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:YES];
    // Configure the view for the selected state
}
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    [super setHighlighted:highlighted animated:YES];
}


- (IBAction)mediaPlay:(id)sender {
    if (AVManager.sharedManager.player.isPlaying) {
        [AVManager.sharedManager stopAllPlaying];
        if ([AVManager.sharedManager.currentCell isEqual:self]) {
            [self.playBtn setTitle:@"Play" forState:UIControlStateNormal];
            return;
        }
    }
    
    [self.playBtn setTitle:@"Stop" forState:UIControlStateNormal];
    [AVManager.sharedManager playForCell:self];
    
    
}


- (IBAction)like:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Like" message:@"Like function is not available yet." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)profile:(id)sender{
    NSLog(@"Profile");
    //need to figure out how to call tableViewController from here
}

@end
