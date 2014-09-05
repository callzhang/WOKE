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

#define maxBytes            150000
#define progressBarLength   200

@implementation EWMediaViewCell
@synthesize media;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.name.text = @"";
        self.message.text = @"";
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
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
            return;
        }
    }
    //play this cell
    [AVManager.sharedManager playForCell:self];
    
}

- (void)setMedia:(EWMediaItem *)m{
    NSParameterAssert(m);
    media = m;
    if ([media.type isEqualToString:kMediaTypeBuzz]) {
        self.mediaBar.hidden = YES;
        [self.icon setImage:[UIImage imageNamed:@"Buzz Icon"] forState:UIControlStateNormal];
    }else if([media.type isEqualToString:kMediaTypeVoice]){
        self.mediaBar.hidden = NO;
        [self.icon setImage:[UIImage imageNamed:@"Voice Icon"] forState:UIControlStateNormal];
        
        //set media bar length
        CGRect frame = self.mediaBar.frame;
        AVAudioPlayer *p = [[AVAudioPlayer alloc] initWithData:media.audio error:NULL];
        double len = p.duration;
        double ratio = len/30/2 + 0.5;
        if (ratio > 1.0) ratio = 1.0;
        frame.size.width = progressBarLength * ratio;
        self.mediaBar.frame = frame;
        
        [self setNeedsDisplay];
    }else{
        [NSException raise:@"Unexpected media type" format:@"Reason: please support %@", media.type];
    }
    
    //date
    self.date.text = [media.updatedAt date2MMDD];
    
    //profile
    [self.profilePic setImage:media.author.profilePic forState:UIControlStateNormal];
    [EWUIUtil applyHexagonSoftMaskForView:self.profilePic.imageView];
    
    //description
    self.message.text = media.message;
    
    
}


- (IBAction)profile:(id)sender{
    if (!media.author) {
        return;
    }
    EWPersonViewController *profileVC = [[EWPersonViewController alloc] initWithPerson:media.author];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:profileVC];
    [self.controller presentViewControllerWithBlurBackground:navController completion:NULL];

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
