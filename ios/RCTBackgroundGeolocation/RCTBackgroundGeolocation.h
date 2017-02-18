//
//  RCTBackgroundGeolocation.h
//  RCTBackgroundGeolocation
//
//  Created by Marian Hello on 04/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif
#import "LocationManager.h"

@interface RCTBackgroundGeolocation : NSObject <RCTBridgeModule, LocationManagerDelegate>

@property (nonatomic, strong) LocationManager* locationManager;

@end
