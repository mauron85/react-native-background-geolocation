//
//  MAURBackgroundLocationTest.m
//  BackgroundGeolocationTests
//
//  Created by Marian Hello on 12/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MAURLocation.h"

@interface MAURBackgroundLocationTest : XCTestCase

@end

@implementation MAURBackgroundLocationTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTimeToDictionary {
    NSDateFormatter *RFC3339DateFormatter = [[NSDateFormatter alloc] init];
    RFC3339DateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    RFC3339DateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    RFC3339DateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSString *string = @"2016-01-01T00:00:00+01:00";
    
    MAURLocation *bgloc1 = [[MAURLocation alloc] init];
    bgloc1.time = [RFC3339DateFormatter dateFromString:string];
    
    NSDictionary *data = [bgloc1 toDictionary];
    
    XCTAssertEqual([[data objectForKey:@"time"] doubleValue], 1451602800000);
    XCTAssertEqual([bgloc1.time timeIntervalSince1970] * 1000, 1451602800000);
}

- (void)testObjectCopying {
    MAURLocation *bgloc1 = [[MAURLocation alloc] init];
    bgloc1.latitude = [NSNumber numberWithDouble:12];
    bgloc1.longitude = [NSNumber numberWithDouble:11];
    bgloc1.radius = [NSNumber numberWithDouble:50];
    
    MAURLocation *stationaryLocation = [bgloc1 copy];
//    stationaryLocation.type = @"stationary";
    
    XCTAssertTrue([bgloc1.radius isEqualToNumber:[NSNumber numberWithDouble:50]]);
//    XCTAssertTrue([stationaryLocation.type isEqualToString:@"stationary"]);
}

- (void)testDistanceFromLocation {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    const double latitude1 = 49.1634594;
    const double longitude1 = 20.273454;
    const double latitude2 = 49.1260825;
    const double longitude2 = 20.4350187;
    
    MAURLocation *bgloc1 = [[MAURLocation alloc] init];
    MAURLocation *bgloc2 = [[MAURLocation alloc] init];
    bgloc1.latitude = [NSNumber numberWithDouble:latitude1];
    bgloc1.longitude = [NSNumber numberWithDouble:longitude1];
    bgloc2.latitude = [NSNumber numberWithDouble:latitude2];
    bgloc2.longitude = [NSNumber numberWithDouble:longitude2];

    CLLocation *location1 = [[CLLocation alloc]initWithLatitude:latitude1 longitude:longitude1];
    CLLocation *location2 = [[CLLocation alloc]initWithLatitude:latitude2 longitude:longitude2];

    double apple_dist = [location1 distanceFromLocation:location2];
    double bgloc_dist = [bgloc1 distanceFromLocation:bgloc2];
    XCTAssertEqualWithAccuracy(bgloc_dist, apple_dist, 20, "Our implementation of distance %f should equal Apple %f", bgloc_dist, apple_dist);
}

- (void)testLocationIsBeyond {
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    const double latitude1 = 49.134873;
    const double longitude1 = 20.209260;
    const double latitude2 = 49.14088;
    const double longitude2 = 20.225382;
    
    MAURLocation *bgloc1 = [[MAURLocation alloc] init];
    MAURLocation *bgloc2 = [[MAURLocation alloc] init];
    bgloc1.latitude = [NSNumber numberWithDouble:latitude1];
    bgloc1.longitude = [NSNumber numberWithDouble:longitude1];
    bgloc2.latitude = [NSNumber numberWithDouble:latitude2];
    bgloc2.longitude = [NSNumber numberWithDouble:longitude2];

    XCTAssertTrue([bgloc1 isBeyond:bgloc2 radius:100], "Expecting bgloc1 to not be beyond bgloc2 and radius 100m");
    XCTAssertTrue([bgloc1 isBeyond:bgloc2 radius:1000], "Expecting bgloc1 to not be beyond bgloc2 and radius 1000m");
    XCTAssertTrue(![bgloc1 isBeyond:bgloc2 radius:10000], "Expecting bgloc1 to be beyond bgloc2 and radius 10000m");
}

