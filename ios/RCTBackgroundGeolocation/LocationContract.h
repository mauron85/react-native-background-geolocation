//
//  LocationContract.h
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 23/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef LocationContract_h
#define LocationContract_h

#define LC_TABLE_NAME                      "location"
#define LC_COLUMN_NAME_ID                  "id"
#define LC_COLUMN_NAME_NULLABLE            "NULLHACK"
#define LC_COLUMN_NAME_TIME                "time"
#define LC_COLUMN_NAME_ACCURACY            "accuracy"
#define LC_COLUMN_NAME_SPEED               "speed"
#define LC_COLUMN_NAME_BEARING             "bearing"
#define LC_COLUMN_NAME_ALTITUDE            "altitude"
#define LC_COLUMN_NAME_LATITUDE            "latitude"
#define LC_COLUMN_NAME_LONGITUDE           "longitude"
#define LC_COLUMN_NAME_PROVIDER            "provider"
#define LC_COLUMN_NAME_LOCATION_PROVIDER   "service_provider"
#define LC_COLUMN_NAME_VALID               "valid"

@interface LocationContract : NSObject

+ (NSString*) createTableSQL;

@end


#endif /* LocationContract_h */
