//
//  ActivityLocationProvider.m
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 14/09/2016.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActivityLocationProvider.h"
#import "Logging.h"

static NSString * const TAG = @"ActivityLocationProvider";
static NSString * const Domain = @"com.marianhello";

@implementation ActivityLocationProvider

- (instancetype) init
{
    self = [super init];
    
    if (self == nil) {
        return self;
    }
    
    return self;
}

- (void) onCreate {/* noop */}

- (void) onDestroy {/* noop */}

- (BOOL) configure:(Config*)config error:(NSError * __autoreleasing *)outError
{
    if (outError != nil) {
        NSDictionary *errorDictionary = @{ @"code": [NSNumber numberWithInt:NOT_IMPLEMENTED], @"message" : @"Not implemented yet" };
        *outError = [NSError errorWithDomain:Domain code:NOT_IMPLEMENTED userInfo:errorDictionary];
    }
    
    return NO;
}

- (BOOL) start:(NSError * __autoreleasing *)outError
{
    if (outError != nil) {
        NSDictionary *errorDictionary = @{ @"code": [NSNumber numberWithInt:NOT_IMPLEMENTED], @"message" : @"Not implemented yet" };
        *outError = [NSError errorWithDomain:Domain code:NOT_IMPLEMENTED userInfo:errorDictionary];
    }

    return NO;
}

- (BOOL) stop:(NSError * __autoreleasing *)outError
{
    if (outError != nil) {
        NSDictionary *errorDictionary = @{ @"code": [NSNumber numberWithInt:NOT_IMPLEMENTED], @"message" : @"Not implemented yet" };
        *outError = [NSError errorWithDomain:Domain code:NOT_IMPLEMENTED userInfo:errorDictionary];
    }

    return NO;
}

- (void) switchMode:(BGOperationMode)mode
{
    /* do nothing */
}

@end
