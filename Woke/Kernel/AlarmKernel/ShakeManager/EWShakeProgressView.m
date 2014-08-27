//
//  EWShakeProgressView.m
//  Woke
//
//  Created by mq on 14-8-22.
//  Copyright (c) 2014年 WokeAlarm.com. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

#import "EWShakeProgressView.h"


@interface  EWShakeProgressView()

@property (nonatomic,strong) CMMotionManager * motionManager;


@end


@implementation EWShakeProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _motionManager  = [[CMMotionManager alloc] init];
        
        _motionManager.accelerometerUpdateInterval = 0.1f;
        
        
        // Initialization code
    }
    return self;
}
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        _motionManager  = [[CMMotionManager alloc] init];
        
        _motionManager.accelerometerUpdateInterval = 0.1f;
        
        
        // Initialization code
    }
    return self;
}
-(BOOL)isShakeSupported
{
    if ([self.motionManager isAccelerometerAvailable]) {
        
        return YES;
    }
    else {
        return NO;
    }
}

-(void)startUpdateProgressBarWithProgressingHandler:(ProgressingHandler)progressHandler CompleteHandler:(SuccessProgressHandler)successProgressHandler
{
    
    if ([self isShakeSupported]) {
        //TODO: sound
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error){
            
            //NSLog(@"%f %f %f",accelerometerData.acceleration.x , accelerometerData.acceleration.y , accelerometerData.acceleration.z);
            
            double x = accelerometerData.acceleration.x;
            double y = accelerometerData.acceleration.y;
            double z = accelerometerData.acceleration.z;
            double strength = log(x*x +y*y+ z*z) * kMotionStrengthModifier - kMotionThrethold;
            //TODO: Viberation
            if (self.progress < 1) {
                
                
                [self setProgress:(self.progress + strength) animated:YES];
                
                if (progressHandler) {
                    progressHandler();
                }
                
            }else{
                //TODO: sound
                [self.motionManager stopAccelerometerUpdates];
                
                if (successProgressHandler) {
                    successProgressHandler();
                }
                NSLog(@"Shake Compeled");
            }
            
            
            
        }];
    }
    else {
        
        NSLog(@"Accelerometer is not available.");
        if (successProgressHandler) {
			successProgressHandler();
		}
    }

    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
