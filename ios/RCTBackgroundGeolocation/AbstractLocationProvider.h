//
//  AbstractLocationProvider.h
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 14/09/2016.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef AbstractLocationProvider_h
#define AbstractLocationProvider_h

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "LocationDelegate.h"
#import "Config.h"

// Debug sounds for bg-geolocation life-cycle events.
// http://iphonedevwiki.net/index.php/AudioServices
#define exitRegionSound         1005
#define locationSyncSound       1004
#define paceChangeYesSound      1110
#define paceChangeNoSound       1112
#define acquiringLocationSound  1103
#define acquiredLocationSound   1052
#define locationErrorSound      1073

typedef NS_ENUM(NSInteger, BGErrorCode) {
    UNKNOWN_LOCATION_PROVIDER = 1,
    NOT_IMPLEMENTED = 99
};

typedef NS_ENUM(NSInteger, BGOperationMode) {
    BACKGROUND = 0,
    FOREGROUND = 1
};

@protocol LocationProvider <NSObject>

- (void) onCreate;
- (void) onDestroy;
- (BOOL) configure:(Config*)config error:(NSError * __autoreleasing *)outError;
- (BOOL) start:(NSError * __autoreleasing *)outError;
- (BOOL) stop:(NSError * __autoreleasing *)outError;
- (void) switchMode:(BGOperationMode)mode;

@end

@interface AbstractLocationProvider : NSObject//<LocationProvider>

@property (weak, nonatomic) id<LocationDelegate> delegate;

- (void) notify:(NSString*)message;

@end


#endif /* AbstractLocationProvider_h */
