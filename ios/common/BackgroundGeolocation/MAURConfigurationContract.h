//
//  MAURConfigurationContract.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 01/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#ifndef MAURConfigurationContract_h
#define MAURConfigurationContract_h

#define CC_TABLE_NAME                         "configuration"
#define CC_COLUMN_NAME_ID                     "id"
#define CC_COLUMN_NAME_NULLABLE               "NULLHACK"
#define CC_COLUMN_NAME_RADIUS                 "stationary_radius"
#define CC_COLUMN_NAME_DISTANCE_FILTER        "distance_filter"
#define CC_COLUMN_NAME_DESIRED_ACCURACY       "desired_accuracy"
#define CC_COLUMN_NAME_DEBUG                  "debugging"
#define CC_COLUMN_NAME_ACTIVITY_TYPE          "activity_type"
#define CC_COLUMN_NAME_NOTIF_TITLE            "notification_title"
#define CC_COLUMN_NAME_NOTIF_TEXT             "notification_text"
#define CC_COLUMN_NAME_NOTIF_ICON_LARGE       "notification_icon_large"
#define CC_COLUMN_NAME_NOTIF_ICON_SMALL       "notification_icon_small"
#define CC_COLUMN_NAME_NOTIF_COLOR            "notification_icon_color"
#define CC_COLUMN_NAME_STOP_TERMINATE         "stop_terminate"
#define CC_COLUMN_NAME_START_BOOT             "start_boot"
#define CC_COLUMN_NAME_START_FOREGROUND       "start_foreground"
#define CC_COLUMN_NAME_STOP_ON_STILL          "stop_still"
#define CC_COLUMN_NAME_LOCATION_PROVIDER      "service_provider"
#define CC_COLUMN_NAME_INTERVAL               "interval"
#define CC_COLUMN_NAME_FASTEST_INTERVAL       "fastest_interval"
#define CC_COLUMN_NAME_ACTIVITIES_INTERVAL    "activities_interval"
#define CC_COLUMN_NAME_URL                    "url"
#define CC_COLUMN_NAME_SYNC_URL               "sync_url"
#define CC_COLUMN_NAME_SYNC_THRESHOLD         "sync_threshold"
#define CC_COLUMN_NAME_HEADERS                "http_headers"
#define CC_COLUMN_NAME_SAVE_BATTERY           "save_battery"
#define CC_COLUMN_NAME_MAX_LOCATIONS          "max_locations"
#define CC_COLUMN_NAME_PAUSE_LOCATION_UPDATES "pause_updates"
#define CC_COLUMN_NAME_TEMPLATE               "template"
#define CC_COLUMN_NAME_LAST_UPDATED_AT        "updated_at"

@interface MAURConfigurationContract : NSObject

+ (NSString*) createTableSQL;

@end

#endif /* MAURConfigurationContract_h */
