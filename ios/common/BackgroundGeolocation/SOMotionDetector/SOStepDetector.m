
//
//  SOStepDetector.m
//  MotionDetection
//
//  Created by Artur on 5/15/15.
//  Copyright (c) 2015 Artur Mkrtchyan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SOStepDetector.h"
#import <CoreMotion/CoreMotion.h>

#define kUpdateInterval 0.2f
@interface SOStepDetector()

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSOperationQueue* queue;

@end

@implementation SOStepDetector

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    
    self.motionManager = [CMMotionManager new];
    
    self.motionManager.accelerometerUpdateInterval = kUpdateInterval;
    self.motionManager.deviceMotionUpdateInterval  = kUpdateInterval;
    self.motionManager.gyroUpdateInterval          = kUpdateInterval;
    self.motionManager.magnetometerUpdateInterval  = kUpdateInterval;
    self.motionManager.showsDeviceMovementDisplay  = YES;
    
    self.queue = [NSOperationQueue new];
    self.queue.maxConcurrentOperationCount = 1;
    
    return self;
}

- (void)startDetectionWithUpdateBlock:(void (^)(NSError *))callback
{
    if (self.motionManager.isAccelerometerActive) {
        return;
    }
    
    [self.motionManager startAccelerometerUpdatesToQueue:self.queue
                                             withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        if (error) {
            if (callback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback (error);
                });
            }
            return ;
        }
        
        CMAcceleration acceleration = accelerometerData.acceleration;
        
        CGFloat strength = 1.2f;
        BOOL isStep = NO;
        if (fabs(acceleration.x) > strength || fabs(acceleration.y) > strength || fabs(acceleration.z) > strength) {
            isStep = YES;
        }
        if (isStep) {
            if (callback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback (nil);
                });
            }
        }
    }];
}

- (void)stopDetection
{
    if (self.motionManager.isAccelerometerActive) {
        [self.motionManager stopAccelerometerUpdates];
    }
}

@end
