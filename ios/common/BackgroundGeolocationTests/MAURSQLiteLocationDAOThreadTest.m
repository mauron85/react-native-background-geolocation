//
//  BackgroundGeolocationTest.m
//  BackgroundGeolocationTests
//
//  Created by Marian Hello on 10/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MAURSQLiteLocationDAO.h"

@interface PersistLocationInThread : NSObject
{
    
}
// class methods go here
- (void) noop;
- (void) persistLocation:(NSNumber *)value;
@end

@interface MAURSQLiteLocationDAOThreadTest : XCTestCase

@end

@implementation MAURSQLiteLocationDAOThreadTest

- (void)setUp {
    [super setUp];
    MAURSQLiteLocationDAO *locationDAO = [MAURSQLiteLocationDAO sharedInstance];
    [locationDAO clearDatabase];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGetAllLocationsMultiThread {
    MAURSQLiteLocationDAO *locationDAO = [MAURSQLiteLocationDAO sharedInstance];
    long unsigned threadsCount = 100;
    
    dispatch_queue_t queue = dispatch_queue_create("com.marianhello.SQLiteLocationDAOThreadTests", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < threadsCount; i++) {
        dispatch_group_async(group, queue, ^{
            MAURLocation *location = [[MAURLocation alloc] init];
            location.time = [NSDate dateWithTimeIntervalSince1970:100+i];
            location.accuracy = [NSNumber numberWithDouble:i];
            location.speed = [NSNumber numberWithDouble:32+i];
            location.heading = [NSNumber numberWithDouble:200+i];
            location.altitude = [NSNumber numberWithDouble:940+i];
            location.latitude = [NSNumber numberWithDouble:37+i];
            location.longitude = [NSNumber numberWithDouble:-22+i];
            location.provider = @"TEST";
            location.locationProvider = [NSNumber numberWithInt:-1];
            
            [locationDAO persistLocation:location];
        });
    }

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    NSMutableArray *locations = [NSMutableArray arrayWithArray:[locationDAO getAllLocations]];
    [locations sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];

    XCTAssertEqual([locations count], threadsCount, @"Number of stored location is %lu expecting %lu", (unsigned long)[locations count], threadsCount);
    
    for (int i = 0; i < threadsCount; i++) {
        MAURLocation *result = [locations objectAtIndex:i];
        XCTAssertTrue([result.time isEqualToDate:[NSDate dateWithTimeIntervalSince1970:100+i]], "time is %@ expecting %@", result.time, [NSDate dateWithTimeIntervalSince1970:100+i]);
        XCTAssertTrue([result.accuracy isEqualToNumber:[NSNumber numberWithDouble:i]], "accuracy is %@ expecting %@", result.accuracy, [NSNumber numberWithDouble:i]);
        XCTAssertTrue([result.speed isEqualToNumber:[NSNumber numberWithDouble:32+i]], "speed is %@ expecting %@", result.speed, [NSNumber numberWithDouble:32+i]);
        XCTAssertTrue([result.heading isEqualToNumber:[NSNumber numberWithDouble:200+i]], "heading is %@ expecting %@", result.heading, [NSNumber numberWithDouble:200+i]);
        XCTAssertTrue([result.altitude isEqualToNumber:[NSNumber numberWithDouble:940+i]], "altitude is %@ expecting %@", result.altitude, [NSNumber numberWithDouble:940+i]);
        XCTAssertTrue([result.latitude isEqualToNumber:[NSNumber numberWithDouble:37+i]], "latitude is %@ expecting %@", result.latitude, [NSNumber numberWithDouble:37+i]);
        XCTAssertTrue([result.longitude isEqualToNumber:[NSNumber numberWithDouble:-22+i]], "longitude is %@ expecting %@", result.longitude, [NSNumber numberWithDouble:-22+i]);
        XCTAssertTrue([result.provider isEqualToString:@"TEST"], @"provider is expected to be TEST");
        XCTAssertTrue([result.locationProvider isEqualToNumber:[NSNumber numberWithInt:-1]], "service_provider is %@ expecting %@", result.locationProvider, [NSNumber numberWithInt:-1]);
    }
}

@end
