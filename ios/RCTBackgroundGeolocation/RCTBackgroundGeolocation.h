//
//  RCTBackgroundGeolocation.h
//  RCTBackgroundGeolocation
//
//  Created by Marian Hello on 04/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>
#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#else
#import "RCTBridgeModule.h"
#endif
#import "MAURProviderDelegate.h"

@interface RCTBackgroundGeolocation : NSObject <RCTBridgeModule, MAURProviderDelegate, UNUserNotificationCenterDelegate>

@end
