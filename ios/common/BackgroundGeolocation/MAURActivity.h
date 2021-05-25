//
//  MAURActivity.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 13/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#ifndef MAURActivity_h
#define MAURActivity_h

#import <Foundation/Foundation.h>

@interface MAURActivity : NSObject <NSCopying>

@property NSNumber *confidence;
@property NSString *type;

- (NSDictionary*) toDictionary;

@end

#endif /* MAURActivity_h */