- (void)testIfSignificantlyNewerLocationIsBetter {
    const double latitude1 = 49.134873;
    const double longitude1 = 20.209260;
    const double latitude2 = 49.14088;
    const double longitude2 = 20.225382;
    const int oldtime = 1451602800; //Fri Jan 01 2016 00:00:00 GMT+0100 (CET)
    const int newtime = 1451610000; //Fri Jan 01 2016 00:02:00 GMT+0100 (CET)
    
    MAURLocation *older = [[MAURLocation alloc] init];
    MAURLocation *newer = [[MAURLocation alloc] init];
    older.latitude = [NSNumber numberWithDouble:latitude1];
    older.longitude = [NSNumber numberWithDouble:longitude1];
    older.time = [[NSDate alloc]initWithTimeIntervalSince1970:oldtime];
    newer.latitude = [NSNumber numberWithDouble:latitude2];
    newer.longitude = [NSNumber numberWithDouble:longitude2];
    newer.time = [[NSDate alloc]initWithTimeIntervalSince1970:newtime];
 
    XCTAssertTrue([newer isBetterLocation:older]);
}

- (void)testIfLocationWithBetterAccuracyAndSameTimeIsBetter {
    const double latitude1 = 49.134873;
    const double longitude1 = 20.209260;
    const double latitude2 = 49.14088;
    const double longitude2 = 20.225382;
    const double accuracy = 400;
    const double betterAccuracy = 100;
    const int time = 1451602800;
    
    MAURLocation *lessAccurate = [[MAURLocation alloc] init];
    MAURLocation *moreAccurate = [[MAURLocation alloc] init];
    lessAccurate.latitude = [NSNumber numberWithDouble:latitude1];
    lessAccurate.longitude = [NSNumber numberWithDouble:longitude1];
    lessAccurate.time = [[NSDate alloc]initWithTimeIntervalSince1970:time];
    lessAccurate.accuracy = [NSNumber numberWithDouble:accuracy];
    moreAccurate.latitude = [NSNumber numberWithDouble:latitude2];
    moreAccurate.longitude = [NSNumber numberWithDouble:longitude2];
    moreAccurate.time = [[NSDate alloc]initWithTimeIntervalSince1970:time];
    moreAccurate.accuracy = [NSNumber numberWithDouble:betterAccuracy];
    
    XCTAssertTrue([moreAccurate isBetterLocation:lessAccurate]);
}

- (void)testIflLocationWithNilAccuracyIsInvalid
{
    MAURLocation *loc = [[MAURLocation alloc] init];
    XCTAssertFalse([loc hasAccuracy]);
}

- (void) testIfLocationWithZeroAccuracyIsInvalid
{
    MAURLocation *loc = [[MAURLocation alloc] init];
    loc.accuracy = [NSNumber numberWithInt:0];
    XCTAssertTrue([loc hasAccuracy]);
}

- (void) testIfLocationWithAccuracyAboveZeroIsValid
{
    MAURLocation *loc = [[MAURLocation alloc] init];
    loc.accuracy = [NSNumber numberWithInt:10];
    XCTAssertTrue([loc isValid]);
}

- (void)testIflLocationWithTimeMoreThenOneDayFromNowIsInvalid
{
    MAURLocation *loc = [[MAURLocation alloc] init];
    loc.accuracy = [[NSNumber alloc] initWithInt:1];
    loc.time = [[[NSDate alloc] init] dateByAddingTimeInterval:186400];
    XCTAssertTrue(![loc hasTime]);
}

- (void)testIflLocationWithTimeNowIsValid
{
    MAURLocation *loc = [[MAURLocation alloc] init];
    loc.accuracy = [[NSNumber alloc] initWithInt:1];
    loc.time = [[NSDate alloc] init];
    XCTAssertTrue([loc isValid]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
