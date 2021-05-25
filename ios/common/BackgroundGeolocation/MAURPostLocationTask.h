//
//  MAURPostLocationTask.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 27/04/2018.
//  Copyright © 2018 mauron85. All rights reserved.
//

#ifndef MAURPostLocationTask_h
#define MAURPostLocationTask_h

#import "MAURConfig.h"
#import "MAURLocation.h"

@class MAURPostLocationTask;

@protocol MAURPostLocationTaskDelegate <NSObject>

@optional
- (void)postLocationTaskRequestedAbortUpdates:(MAURPostLocationTask * _Nonnull)task;
- (void)postLocationTaskHttpAuthorizationUpdates:(MAURPostLocationTask * _Nonnull)task;

@end

@interface MAURPostLocationTask : NSObject

@property (nonatomic, weak) MAURConfig * _Nullable config;
@property (nonatomic, weak) id<MAURPostLocationTaskDelegate> _Nullable delegate;

- (void) add:(MAURLocation * _Nonnull)location;
- (void) start;
- (void) stop;
- (void) sync;

+ (void) setLocationTransform:(MAURLocationTransform _Nullable)transform;
+ (MAURLocationTransform _Nullable) locationTransform;

@end

#endif /* MAURPostLocationTask_h */
