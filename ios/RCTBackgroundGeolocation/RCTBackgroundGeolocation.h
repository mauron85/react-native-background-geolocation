//
//  RCTBackgroundGeolocation.h
//  RCTBackgroundGeolocation
//
//  Created by Marian Hello on 04/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#else
#import "RCTBridgeModule.h"
#endif
#import "BackgroundGeolocationFacade.h"

@interface RCTBackgroundGeolocation : NSObject <RCTBridgeModule, LocationDelegate>

@property (nonatomic, strong) BackgroundGeolocationFacade* facade;

@end
