//
//  MAURBackgroundSync.h
//
//  Created by Marian Hello on 07/07/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef MAURBackgroundSync_h
#define MAURBackgroundSync_h

#import <Foundation/Foundation.h>

@class MAURBackgroundSync;

@protocol MAURBackgroundSyncDelegate <NSObject>

@optional
- (void)backgroundSyncRequestedAbortUpdates:(MAURBackgroundSync * _Nonnull)task;
- (void)backgroundSyncHttpAuthorizationUpdates:(MAURBackgroundSync * _Nonnull)task;

@end

@interface MAURBackgroundSync : NSObject

@property (nonatomic, weak) id<MAURBackgroundSyncDelegate> _Nullable delegate;

- (instancetype) init;
- (NSString*) status;
- (void) sync:(NSString * _Nonnull)url withTemplate:(id)locationTemplate withHttpHeaders:(NSMutableDictionary * _Nullable)httpHeaders;
- (void) cancel;

@end

#endif /* MAURBackgroundSync_h */
