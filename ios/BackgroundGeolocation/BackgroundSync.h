//
//  BackgroundSync.h
//
//  Created by Marian Hello on 07/07/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef BackgroundSync_h
#define BackgroundSync_h

#import <Foundation/Foundation.h>

@interface BackgroundSync : NSObject

- (instancetype) init;
- (NSString*) status;
- (void) sync:(NSString*)url onLocationThreshold:(NSInteger)threshold withTemplate:(id)locationTemplate withHttpHeaders:(NSMutableDictionary*)httpHeaders;
- (void) cancel;

@end

#endif /* BackgroundSync_h */
