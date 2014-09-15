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
    
    // init label
//    self.name = [[UILabel alloc] initWithFrame:CGRectMake(-20, 60, 120, 21)];
//    self.name.textAlignment = NSTextAlignmentCenter;
//    self.name.backgroundColor = [UIColor clearColor];
//    self.name.font = [UIFont systemFontOfSize:13.0];
//    self.name.textColor  = [UIColor whiteColor];
   
    _person = person;
    [self addSubview:self.name];
    //init state
    self.name.alpha = 0;
    self.selection.hidden = YES;
    self.initial.hidden = YES;
    //[self applyHexagonMask];
    
    if (person.profilePic) {
        self.profile.image = person.profilePic;
    }else{
        self.profile.image = [UIImage imageNamed:@"profile"];
    }
    
    self.name.text = person.name;
    
    //If show name, the name will displayed below the cell
    BOOL isMe = person.isMe;
    if (isMe) {
        self.initial.hidden = NO;
        self.initial.text = @"YOU";
    }else if(self.showName){
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{
                self.name.alpha = 1;
                CGRect frame = self.name.frame;
                frame.origin.y += 20;
                self.name.frame = frame;
            }];
        });
    }
    
    
    if (isMe) {
        self.time.text = @"";
        self.km.text = @"";
        self.showTime = NO;
        return;
    }else{
        if (self.showTime) {
            
            //time
            //[_time addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:nil];
            self.time.alpha = 1;
            self.time.text = [self timeString];
        }
        
        
        //distance
        if (self.showDistance && !time) {
            self.km.text = [self distanceString];
        }
        
    }
}

- (NSString *)distanceString{
    if (!_person.isMe && _person.lastLocation && me.lastLocation && !_distance) {
        CLLocation *loc0 = me.lastLocation;
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
    NSDate *time = _person.cachedInfo[kNextTaskTime];
    
    if (time && [time timeIntervalSinceNow] > 0) {
        _timeLeft = [time timeIntervalSinceNow];
        return [time timeLeft];
        
    }else{
        _timeLeft = 0;
        return @"";
        
    }

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSNumber *a = change[NSKeyValueChangeNewKey];
    float alpha = a.floatValue;
    NSLog(@"alpha changed: %f", alpha);
}


- (void)drawRect:(CGRect)rect{
    [EWUIUtil applyHexagonSoftMaskForView:self.image];
    //[EWUIUtil applyShadow:self.contentView];
}

@end
