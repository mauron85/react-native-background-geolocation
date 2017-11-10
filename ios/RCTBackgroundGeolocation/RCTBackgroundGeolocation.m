//
//  RCTBackgroundGeolocation.m
//  RCTBackgroundGeolocation
//
//  Created by Marian Hello on 04/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import "RCTBackgroundGeolocation.h"
#if __has_include("RCTLog.h")
#import "RCTLog.h"
#else
#import <React/RCTLog.h>
#endif
#if __has_include("RCTEventDispatcher.h")
#import "RCTEventDispatcher.h"
#else
#import <React/RCTEventDispatcher.h>
#endif
#import "Logging.h"
#import "BackgroundTaskManager.h"

#define isNull(value) value == nil || [value isKindOfClass:[NSNull class]]

@implementation RCTBackgroundGeolocation

FMDBLogger *sqliteLogger;

@synthesize bridge = _bridge;
@synthesize facade;

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
        
        [DDLog addLogger:sqliteLogger withLevel:DDLogLevelDebug];

        facade = [[BackgroundGeolocationFacade alloc] init];
        facade.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppPause:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppResume:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    }

    return self;
}

/**
 * configure plugin
 */
RCT_EXPORT_METHOD(configure:(NSDictionary*)configDictionary success:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #configure");
    Config* config = [Config fromDictionary:configDictionary];
    NSError *error = nil;
    
    if ([facade configure:config error:&error]) {
        success(@[[NSNull null]]);
    } else {
        failure(@[@"Configuration error"]);
    }
}

RCT_EXPORT_METHOD(start)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #start");
    NSError *error = nil;
    [facade start:&error];

    if (error == nil) {
        [self sendEvent:@"start"];
    } else {
        [self sendEvent:@"error" resultAsDictionary:[error userInfo]];
    }
}

RCT_EXPORT_METHOD(stop)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #stop");
    NSError *error = nil;
    [facade stop:&error];

    if (error == nil) {
        [self sendEvent:@"stop"];
    } else {
        [self sendEvent:@"error" resultAsDictionary:[error userInfo]];
    }
}

RCT_EXPORT_METHOD(switchMode:(NSNumber*)mode success:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #switchMode");
    [facade switchMode:[mode integerValue]];
}

RCT_EXPORT_METHOD(isLocationEnabled:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #isLocationEnabled");
    success(@[@([facade isLocationEnabled])]);
}

RCT_EXPORT_METHOD(showAppSettings)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #showAppSettings");
    [facade showAppSettings];
}

RCT_EXPORT_METHOD(showLocationSettings)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #showLocationSettings");
    [facade showLocationSettings];
}

RCT_EXPORT_METHOD(getLocations:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #getLocations");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *locations = [facade getLocations];
        NSMutableArray* dictionaryLocations = [[NSMutableArray alloc] initWithCapacity:[locations count]];
        for (Location* location in locations) {
            [dictionaryLocations addObject:[location toDictionary]];
        }
        success(@[dictionaryLocations]);
    });
}

RCT_EXPORT_METHOD(getValidLocations:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #getValidLocations");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *locations = [facade getValidLocations];
        NSMutableArray* dictionaryLocations = [[NSMutableArray alloc] initWithCapacity:[locations count]];
        for (Location* location in locations) {
            [dictionaryLocations addObject:[location toDictionary]];
        }
        success(@[dictionaryLocations]);
    });
}

RCT_EXPORT_METHOD(deleteLocation:(int)locationId success:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #deleteLocation");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [facade deleteLocation:[NSNumber numberWithInt:locationId]];
    });
}

RCT_EXPORT_METHOD(deleteAllLocations:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #deleteAllLocations");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [facade deleteAllLocations];
    });
}

RCT_EXPORT_METHOD(getLogEntries:(int)limit success:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #getLogEntries");
//    limit = isNull(limit) ? [NSNumber numberWithInt:0] : limit;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *path = [[self loggerDirectory] stringByAppendingPathComponent:@"log.sqlite"];
        NSArray *logs = [LogReader getEntries:path limit:(NSInteger)limit];
        success(@[logs]);
    });
}

RCT_EXPORT_METHOD(getConfig:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #getConfig");
    Config *config = [facade getConfig];
    if (config == nil) {
        config = [[Config alloc] init]; // default config
    }
    success(@[[config toDictionary]]);
}

