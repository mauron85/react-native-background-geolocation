//
//  LocationUploader.h
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 07/07/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef LocationUploader_h
#define LocationUploader_h

#import <Foundation/Foundation.h>

@interface LocationUploader : NSObject

- (instancetype) init;
- (NSString*) status;
- (void) sync:(NSString*)url onLocationThreshold:(NSInteger)threshold;
- (void) cancel;

@end

#endif /* LocationUploader_h */