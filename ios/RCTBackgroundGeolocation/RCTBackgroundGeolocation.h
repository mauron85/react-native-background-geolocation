//
//  RCTBackgroundGeolocation.h
//  RCTBackgroundGeolocation
//
//  Created by Marian Hello on 04/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#if __has_include(<React/RCTBridgeModule.h>)
    #import <React/RCTBridgeModule.h>
    #import <React/RCTEventEmitter.h>
#else
    #import "RCTBridgeModule.h"
    #import "RCTEventEmitter.h"
#endif
#import "LocationManager.h"

@interface RCTBackgroundGeolocation : RCTEventEmitter <RCTBridgeModule, LocationManagerDelegate>

@property (nonatomic, strong) LocationManager* locationManager;

@end
