//
//  RCTBackgroundGeolocation.h
//  RCTBackgroundGeolocation
//
//  Created by Marian Hello on 04/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import "RCTBridgeModule.h"
#import "BackgroundGeolocationDelegate.h"

@interface RCTBackgroundGeolocation : NSObject <RCTBridgeModule>

@property (nonatomic, strong) BackgroundGeolocationDelegate* bgDelegate;

@end
