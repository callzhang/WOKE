//
//  EWNotificationCell.m
//  Woke
//
//  Created by Lee on 7/3/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWNotificationCell.h"
#import "EWNotification.h"
#import "EWPerson.h"
#import "EWUIUtil.h"
#import "EWPersonStore.h"


@implementation EWNotificationCell

- (void)awakeFromNib
{
    // Initialization code
    
    self.time = [[UILabel alloc] init];
    [self addSubview:self.time];
    self.time.textColor = [UIColor whiteColor];
    self.time.backgroundColor = [UIColor clearColor];
    self.time.font = [UIFont systemFontOfSize:12];
    
    self.detail = [[UILabel alloc] init];
     self.detail.textColor = [UIColor whiteColor];
    self.detail.backgroundColor = [UIColor clearColor];
    [self addSubview:self.detail];
    self.detail.font = [UIFont fontWithName:@"lato-Regular.ttf" size:14];
    self.detail.numberOfLines = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:NO];

    // Configure the view for the selected state
}

- (void)setNotification:(EWNotification *)notification{
    if (_notification == notification) {
        return;
    }
    _notification = notification;
    self.detail.frame = CGRectMake(61, 8, 250, 35);
    self.time.frame = CGRectMake(61, 47, 181, 15);
    

    //time
    if (notification.createdAt) {
        self.time.text = [notification.createdAt.timeElapsedString stringByAppendingString:@" ago"];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            PFObject *PO = [notification getParseObjectWithError:NULL];
            notification.createdAt = PO.createdAt;
            self.time.text = [PO.createdAt.timeElapsedString stringByAppendingString:@" ago"];
        });
    }
    
    
    NSString *type = notification.type;
    if ([type isEqualToString:kNotificationTypeNotice]) {
        self.profilePic.image = nil;
        self.profilePic.hidden = YES;
        NSInteger deltaX = self.detail.x - self.profilePic.x;
        self.detail.left = self.profilePic.x;
        self.detail.width += deltaX;
        self.time.left = self.profilePic.x;
        self.time.width += deltaX;
        
        NSString *title = notification.userInfo[@"title"];
        //NSString *body = notification.userInfo[@"content"];
        //NSString *link = notification.userInfo[@"link"];
        
        self.detail.text = title;
    }else{
        //kNotificationTypeNextTaskHasMedia
        //kNotificationTypeFriendRequest
        //kNotificationTypeFriendAccepted
        
        NSString *personID = notification.sender;
        EWPerson *sender = [[EWPersonStore sharedInstance] getPersonByServerID:personID];
        if (sender.profilePic) {
            self.profilePic.image = sender.profilePic;
        }else{
            //download
            [sender refreshShallowWithCompletion:^{
                self.profilePic.image = sender.profilePic;
            }];
        }

        
        if([type isEqualToString:kNotificationTypeFriendRequest]){
            
               self.detail.text = [NSString stringWithFormat:@"%@ has sent you a friend request", sender.name];
            
            
        }else if([type isEqualToString:kNotificationTypeFriendAccepted]){
            
            self.detail.text = [NSString stringWithFormat:@"%@ has accepted your friend request", sender.name];
            
        }else if (kNotificationTypeNextTaskHasMedia){
            self.detail.text = @"You have received voice(s) for next wake up.";
        }
    }
    
    //adjust size
        
    CGSize fixLabelSize = [self.detail.text sizeWithFont:self.detail.font constrainedToSize:CGSizeMake(250, 1000)  lineBreakMode:UILineBreakModeWordWrap];
    
    self.detail.height = fixLabelSize.height;
    //self.detail.width = fixLabelSize.width;
    
    CGFloat deltaHeight = self.detail.height - 35;
    //self.detail.height += deltaHeight;®
    self.time.y += deltaHeight;
    self.contentView.height += deltaHeight;
    self.height = self.contentView.height;
    
    
    if (notification.completed) {
        self.detail.enabled = NO;
        self.time.enabled = NO;
    }else{
        self.detail.enabled = YES;
        self.time.enabled = YES;
        
    }
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    
    [EWUIUtil applyHexagonSoftMaskForView:self.profilePic];
}


@end
