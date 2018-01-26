//
//  ProviderDelegate.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 14/09/2016.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef ProviderDelegate_h
#define ProviderDelegate_h

#import "Location.h"
#import "Activity.h"
//#import "LocationController.h"

typedef NS_ENUM(NSInteger, BGErrorCode) {
    BG_PERMISSION_DENIED = 1000,
    BG_SETTINGS_ERROR    = 1001,
    BG_CONFIGURE_ERROR   = 1002,
    BG_SERVICE_ERROR     = 1003,
    BG_JSON_ERROR        = 1004,
    BG_NOT_IMPLEMENTED   = 9999
};


typedef NS_ENUM(NSInteger, BGAuthorizationStatus) {
    NOT_DETERMINED = 0,
    ALLOWED = 1,
    DENIED = 2
};

@protocol ProviderDelegate <NSObject>

- (void) onAuthorizationChanged:(BGAuthorizationStatus)authStatus;
- (void) onLocationChanged:(Location*)location;
- (void) onStationaryChanged:(Location*)location;
- (void) onLocationPause;
- (void) onLocationResume;
- (void) onActivityChanged:(Activity*)activity;
- (void) onError:(NSError*)error;

@end

#endif /* ProviderDelegate_h */
