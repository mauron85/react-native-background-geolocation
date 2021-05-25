//
//  MAURAbstractLocationProvider.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 14/09/2016.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef MAURAbstractLocationProvider_h
#define MAURAbstractLocationProvider_h

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MAURBackgroundGeolocationFacade.h"
#import "MAURProviderDelegate.h"
#import "MAURConfig.h"

// Debug sounds for bg-geolocation life-cycle events.
// http://iphonedevwiki.net/index.php/AudioServices
#define exitRegionSound         1005
#define locationSyncSound       1004
#define paceChangeYesSound      1110
#define paceChangeNoSound       1112
#define acquiringLocationSound  1103
#define acquiredLocationSound   1052
#define locationErrorSound      1073

@protocol MAURLocationProvider <NSObject>

- (void) onCreate;
- (void) onDestroy;
- (void) onTerminate;
- (BOOL) onConfigure:(MAURConfig*)config error:(NSError * __autoreleasing *)outError;
- (BOOL) onStart:(NSError * __autoreleasing *)outError;
- (BOOL) onStop:(NSError * __autoreleasing *)outError;
- (void) onSwitchMode:(MAUROperationalMode)mode;

@end

@interface MAURAbstractLocationProvider : NSObject//<LocationProvider>

@property (weak, nonatomic) id<MAURProviderDelegate> delegate;

- (void) onTerminate;
- (void) onSwitchMode:(MAUROperationalMode)mode;
- (void) notify:(NSString*)message;

@end


#endif /* MAURAbstractLocationProvider_h */
