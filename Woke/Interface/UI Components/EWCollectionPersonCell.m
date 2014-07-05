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
#import "EWPersonStore.h"
#import "EWTaskItem.h"
#import "EWTaskStore.h"
#import "NSDate+Extend.h"

@implementation EWCollectionPersonCell

////only called when registing class
//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        
//        self.image.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
//        
//        //mask
//        //[self applyHexagonMask];
//        
//    }
//    return self;
//}
//
//- (id)initWithCoder:(NSCoder *)aDecoder{
//    self = [super initWithCoder:aDecoder];
//    if (self) {
//        self.image.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
//        //mask
//        //[self applyHexagonMask];
//    }
//    return self;
//}

- (void)applyHexagonMask{
    [EWUIUtil applyHexagonSoftMaskForView:self.image];
}

-(NSString *)timeAndDistance
{
    
    NSString *timeLeft = _time.text;
    NSString *distance = _km.text;
    
    if (!timeLeft && !_distance) {
        _timeAndDistance = @"";
    }
    else if (timeLeft || distance) {
        _timeAndDistance = [timeLeft stringByAppendingString:distance];
    }
    else
    {
       _timeAndDistance = [[timeLeft stringByAppendingString:@" . "] stringByAppendingString:distance];
    }
    
    return _timeAndDistance;
}

- (void)setPerson:(EWPerson *)person{
    _person = person;
    //init state
    self.image.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    self.name.alpha = 0;
    self.selection.hidden = YES;
    self.initial.hidden = YES;
    [self applyHexagonMask];
    
    self.profile.image = person.profilePic;
    self.name.text = person.name;
    
    //If show name, the name will displayed below the cell
    if (person.isMe) {
        self.initial.hidden = NO;
        self.initial.text = @"YOU";
    }else if(self.showName){
        [UIView animateWithDuration:0.2 animations:^{
            self.name.alpha = 1;
            CGRect frame = self.name.frame;
            frame.origin.y += 20;
            self.name.frame = frame;
        }];
    }
    
    //time
    NSDate *time = person.cachedInfo[kNextTaskTime];
    if (!time) {
        time = [[EWTaskStore sharedInstance] nextValidTaskForPerson:person].time;
    }
    self.time.text = [time timeLeft];
    if (self.showTime) {
        self.time.alpha = 1;
    }
    
    //distance
    if (!_person.isMe && _person.lastLocation && me.lastLocation && !_distance) {
        CLLocation *loc0 = me.lastLocation;
        CLLocation *loc1 = _person.lastLocation;
        self.distance = [loc0 distanceFromLocation:loc1]/1000;
    }
    if (self.showDistance && self.distance) {
        self.km.text = [NSString stringWithFormat:@"%.1fkm", _distance];
    }
    
}

@end
