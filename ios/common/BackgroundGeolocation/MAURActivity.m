//
//  MAURActivity.m
//  BackgroundGeolocation
//
//  Created by Marian Hello on 13/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#import "MAURActivity.h"

@implementation MAURActivity

@synthesize type, confidence;

- (instancetype) init
{
    self = [super init];
    if (self != nil) {
        confidence = [NSNumber numberWithInt:0];
    }
    
    return self;
}

- (NSDictionary*) toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
    
    if (confidence != nil) [dict setObject:confidence forKey:@"confidence"];
    if (type != nil) [dict setObject:type forKey:@"type"];
    
    return dict;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"Activity: confidence=%@ type=%@", confidence, type];
    
}

-(id) copyWithZone: (NSZone *) zone
{
    MAURActivity *copy = [[[self class] allocWithZone: zone] init];
    if (copy) {
        copy.confidence = confidence;
        copy.type = type;
    }
    
    return copy;
}

@end
