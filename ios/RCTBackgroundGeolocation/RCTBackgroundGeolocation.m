//
//  RCTBackgroundGeolocation.m
//  RCTBackgroundGeolocation
//
//  Created by Marian Hello on 04/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import "RCTBackgroundGeolocation.h"
#import <React/RCTLog.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import "Logging.h"

@implementation RCTBackgroundGeolocation

FMDBLogger *sqliteLogger;

@synthesize bridge = _bridge;
@synthesize locationManager;

RCT_EXPORT_MODULE();


-(instancetype)init
{
    self = [super init];
    if (self) {
        [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelInfo];
        [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelDebug];
        
        sqliteLogger = [[FMDBLogger alloc] initWithLogDirectory:[self loggerDirectory]];
        sqliteLogger.saveThreshold     = 1;
        sqliteLogger.saveInterval      = 0;
        sqliteLogger.maxAge            = 60 * 60 * 24 * 7; //  7 days
        sqliteLogger.deleteInterval    = 60 * 60 * 24;     //  1 day
        sqliteLogger.deleteOnEverySave = NO;

        locationManager = [[LocationManager alloc] init];
        locationManager.delegate = self;
//        locationManager.onLocationChanged = [self createLocationChangedHandler];
    }

    return self;
}

/**
 * configure plugin
 */
RCT_EXPORT_METHOD(configure:(NSDictionary*)configDictionary success:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #configure");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Config* config = [Config fromDictionary:configDictionary];
        NSError *error = nil;
        
        if ([locationManager configure:config error:&error]) {
            success(@[[NSNull null]]);
        } else {
            failure(@[@"Configuration error"]);
        }
    });
}

RCT_EXPORT_METHOD(start:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #start");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        [locationManager start:&error];
        if (error == nil) {
            success(@[[NSNull null]]);
        } else {
            failure(@[[error userInfo]]);
        }
    });
}

RCT_EXPORT_METHOD(stop:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #stop");
    NSError *error = nil;
    [locationManager stop:&error];
    if (error == nil) {
        success(@[[NSNull null]]);
    } else {
        failure(@[[error userInfo]]);
    }
}

RCT_EXPORT_METHOD(finish:(int)taskId)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #finish");
    [locationManager finish];
}

RCT_EXPORT_METHOD(isLocationEnabled:(RCTResponseSenderBlock)callback)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #isLocationEnabled");
    callback(@[@([locationManager isLocationEnabled])]);
}

RCT_EXPORT_METHOD(showAppSettings)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #showAppSettings");
    [locationManager showAppSettings];
}

RCT_EXPORT_METHOD(showLocationSettings)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #showLocationSettings");
    [locationManager showLocationSettings];
}

RCT_EXPORT_METHOD(watchLocationMode:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #watchLocationMode");
    //TODO: implement    
}

RCT_EXPORT_METHOD(stopWatchingLocationMode)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #stopWatchingLocationMode");
    //TODO: implement
}

RCT_EXPORT_METHOD(getLocations:(RCTResponseSenderBlock)callback)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #getLocations");
    //TODO: implement
}

RCT_EXPORT_METHOD(deleteLocation:(int)locationId success:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #deleteLocation");
    //TODO: implement
}

RCT_EXPORT_METHOD(deleteAllLocations:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #deleteAllLocations");
    //TODO: implement
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

- (NSString *)loggerDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    
    return [basePath stringByAppendingPathComponent:@"SQLiteLogger"];
}

- (void) onAuthorizationChanged:(NSInteger)authStatus
{
    //TODO: implement
}

- (void) onLocationChanged:(NSMutableDictionary*)location
{
    RCTLogInfo(@"RCTBackgroundGeolocation onLocationChanged");
    [self sendEvent:@"location" dictionary:location];
}

- (void) onStationaryChanged:(NSMutableDictionary*)location
{
    RCTLogInfo(@"RCTBackgroundGeolocation onStationaryChanged");
    [self sendEvent:@"stationary" dictionary:location];
}

- (void) onError:(NSError*)error
{
    RCTLogInfo(@"RCTBackgroundGeolocation onStationaryChanged");
    [self sendEvent:@"stationary" dictionary:[error userInfo]];
}

@end
