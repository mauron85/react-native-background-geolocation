//
//  ConfigTest.m
//  BackgroundGeolocationTests
//
//  Created by Marian Hello on 02/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Config.h"

@interface ConfigTest : XCTestCase

@end

@implementation ConfigTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit {
    Config *config = [[Config alloc] init];

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

- (void)testToDictionary {
    Config *config = [[Config alloc] init];
    NSDictionary *dict = [config toDictionary];

    XCTAssertNil(dict[@"url"]);
    XCTAssertNil(dict[@"syncUrl"]);
    XCTAssertNil(dict[@"httpHeaders"]);
    XCTAssertEqualObjects(dict[@"postTemplate"], [Config getDefaultTemplate]);
}

- (void)testBooleans {
    Config *config = [[Config alloc] init];
    
    config._debug = @YES;
    XCTAssertTrue([config isDebugging]);
    
    config._debug = @NO;
    XCTAssertFalse([config isDebugging]);
    
}

- (void)testNullToDictionary {
    Config *config = [[Config alloc] init];
    config.url = (id)[NSNull null];
    config.syncUrl = (id)[NSNull null];
    config.httpHeaders = (id)[NSNull null];
    config._template = (id)[NSNull null];
    
    NSDictionary *dict = [config toDictionary];
    XCTAssertEqualObjects(dict[@"url"], @"");
    XCTAssertEqualObjects(dict[@"syncUrl"], @"");
    XCTAssertEqualObjects(dict[@"httpHeaders"], @{});
    XCTAssertEqualObjects(dict[@"postTemplate"], [Config getDefaultTemplate]);
}

- (void)testMerge {
    Config *config1 = [[Config alloc] init];
    config1.distanceFilter = [NSNumber numberWithInt:666];
    Config *config2 = [[Config alloc] initWithDefaults];
    config2.distanceFilter = [NSNumber numberWithInt:999];
    
    Config *merger = [Config merge:config1 withConfig:config2];
    
    XCTAssertEqual(merger.distanceFilter.intValue, 999);
    XCTAssertEqualObjects(merger.activityType, @"OtherNavigation");
    XCTAssertEqual(config1.distanceFilter.intValue, 666);
    XCTAssertEqual(config2.distanceFilter.intValue, 999);
    XCTAssertNotEqual(merger.distanceFilter, config1.distanceFilter);
    XCTAssertEqual(merger.distanceFilter, config2.distanceFilter);
    XCTAssertNotEqual(config1.distanceFilter, config2.distanceFilter);
}

- (void)testArrayTemplateToString {
    Config *config = [[Config alloc] init];
    config._template = @[@"latitude", @"longitude", @"custom"];
    
    XCTAssertEqualObjects([config getTemplateAsString:nil], @"[\"latitude\",\"longitude\",\"custom\"]");
}

- (void)testDictionaryTemplateToString {
    Config *config = [[Config alloc] init];
    config._template = @{
                           @"lat": @"latitude",
                           @"lon": @"longitude",
                           @"foo": @"bar"
                        };
    
    XCTAssertEqualObjects([config getTemplateAsString:nil], @"{\"lat\":\"latitude\",\"lon\":\"longitude\",\"foo\":\"bar\"}");
}

- (void)testMergeEmpty {
    Config *config1 = [[Config alloc] init];
    Config *config2 = [[Config alloc] init];
    
    config1.url = @"url";
    config1.syncUrl = @"syncurl";
    
    config2.url = @"";
    config2.syncUrl = @"";

    Config *merger = [Config merge:config1 withConfig:config2];
    
    XCTAssertEqualObjects(merger.url, @"");
    XCTAssertEqualObjects(merger.syncUrl, @"");
}

- (void)testMergeNullFromDictionary {
    Config *config1 = [[Config alloc] init];

    config1.url = @"url";
    config1.syncUrl = @"syncurl";
    config1.httpHeaders = @{@"foo": @"bar"};
    config1._template = @{@"lat": @"@latitude"};
    
    NSDictionary *configProps = @{
                                  @"url": [NSNull null],
                                  @"syncUrl": [NSNull null],
                                  @"httpHeaders": [NSNull null],
                                  @"postTemplate": [NSNull null]
                                 };
    Config *config2 = [Config fromDictionary:configProps];
    
    XCTAssertFalse([config2 hasValidUrl]);
    XCTAssertFalse([config2 hasValidSyncUrl]);
    
    Config *merger = [Config merge:config1 withConfig:config2];
    
    XCTAssertEqualObjects(merger.url, @"");
    XCTAssertEqualObjects(merger.syncUrl, @"");
    XCTAssertEqualObjects(merger.httpHeaders, @{});
    XCTAssertEqualObjects(merger._template, [Config getDefaultTemplate]);
}

@end
