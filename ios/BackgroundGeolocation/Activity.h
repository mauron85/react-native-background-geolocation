//
//  Activity.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 13/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#ifndef Activity_h
#define Activity_h

#import <Foundation/Foundation.h>

@interface Activity : NSObject <NSCopying>

@property NSNumber *confidence;
@property NSString *type;

- (NSDictionary*) toDictionary;

@end

#endif /* Activity_h */