RCT_EXPORT_METHOD(checkStatus:(RCTResponseSenderBlock)success failure:(RCTResponseSenderBlock)failure)
{
    RCTLogInfo(@"RCTBackgroundGeolocation #checkStatus");
    BOOL isRunning = [facade isStarted];
    BOOL hasPermissions = [facade isLocationEnabled];
    NSInteger authorization = 1; // TODO: check authorization

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setObject:[NSNumber numberWithBool:isRunning] forKey:@"isRunning"];
    [dict setObject:[NSNumber numberWithBool:hasPermissions] forKey:@"hasPermissions"];
    [dict setObject:[NSNumber numberWithInteger:authorization] forKey:@"authorization"];

    success(@[dict]);
}

RCT_EXPORT_METHOD(startTask:(RCTResponseSenderBlock)callback)
{
    NSUInteger taskKey = [[BackgroundTaskManager sharedTasks] beginTask];
    callback(@[[NSNumber numberWithInteger:taskKey]]);
}

RCT_EXPORT_METHOD(endTask:(NSNumber* _Nonnull)taskKey)
{
    [[BackgroundTaskManager sharedTasks] endTaskWithKey:[taskKey integerValue]];
}

-(void) sendEvent:(NSString*)name
{
    NSString *event = [NSString stringWithFormat:@"%@", name];
    [_bridge.eventDispatcher sendDeviceEventWithName:event body:[NSNull null]];
}

-(void) sendEvent:(NSString*)name resultAsDictionary:(NSDictionary*)resultAsDictionary
{
    NSString *event = [NSString stringWithFormat:@"%@", name];
    [_bridge.eventDispatcher sendDeviceEventWithName:event body:resultAsDictionary];
}

-(void) sendEvent:(NSString*)name resultAsArray:(NSArray*)resultAsArray
{
    NSString *event = [NSString stringWithFormat:@"%@", name];
    [_bridge.eventDispatcher sendDeviceEventWithName:event body:resultAsArray];
}

-(void) sendEvent:(NSString*)name resultAsNumber:(NSNumber*)resultAsNumber
{
    NSString *event = [NSString stringWithFormat:@"%@", name];
    [_bridge.eventDispatcher sendDeviceEventWithName:event body:resultAsNumber];
}

- (NSString *)loggerDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    
    return [basePath stringByAppendingPathComponent:@"SQLiteLogger"];
}

- (void) onAuthorizationChanged:(NSInteger)authStatus
{
    RCTLogInfo(@"RCTBackgroundGeolocation onAuthorizationChanged");
    [self sendEvent:@"authorization" resultAsNumber:[NSNumber numberWithInteger:authStatus]];
}

- (void) onLocationChanged:(Location*)location
{
    RCTLogInfo(@"RCTBackgroundGeolocation onLocationChanged");
    [self sendEvent:@"location" resultAsDictionary:[location toDictionary]];
}

- (void) onStationaryChanged:(Location*)location
{
    RCTLogInfo(@"RCTBackgroundGeolocation onStationaryChanged");
    [self sendEvent:@"stationary" resultAsDictionary:[location toDictionary]];
}

- (void) onError:(NSError*)error
{
    RCTLogInfo(@"RCTBackgroundGeolocation onError");
    [self sendEvent:@"error" resultAsDictionary:[error userInfo]];
}

- (void) onLocationPause
{
    RCTLogInfo(@"RCTBackgroundGeoLocation location updates paused");
    [self sendEvent:@"stop"];
}

- (void) onLocationResume
{
    RCTLogInfo(@"RCTBackgroundGeoLocation location updates resumed");
    [self sendEvent:@"start"];
}

-(void) onAppResume:(NSNotification *)notification
{
    RCTLogInfo(@"RCTBackgroundGeoLocation resumed");
    [facade switchMode:FOREGROUND];
    [self sendEvent:@"foreground"];
}

-(void) onAppPause:(NSNotification *)notification
{
    RCTLogInfo(@"RCTBackgroundGeoLocation paused");
    [facade switchMode:BACKGROUND];
    [self sendEvent:@"background"];
}

/**@
 * on UIApplicationDidFinishLaunchingNotification
 */
-(void) onFinishLaunching:(NSNotification *)notification
{
    NSDictionary *dict = [notification userInfo];
    
    if ([dict objectForKey:UIApplicationLaunchOptionsLocationKey]) {
        DDLogInfo(@"RCTBackgroundGeolocation started by system on location event.");
        //        [manager switchOperationMode:BACKGROUND];
    }
}

-(void) onAppTerminate:(NSNotification *)notification
{
    DDLogInfo(@"RCTBackgroundGeoLocation appTerminate");
    [facade onAppTerminate];
}

@end
