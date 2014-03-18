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
#import "EWRoundButton.h"

@implementation EWMediaViewCell
@synthesize controller, media;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.title.text = @"早上好";
        self.description.text = @"早上的虫子更好";
        //self.progressBar.maximumValueImage = [UIImage imageNamed:@"MediaCell"];
        
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


- (IBAction)play:(id)sender {
    if (AVManager.sharedManager.player.isPlaying) {
        [AVManager.sharedManager stopAllPlaying];
        if ([AVManager.sharedManager.currentCell isEqual:self]) {
            [[AVManager sharedManager].currentCell.mediaBar stop];
            return;
        }
    }
    //play this cell
    [AVManager.sharedManager playForCell:self];
    [self.mediaBar play];
    
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
