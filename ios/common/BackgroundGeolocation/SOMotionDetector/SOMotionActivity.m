//
//  SOMotionActivity.m
//  BackgroundGeolocation
//
//  Created by Marian Hello on 13/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#import "SOMotionActivity.h"

@implementation SOMotionActivity

@synthesize motionType, confidence;

- (instancetype) init
{
    self = [super init];
    if (self != nil) {
        confidence = 0;
    }
    
    return self;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"Activity: confidence=%d motionType=%d", confidence, motionType];
    
}

-(id) copyWithZone: (NSZone *) zone
{
    SOMotionActivity *copy = [[[self class] allocWithZone: zone] init];
    if (copy) {
        copy.confidence = confidence;
        copy.motionType = motionType;
    }
    
    return copy;
}

@end
