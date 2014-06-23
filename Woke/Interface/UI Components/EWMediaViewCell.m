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
#import "EWMediaSlider.h"
#import "EWDataStore.h"
#import "EWPersonViewController.h"
#import "EWUIUtil.h"

#define maxBytes        150000

@implementation EWMediaViewCell
@synthesize media;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.name.text = @"";
        self.description.text = @"";
        self.backgroundColor = [UIColor clearColor];
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCell:) name:kAudioPlayerWillStart object:nil];
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
    
}

- (void)setMedia:(EWMediaItem *)m{
    if ([m.type isEqualToString:kMediaTypeBuzz]) {
        self.mediaBar.hidden = YES;
        self.buzzIcon.hidden = NO;
    }else{
        self.mediaBar.hidden = NO;
        self.buzzIcon.hidden = YES;
        
        //set media bar length
        CGRect frame = self.mediaBar.frame;
        AVAudioPlayer *p = [[AVAudioPlayer alloc] initWithData:m.audio error:NULL];
        double len = p.duration;
        self.mediaBar.timeLabel.text = [NSString stringWithFormat:@"%.1f\"", len];
        double ratio = len/30/2 + 0.5;
        if (ratio > 1.0) ratio = 1.0;
        frame.size.width = 240.0 * ratio;
        self.mediaBar.frame = frame;
        //NSLog(@"changed slider width to %f", frame.size.width);
        
        [self setNeedsDisplay];
    }
    
    self.profilePic.imageView.image = media.author.profilePic;
    [EWUIUtil applyHexagonMaskForView:self.profilePic.imageView];
    media = m;
}


- (IBAction)profile:(id)sender{
    EWPersonViewController *profileVC = [[EWPersonViewController alloc] initWithPerson:media.author];
    [self.controller presentViewControllerWithBlurBackground:profileVC];
    
//    if([self.superview isKindOfClass:[UITableView class]]){
//        UITableView *table = (UITableView *)self.superview;
//        if ([table.delegate isKindOfClass:[EWWakeUpViewController class]]) {
//            EWWakeUpViewController *presenter = (EWWakeUpViewController *)table.delegate;
//            [presenter presentViewControllerWithBlurBackground:controller];
//        }
//    }

}


//- (void)updateCell:(NSNotification *)notification{
//    NSString *path = notification.userInfo[kAudioPlayerNextPath];
//    NSString *localPath = [[EWDataStore sharedInstance] localPathForKey:media.audioKey];
//    if ([path isEqualToString:localPath] || [path isEqualToString:media.audioKey]) {
//        //matched media cell with playing path
//        [AVManager sharedManager].currentCell = self;
//    }
//}

@end
