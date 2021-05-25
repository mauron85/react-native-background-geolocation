//
//  MAURSQLiteConfigurationDAOTest.m
//  BackgroundGeolocationTests
//
//  Created by Marian Hello on 01/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MAURConfig.h"
#import "MAURSQLiteConfigurationDAO.h"

@interface MAURSQLiteConfigurationDAOTest : XCTestCase

@end

@implementation MAURSQLiteConfigurationDAOTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEmptyConfiguration {
    MAURSQLiteConfigurationDAO *dao = [MAURSQLiteConfigurationDAO sharedInstance];
    XCTAssertTrue([dao clearDatabase]);
    MAURConfig *config = [dao retrieveConfiguration];
    XCTAssertNil(config);
}

- (void)testPersistConfiguration {
    MAURSQLiteConfigurationDAO *dao = [MAURSQLiteConfigurationDAO sharedInstance];
    MAURConfig *config = [[MAURConfig alloc] init];
    
    BOOL success = [dao persistConfiguration:config];
    config = [dao retrieveConfiguration];

    XCTAssertTrue(success);
    XCTAssertFalse([config hasStationaryRadius]);
    XCTAssertFalse([config hasDistanceFilter]);
    XCTAssertFalse([config hasDesiredAccuracy]);
    XCTAssertFalse([config hasDebug]);
    XCTAssertFalse([config hasActivityType]);
    XCTAssertFalse([config hasActivitiesInterval]);
    XCTAssertFalse([config hasStopOnTerminate]);
    XCTAssertFalse([config hasUrl]);
    XCTAssertFalse([config hasSyncUrl]);
    XCTAssertFalse([config hasSyncThreshold]);
    XCTAssertFalse([config hasHttpHeaders]);
    XCTAssertFalse([config hasSaveBatteryOnBackground]);
    XCTAssertFalse([config hasMaxLocations]);
    XCTAssertFalse([config hasPauseLocationUpdates]);
    XCTAssertFalse([config hasLocationProvider]);
}


- (void)testRetrieveConfiguration {
    MAURSQLiteConfigurationDAO *dao = [MAURSQLiteConfigurationDAO sharedInstance];
    MAURConfig *config = [[MAURConfig alloc] init];
    config.stationaryRadius = [NSNumber numberWithInt:99];
    config.distanceFilter = [NSNumber numberWithInt:20];
    config.desiredAccuracy = [NSNumber numberWithInt:30];
    config._debug = [NSNumber numberWithBool:YES];
    config.activityType = @"MyActivity";
    config.activitiesInterval = [NSNumber numberWithInt:1234];
    config._stopOnTerminate = [NSNumber numberWithBool:YES];
    config.url = @"http://server:3000/locations";
    config.syncUrl = @"http://server:3000/sync";
    config.syncThreshold = [NSNumber numberWithInt:100];
    config.httpHeaders = [[NSMutableDictionary alloc] init];
    [config.httpHeaders setObject:@"bar" forKey:@"foo"];
    config._saveBatteryOnBackground = [NSNumber numberWithBool:YES];
    config.maxLocations = [NSNumber numberWithInt:10];
    config._pauseLocationUpdates = [NSNumber numberWithBool:YES];
    config.locationProvider = [NSNumber numberWithInt:2];

    [dao persistConfiguration:config];
    MAURConfig *stored = [dao retrieveConfiguration];
    
    XCTAssertEqualObjects(config.stationaryRadius, stored.stationaryRadius);
    XCTAssertEqualObjects(config.distanceFilter, stored.distanceFilter);
    XCTAssertEqualObjects(config.desiredAccuracy, stored.desiredAccuracy);
    XCTAssertEqual([config isDebugging], [stored isDebugging]);
    XCTAssertEqualObjects(config.activityType, stored.activityType);
    XCTAssertEqualObjects(config.activitiesInterval, stored.activitiesInterval);
    XCTAssertEqual([config stopOnTerminate], [stored stopOnTerminate]);
    XCTAssertEqualObjects(config.url, stored.url);
    XCTAssertEqualObjects(config.syncUrl, stored.syncUrl);
    XCTAssertEqualObjects(config.syncThreshold, stored.syncThreshold);
    XCTAssertEqualObjects(config.httpHeaders, stored.httpHeaders);
    XCTAssertEqual([config saveBatteryOnBackground], [stored saveBatteryOnBackground]);
    XCTAssertEqualObjects(config.maxLocations, stored.maxLocations);
    XCTAssertEqual([config pauseLocationUpdates], [stored pauseLocationUpdates]);
    XCTAssertEqualObjects(config.locationProvider, stored.locationProvider);
}


@end
