//
//  LocationProvider.m
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 14/09/2016.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import "LocationProvider.h"

@implementation AbstractLocationProvider {
    UILocalNotification *localNotification;
}

@synthesize delegate, distanceFilter;

- (instancetype) init
{
    self = [super init];
    
    if (self == nil) {
        return self;
    }

    localNotification = [[UILocalNotification alloc] init];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    return self;
}

- (void) notify:(NSString*)message
{
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = message;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

@end