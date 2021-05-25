//
//  SOMotionActivity.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 13/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#ifndef SOMotionActivity_h
#define SOMotionActivity_h

#import <Foundation/Foundation.h>

typedef enum
{
    MotionTypeNotMoving = 1,
    MotionTypeWalking,
    MotionTypeRunning,
    MotionTypeAutomotive,
    MotionTypeUnknown
} SOMotionType;

@interface SOMotionActivity : NSObject <NSCopying>

@property int confidence;
@property SOMotionType motionType;

@end

#endif /* SOMotionActivity_h */
