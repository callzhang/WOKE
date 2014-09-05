//
//  EWShakeProgressView.m
//  Woke
//
//  Created by mq on 14-8-22.
//  Copyright (c) 2014年 WokeAlarm.com. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

#import "EWShakeProgressView.h"
#import "AVManager.h"

@interface  EWShakeProgressView()

@property (nonatomic,strong) CMMotionManager * motionManager;
@property (nonatomic) float threshold;

@end


@implementation EWShakeProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _motionManager  = [[CMMotionManager alloc] init];
        
        _motionManager.accelerometerUpdateInterval = 0.1f;
        _threshold = kMotionThreshold;
        
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
        _threshold = kMotionThreshold;
        
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
			
			_threshold = kMotionThreshold * (1+self.progress);
			double strength = log(x*x +y*y+ z*z) * kMotionStrengthModifier - _threshold;
			
			static NSTimer *viberationTimer;
            if (self.progress < 1) {
                //Viberation
				if (![viberationTimer isValid]) {
					viberationTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(viberation) userInfo:nil repeats:YES];
				}
                
#ifdef DEBUG
                [self setProgress:(self.progress + strength) animated:YES];
#else
				//modify the time it takes to reach the end
				[self setProgress:(self.progress + strength * kMotionStrengthModifier) animated:YES];
#endif
                
                if (progressHandler) {
                    progressHandler();
                }
                
            }else{
                //TODO: sound
				[[AVManager sharedManager] playSoundFromFile:@"new.caf"];
				[viberationTimer invalidate];
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

- (void)viberation{
#ifdef DEBUG
	NSLog(@"Threshold %f, progress %f", _threshold, self.progress);
#endif
	double t = [[NSDate date] timeIntervalSinceReferenceDate];
	t = t - (NSInteger)t;
	NSInteger phase = floor(t*5);
	switch (phase) {
		case 1:{
			if (self.progress > 0.2) {
				AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
			}
			break;
		}
		case 2:{
			if (self.progress > 0.4) {
				AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
			}
			break;
		}
		case 3:{
			if (self.progress > 0.6) {
				AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
			}
			break;
		}
		case 4:{
			if (self.progress > 0.8) {
				AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
			}
			break;
		}
		case 0:{
			if (self.progress > 0.9) {
				AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
			}
			break;
		}
		default:
			break;
	}
}

@end
