//
//  EWCollectionPersonCell.m
//  EarlyWorm
//
//  Created by Lei on 3/2/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWCollectionPersonCell.h"
#import "EWUIUtil.h"
#import "EWPerson.h"
#import "EWPersonManager.h"
//#import "EWTaskItem.h"
//#import "EWTaskManager.h"
#import "NSDate+Extend.h"
#import "EWAlarmManager.h"

@interface EWCollectionPersonCell()
@property (nonatomic) BOOL needsUpdate;
@end

@implementation EWCollectionPersonCell

- (void)applyHexagonMask{
    [EWUIUtil applyHexagonSoftMaskForView:self.image];
}

-(NSString *)timeAndDistance
{
    
    NSString *timeLeftString = [self timeString];
    NSString *distanceString = [self distanceString];
    
    if (!_timeLeft && !_distance) {
        _timeAndDistance = @"";
    }
    else if(_timeLeft && _distance){
       _timeAndDistance = [[timeLeftString stringByAppendingString:@" . "] stringByAppendingString:distanceString];
    }else if (_timeLeft) {
        _timeAndDistance = [timeLeftString stringByAppendingString:timeLeftString];
    }else if(_distance){
        _timeAndDistance = [timeLeftString stringByAppendingString:distanceString];
    }
    
    return _timeAndDistance;
}

- (void)setPerson:(EWPerson *)person{
    if ([self.person isEqual:person]) {
        return;
    }
   
    _person = person;
    _needsUpdate = YES;
    [self prepareForDisplay];
}

- (NSString *)distanceString{
    if (!_person.isMe && _person.lastLocation && [EWSession sharedSession].currentUser.lastLocation) {
        CLLocation *loc0 = [EWSession sharedSession].currentUser.lastLocation;
        CLLocation *loc1 = _person.lastLocation;
        _distance = [loc0 distanceFromLocation:loc1]/1000;
    }
    if (_distance) {
        return [NSString stringWithFormat:@"%.0fkm", _distance];
    }else{
        return @"";
    }
}

- (NSString *)timeString{
    NSDate *time = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:_person];;
    if (time && [time timeIntervalSinceNow] > 0) {
        _timeLeft = [time timeIntervalSinceNow];
        return [time timeLeft];
    }else{
        _timeLeft = 0;
        return @"";
    }
}


- (void)drawRect:(CGRect)rect{
    [EWUIUtil applyHexagonSoftMaskForView:self.image];
	//[EWUIUtil applyShadow:self.contentView];//hex takes too much GPU
}

- (void)prepareForDisplay{
    if (_needsUpdate) {
        
        //init state
        self.selection.hidden = YES;
        
        //profile picture
        if (_person.profilePic) {
            self.profile.image = _person.profilePic;
        }else{
            self.profile.image = [UIImage imageNamed:@"profile"];
        }
        
        
        //Name
        BOOL isMe = _person.isMe;
        if (isMe) {
            //self.initial.hidden = NO;
            self.initial.text = @"YOU";
        }else{
            self.initial.text = @"";
            if(self.showName){
                self.name.alpha = 1;
                self.name.text = _person.name;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.2 animations:^{
                        self.name.alpha = 1;
                        CGRect frame = self.name.frame;
                        frame.origin.y += 20;
                        self.name.frame = frame;
                    }];
                });
            }else{
                self.name.text = @"";
            }
        }
        
        //info
        self.info.text = @"";
        if (!isMe) {
            
            if (self.showTime) {
                self.info.text = [self timeString];
            }
            
            //distance
            if (self.showDistance && [self.info.text isEqualToString:@""]) {
                self.info.text = [self distanceString];
            }
            
        }
        
        _needsUpdate = NO;
    }
    
}

@end
