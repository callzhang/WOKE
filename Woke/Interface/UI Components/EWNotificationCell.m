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
    [super awakeFromNib];
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

    //time
    if (notification.createdAt) {
        self.time.text = [notification.createdAt.timeElapsedString stringByAppendingString:@" ago"];
    }else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            PFObject *PO = [notification getParseObjectWithError:NULL];
            dispatch_async(dispatch_get_main_queue(), ^{
                notification.createdAt = PO.createdAt;
                self.time.text = [notification.createdAt.timeElapsedString stringByAppendingString:@" ago"];
            });
        });
        
    }
    
    
    NSString *type = notification.type;
    if ([type isEqualToString:kNotificationTypeNotice]) {
        self.profilePic.image = nil;
        self.profilePic.hidden = YES;
        
        NSString *title = notification.userInfo[@"title"];
        NSString *body = notification.userInfo[@"content"];
        NSString *link = notification.userInfo[@"link"];
        
        self.detail.text = [title stringByAppendingString:[NSString stringWithFormat:@"\n%@\n%@", body, link]];
        
        
    }else{
        //kNotificationTypeNextTaskHasMedia
        //kNotificationTypeFriendRequest
        //kNotificationTypeFriendAccepted
        
        NSString *personID = notification.sender;
        EWPerson *sender = [[EWPersonStore sharedInstance] getPersonByServerID:personID];
        self.profilePic.hidden = NO;
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
            //TODO: timestamp
            self.detail.text = @"You have received voice(s) for next wake up.";
        }
    }
    
    
    if (notification.completed) {
        self.detail.enabled = NO;
        self.time.enabled = NO;
    }else{
        self.detail.enabled = YES;
        self.time.enabled = YES;
    }
    
    //[self setNeedsDisplay];
}

- (void)setSize{
    //adjust size
    if ([_notification.type isEqualToString:kNotificationTypeNotice]) {
        
        NSInteger deltaX = self.detail.x - self.profilePic.x;
        self.detail.x = self.profilePic.x;
        self.detail.width += deltaX;
        self.time.x = self.profilePic.x;
        self.time.width += deltaX;
        
        CGSize fixLabelSize = [self.detail.text sizeWithFont:self.detail.font constrainedToSize:CGSizeMake(self.detail.width, 1000)  lineBreakMode:UILineBreakModeWordWrap];
        float original_height = self.detail.height;
        self.detail.height = ceil(fixLabelSize.height);
        
        CGFloat deltaHeight = self.detail.height - original_height;
        //self.detail.height += deltaHeight;
        //self.time.y += deltaHeight;
        self.contentView.height += deltaHeight;
        self.height = self.contentView.height;
        
    }
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    if (self.profilePic.image) {
        [EWUIUtil applyHexagonSoftMaskForView:self.profilePic];
    }
    
}


@end
