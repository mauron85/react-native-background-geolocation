//
//  RCTBackgroundGeolocation.h
//  RCTBackgroundGeolocation
//
//  Created by Marian Hello on 04/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import "LocationManager.h"

@interface RCTBackgroundGeolocation : NSObject <RCTBridgeModule, LocationManagerDelegate>

@property (nonatomic, strong) LocationManager* locationManager;

@end
