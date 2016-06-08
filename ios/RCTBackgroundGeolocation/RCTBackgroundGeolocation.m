//
//  RCTBackgroundGeolocation.m
//  RCTBackgroundGeolocation
//
//  Created by Marian Hello on 04/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import "RCTBackgroundGeolocation.h"
#import "RCTLog.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"

@implementation RCTBackgroundGeolocation

@synthesize bridge = _bridge;
@synthesize bgDelegate;

RCT_EXPORT_MODULE();


-(instancetype)init
{
    self = [super init];
    if (self) {
        bgDelegate = [[BackgroundGeolocationDelegate alloc] init];
        bgDelegate.onLocationChanged = [self createLocationChangedHandler];
    }

    return self;
}

/**
 * configure plugin
 */
RCT_EXPORT_METHOD(configure:(NSDictionary*)config success:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #configure");
    dispatch_async(dispatch_get_main_queue(), ^{
        [bgDelegate configure:config];
        success(@[]);
    });
}

RCT_EXPORT_METHOD(start:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #start");
    dispatch_async(dispatch_get_main_queue(), ^{
        [bgDelegate start];
        success(@[]);
    });
}

RCT_EXPORT_METHOD(stop:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #stop");
    [bgDelegate stop];
    success(@[]);
}

RCT_EXPORT_METHOD(finish:(int)taskId)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #finish");
    [bgDelegate finish];
}

RCT_EXPORT_METHOD(isLocationEnabled:(RCTResponseSenderBlock)callback)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #isLocationEnabled");
    callback(@[@([bgDelegate isLocationEnabled])]);
}

RCT_EXPORT_METHOD(showAppSettings)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #showAppSettings");
    [bgDelegate showAppSettings];
}

RCT_EXPORT_METHOD(showLocationSettings)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #showLocationSettings");
    [bgDelegate showLocationSettings];
}

RCT_EXPORT_METHOD(watchLocationMode:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #watchLocationMode");
}

RCT_EXPORT_METHOD(stopWatchingLocationMode)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #stopWatchingLocationMode");
}

RCT_EXPORT_METHOD(getLocations:(RCTResponseSenderBlock)callback)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #getLocations");
}

RCT_EXPORT_METHOD(deleteLocation:(int)locationId success:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #deleteLocation");
}

RCT_EXPORT_METHOD(deleteAllLocations:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #deleteAllLocations");
}

-(void (^)(NSMutableDictionary *location)) createLocationChangedHandler {
    return ^(NSMutableDictionary *location) {
        RCTLogInfo(@"RCTBackgroundGeolocation onLocationChanged");
        
        [self sendEvent:@"location" dictionary:location];
    };
}

-(void) sendEvent:(NSString*)name dictionary:(NSDictionary*)dictionary
{
    NSString *event = [NSString stringWithFormat:@"%@", name];
    [_bridge.eventDispatcher sendDeviceEventWithName:event body:dictionary];
}

-(void) sendEvent:(NSString*)name array:(NSArray*)array
{
    NSString *event = [NSString stringWithFormat:@"%@", name];
    [_bridge.eventDispatcher sendDeviceEventWithName:event body:array];
}

@end
