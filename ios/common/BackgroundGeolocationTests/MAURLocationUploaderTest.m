//
//  MAURLocationUploaderTest.m
//  BackgroundGeolocationTests
//
//  Created by Marian Hello on 07/07/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MAURBackgroundSync.h"
#import "MAURSQLiteLocationDAO.h"

@interface BackgroundSyncTest : XCTestCase

@end

@implementation BackgroundSyncTest

- (void)setUp {
    [super setUp];
    MAURSQLiteLocationDAO *locationDAO = [MAURSQLiteLocationDAO sharedInstance];
    [locationDAO clearDatabase];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSync {
    MAURSQLiteLocationDAO *locationDAO = [MAURSQLiteLocationDAO sharedInstance];
    MAURLocation *location;
    
    for (int i = 0; i < 10; i++) {
        location = [[MAURLocation alloc] init];
        location.time = [NSDate dateWithTimeIntervalSince1970:1465511097774.577+i];
        location.accuracy = [NSNumber numberWithDouble:5+i];
        location.speed = [NSNumber numberWithDouble:31.67+i];
        location.heading = [NSNumber numberWithDouble:298.83+i];
        location.altitude = [NSNumber numberWithDouble:940+i];
        location.latitude = [NSNumber numberWithDouble:37.35439853+i];
        location.longitude = [NSNumber numberWithDouble:-122.1100721+i];
        location.provider = @"TEST";
        location.locationProvider = [NSNumber numberWithInt:-1];
        
        [locationDAO persistLocation:location];
    }
    
    MAURBackgroundSync *uploader = [[MAURBackgroundSync alloc] init];
    [uploader sync:@"http://192.168.81.15:3000/testSync" withTemplate:nil withHttpHeaders:nil];
    sleep(5);
    
}

@end
