//
//  MAURProviderDelegate.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 14/09/2016.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef MAURProviderDelegate_h
#define MAURProviderDelegate_h

#import "MAURLocation.h"
#import "MAURActivity.h"
//#import "MAURLocationController.h"

typedef NS_ENUM(NSInteger, MAURBGErrorCode) {
    MAURBGPermissionDenied = 1000,
    MAURBGSettingsError    = 1001,
    MAURBGConfigureError   = 1002,
    MAURBGServiceError     = 1003,
    MAURBGJsonError        = 1004,
    MAURBGNotImplemented   = 9999
};

typedef NS_ENUM(NSInteger, MAURLocationAuthorizationStatus) {
    MAURLocationAuthorizationDenied = 0,
    MAURLocationAuthorizationAllowed = 1,
    MAURLocationAuthorizationAlways = MAURLocationAuthorizationAllowed,
    MAURLocationAuthorizationForeground = 2,
    MAURLocationAuthorizationNotDetermined = 99,
};

typedef NS_ENUM(NSInteger, MAUROperationalMode) {
    MAURBackgroundMode = 0,
    MAURForegroundMode = 1
};

@protocol MAURProviderDelegate <NSObject>

- (void) onAuthorizationChanged:(MAURLocationAuthorizationStatus)authStatus;
- (void) onLocationChanged:(MAURLocation*)location;
- (void) onStationaryChanged:(MAURLocation*)location;
- (void) onLocationPause;
- (void) onLocationResume;
- (void) onActivityChanged:(MAURActivity*)activity;
- (void) onAbortRequested;
- (void) onHttpAuthorization;
- (void) onError:(NSError*)error;

@end

#endif /* MAURProviderDelegate_h */
