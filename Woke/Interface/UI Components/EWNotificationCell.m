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

@interface EWNotificationCell()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userLabelLeadingConstraint;

@end

@implementation EWNotificationCell
- (void)setNotification:(EWNotification *)notification{
    if (_notification == notification) {
        return;
    }
    _notification = notification;

    //time
    if (notification.createdAt) {
        self.time.text = [notification.createdAt.timeElapsedString stringByAppendingString:@" ago"];
    }else{
		__block EWNotification *blockNotification = _notification;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            PFObject *PO = [blockNotification getParseObjectWithError:NULL];
            dispatch_async(dispatch_get_main_queue(), ^{
                blockNotification.createdAt = PO.createdAt;
                self.time.text = [blockNotification.createdAt.timeElapsedString stringByAppendingString:@" ago"];
            });
        });
        
    }
    
    NSString *type = notification.type;
    if ([type isEqualToString:kNotificationTypeSystemNotice]) {
        self.profilePic.image = nil;
        self.profilePic.hidden = YES;
        
        NSString *title = notification.userInfo[@"title"];
        NSString *body = notification.userInfo[@"content"];
        NSString *link = notification.userInfo[@"link"];
        
        self.detail.text = [title stringByAppendingString:[NSString stringWithFormat:@"\n%@\n%@", body, link]];
    }
    else{
        //kNotificationTypeNextTaskHasMedia
        //kNotificationTypeFriendRequest
        //kNotificationTypeFriendAccepted
        
        NSString *personID = notification.sender;
        EWPerson *sender = [[EWPersonStore sharedInstance] getPersonByServerID:personID];
        self.profilePic.hidden = NO;
        if (sender.profilePic) {
            self.profilePic.image = sender.profilePic;
        }
        else{
            //download
            [sender refreshShallowWithCompletion:^{
                self.profilePic.image = sender.profilePic;
            }];
        }
        
        if([type isEqualToString:kNotificationTypeFriendRequest]){
            self.detail.text = [NSString stringWithFormat:@"%@ has sent you a friend request", sender.name];
        }
        else if([type isEqualToString:kNotificationTypeFriendAccepted]){
            self.detail.text = [NSString stringWithFormat:@"%@ has accepted your friend request", sender.name];
        }
        else if (kNotificationTypeNextTaskHasMedia){
            //TODO: timestamp
            self.detail.text = @"You have received voice(s) for next wake up.";
        }
    }
    
    if (notification.completed) {
        self.detail.enabled = NO;
        self.time.enabled = NO;
    }
    else{
        self.detail.enabled = YES;
        self.time.enabled = YES;
    }
    
    [self setSize];
}

- (void)setSize{
    //adjust size
    if ([_notification.type isEqualToString:kNotificationTypeSystemNotice]) {
        self.userLabelLeadingConstraint.constant = -40;
        self.detail.text = [NSString stringWithFormat:@"%@:%@", self.detail.text, kNotificationTypeSystemNotice];

        CGSize fixLabelSize = [self.detail.text sizeWithFont:self.detail.font constrainedToSize:CGSizeMake(self.detail.width+40, 1000)  lineBreakMode:NSLineBreakByWordWrapping];
        CGFloat deltaH = ceil(fixLabelSize.height - self.detail.height);
        self.detail.height += deltaH;
        self.contentView.height = fixLabelSize.height + deltaH;
        self.height = self.contentView.height;
    }
    else {
        self.userLabelLeadingConstraint.constant = 8;
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
