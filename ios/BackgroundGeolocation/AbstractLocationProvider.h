//
//  AbstractLocationProvider.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 14/09/2016.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef AbstractLocationProvider_h
#define AbstractLocationProvider_h

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "BackgroundGeolocationFacade.h"
#import "ProviderDelegate.h"
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

@protocol LocationProvider <NSObject>

- (void) onCreate;
- (void) onDestroy;
- (BOOL) onConfigure:(Config*)config error:(NSError * __autoreleasing *)outError;
- (BOOL) onStart:(NSError * __autoreleasing *)outError;
- (BOOL) onStop:(NSError * __autoreleasing *)outError;
- (void) onSwitchMode:(BGOperationMode)mode;

@end

@interface AbstractLocationProvider : NSObject//<LocationProvider>

@property (weak, nonatomic) id<ProviderDelegate> delegate;

- (void) notify:(NSString*)message;

@end


#endif /* AbstractLocationProvider_h */
