# react-native-mauron85-background-geolocation

# Donation

Please support my work and support continuous development by your donation.

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6GW8FPTE6TV5J)

## Description
React Native fork of [cordova-plugin-background-geolocation](https://github.com/mauron85/cordova-plugin-background-geolocation)
with battery-saving "circular region monitoring" and "stop detection".

Plugin can be used for geolocation when app is running in foreground or background.

On Android you can choose from two location location providers:
* **ANDROID_DISTANCE_FILTER_PROVIDER**
* **ANDROID_ACTIVITY_PROVIDER**

See [Which provider should I use?](https://github.com/mauron85/react-native-background-geolocation/blob/master/PROVIDERS.md) for more information about providers.

## Compatibility

Due to the rapid changes being made in the React Native ecosystem, this module will support
only latest version of React Native. Older versions will only be supported, if they're
compatible with this module.

| Required peerDependencies  | Version |
|----------------------------|---------|
| React Native               | >=0.33  |
| React                      | >=15.3.1|

If you are using an older version of React Native with this module some features may be buggy.

If you are using react-native-maps or another lib that requires react-native-maps such as Exponent.js or airbnb's react-native-maps then aditionally to the instalation steps described here, you must also change `node_modules/react-native-mauron85-background-geolocation/android/lib/build.gradle` in order to `gms:play-services-locations` match the same version used by those libraries. (in this case `9.8.0`)

```
dependencies {
    ...
    compile 'com.google.android.gms:play-services-location:9.8.0'
    ...
}
```

## Submitting issues

All new issues should follow instructions in [ISSUE_TEMPLATE.md](https://raw.githubusercontent.com/mauron85/react-native-background-geolocation/master/ISSUE_TEMPLATE.md).
Properly filled issue report will significantly reduce number of follow up questions and decrease issue resolving time.
Most issues cannot be resolved without debug logs. Please try to isolate debug lines related to your issue.
Instructions how to prepare debug logs can be found in section [Debugging](#debugging).
If you're reporting app crash, debug logs might not contain all needed informations about the cause of the crash.
In that case, also provide relevant parts of output of `adb logcat` command.

## Example Apps

Repository [react-native-background-geolocation-example](https://github.com/mauron85/react-native-background-geolocation-example) is hosting example app for both iOS and Android platform.

## Quick example

```javascript
import React, { Component } from 'react';
import BackgroundGeolocation from 'react-native-mauron85-background-geolocation';

class BgTracking extends Component {
  componentWillMount() {
    BackgroundGeolocation.configure({
      desiredAccuracy: 10,
      stationaryRadius: 50,
      distanceFilter: 50,
      locationTimeout: 30,
      notificationTitle: 'Background tracking',
      notificationText: 'enabled',
      debug: true,
      startOnBoot: false,
      stopOnTerminate: false,
      locationProvider: BackgroundGeolocation.provider.ANDROID_ACTIVITY_PROVIDER,
      interval: 10000,
      fastestInterval: 5000,
      activitiesInterval: 10000,
      stopOnStillActivity: false,
      url: 'http://192.168.81.15:3000/location',
      httpHeaders: {
        'X-FOO': 'bar'
      }
    });

    BackgroundGeolocation.on('location', (location) => {
      //handle your locations here
      Actions.sendLocation(location);
    });

    BackgroundGeolocation.on('stationary', (stationaryLocation) => {
      //handle stationary locations here
      Actions.sendLocation(stationaryLocation);
    });

    BackgroundGeolocation.on('error', (error) => {
      console.log('[ERROR] BackgroundGeolocation error:', error);
    });

    BackgroundGeolocation.start(() => {
      console.log('[DEBUG] BackgroundGeolocation started successfully');    
    });
  }
}

export default BgTracking;
```

## Instalation

Add package to your project

```
npm install react-native-mauron85-background-geolocation --save
```

### Android setup

In `android/settings.gradle`

```gradle
...
include ':react-native-mauron85-background-geolocation', ':app'
project(':react-native-mauron85-background-geolocation').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-mauron85-background-geolocation/android/lib')
...
```

In `android/app/build.gradle`

```gradle
dependencies {
    ...
    compile project(':react-native-mauron85-background-geolocation')
    ...
}
```

In `android/src/main/res/values/strings.xml`

Properties `@account_type` and `@content_authority` should be prefixed with your application package class.

```xml
<resources>
<!-- Make sure you override following in your app res/values/strings.xml -->
    <string name="app_name">APP_NAME</string>
    <string name="account_type">com.yourcompany.account</string>
    <string name="content_authority">com.yourcompany.authority</string>
</resources>
```

Register module (in `MainApplication.java`)

```java
import com.marianhello.react.BackgroundGeolocationPackage;  // <--- Import Package

public class MainApplication extends Application implements ReactApplication {
  ...
  /**
   * A list of packages used by the app. If the app uses additional views
   * or modules besides the default ones, add more packages here.
   */
  @Override
  protected List<ReactPackage> getPackages() {
      return Arrays.<ReactPackage>asList(
          new MainReactPackage(),
          new BackgroundGeolocationPackage() // <---- Add the Package
      );
  }
  ...
}
```

#### Dependencies
You will need to ensure that you have installed the following items through the Android SDK Manager:

| Name                       | Version |
|----------------------------|---------|
| Android SDK Tools          | 24.4.1  |
| Android SDK Platform-tools | 23.1    |
| Android SDK Build-tools    | 23.0.1  |
| Android Support Repository | 25      |
| Android Support Library    | 23.1.1  |
| Google Play Services       | 29      |
| Google Repository          | 24      |


### iOS setup

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. add `./node_modules/react-native-mauron85-background-geolocation/ios/RCTBackgroundGeolocation.xcodeproj`
3. In the XCode project navigator, select your project, select the `Build Phases` tab and in the `Link Binary With Libraries` section add **libRCTBackgroundGeolocation.a**
4. add `UIBackgroundModes` **location** to `Info.plist`
5. add `NSLocationAlwaysUsageDescription` **App requires background tracking** to `Info.plist`


## API

### configure(success, fail, options)

| Parameter | Type          | Platform | Description                                                                     |
|-----------|---------------|----------|---------------------------------------------------------------------------------|
| `options` | `JSON Object` | all      | Configure options                                                               |

Configure options:

| Parameter                 | Type              | Platform     | Description                                                                                                                                                                                                                                                                                                                                        |
|---------------------------|-------------------|--------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `desiredAccuracy`         | `Number`          | all          | Desired accuracy in meters. Possible values [0, 10, 100, 1000]. The lower the number, the more power devoted to GeoLocation resulting in higher accuracy readings. 1000 results in lowest power drain and least accurate readings. @see Apple docs                                                                                                 |
| `stationaryRadius`        | `Number`          | all          | Stationary radius in meters. When stopped, the minimum distance the device must move beyond the stationary location for aggressive background-tracking to engage.                                                                                                                                                                                  |
| `debug`                   | `Boolean`         | all          | When enabled, the plugin will emit sounds for life-cycle events of background-geolocation! See debugging sounds table.                                                                                                                                                                                                                             |
| `distanceFilter`          | `Number`          | all          | The minimum distance (measured in meters) a device must move horizontally before an update event is generated. **@see** [Apple docs](https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/CLLocationManager/CLLocationManager.html#//apple_ref/occ/instp/CLLocationManager/distanceFilter).        |
| `stopOnTerminate`         | `Boolean`         | all          | Enable this in order to force a stop() when the application terminated (e.g. on iOS, double-tap home button, swipe away the app). (default true)                                                                                                                                                                                                   |
| `startOnBoot`             | `Boolean`         | Android      | Start background service on device boot. (default false)                                                                                                                                                                                                                                                                                           |
| `startForeground`         | `Boolean`         | Android      | If false location service will not be started in foreground and no notification will be shown. (default true)                                                                                                                                                                                                                                      |
| `interval`                | `Number`          | Android      | The minimum time interval between location updates in milliseconds. **@see** [Android docs](http://developer.android.com/reference/android/location/LocationManager.html#requestLocationUpdates(long,%20float,%20android.location.Criteria,%20android.app.PendingIntent) for more information.                                                     |
| `notificationTitle`       | `String` optional | Android      | Custom notification title in the drawer.                                                                                                                                                                                                                                                                                                           |
| `notificationText`        | `String` optional | Android      | Custom notification text in the drawer.                                                                                                                                                                                                                                                                                                            |
| `notificationIconColor`   | `String` optional | Android      | The accent color to use for notification. Eg. **#4CAF50**.                                                                                                                                                                                                                                                                                         |
| `notificationIconLarge`   | `String` optional | Android      | The filename of a custom notification icon. See android quirks.                                                                                                                                                                                                                                                                                    |
| `notificationIconSmall`   | `String` optional | Android      | The filename of a custom notification icon. See android quirks.                                                                                                                                                                                                                                                                                    |
| `locationProvider`        | `Number`          | Android      | Set location provider **@see** [wiki](https://github.com/mauron85/cordova-plugin-background-geolocation/wiki/Android-providers)                                                                                                                                                                                                                    |
| `activityType`            | `String`          | iOS          | [AutomotiveNavigation, OtherNavigation, Fitness, Other] Presumably, this affects iOS GPS algorithm. **@see** [Apple docs](https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/CLLocationManager/CLLocationManager.html#//apple_ref/occ/instp/CLLocationManager/activityType) for more information |
| `url`                     | `String`          | all          | Server url where to send HTTP POST with recorded locations **@see** [HTTP locations posting](#http-locations-posting)                                                                                                                                                                                                                              |
| `syncUrl`                 | `String`          | all          | Server url where to send fail to post locations **@see** [HTTP locations posting](#http-locations-posting)                                                                                                                                                                                                                                         |
| `syncThreshold`           | `Number`          | all          | Specifies how many previously failed locations will be sent to server at once (default: 100)                                                                                                                                                                                                                                                       |
| `httpHeaders`             | `Object`          | all          | Optional HTTP headers sent along in HTTP request                                                                                                                                                                                                                                                                                                   |
| `saveBatteryOnBackground` | `Boolean`         | iOS          | Switch to less accurate significant changes and region monitory when in background (default)                                                                                                                                                                                                                                                       |
| `maxLocations`            | `Number`          | all          | Limit maximum number of locations stored into db (default: 10000)                                                                                                                                                                                                                                                                                  |

Following options are specific to provider as defined by locationProvider option
### ANDROID_ACTIVITY_PROVIDER provider options

| Parameter             | Type      | Platform | Description                                                                                                                                                                                                                      |
|-----------------------|-----------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `interval`            | `Number`  | Android  | Rate in milliseconds at which your app prefers to receive location updates. **@see** [android docs](https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest.html#getInterval())          |
| `fastestInterval`     | `Number`  | Android  | Fastest rate in milliseconds at which your app can handle location updates. **@see** [android  docs](https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest.html#getFastestInterval()). |
| `activitiesInterval`  | `Number`  | Android  | Rate in milliseconds at which activity recognition occurs. Larger values will result in fewer activity detections while improving battery life.                                                                                  |
| `stopOnStillActivity` | `Boolean` | Android  | stop() is forced, when the STILL activity is detected (default is true)                                                                                                                                                          |

Location callback will be called with one argument - location object, which tries to mimic w3c [Coordinates interface](http://dev.w3.org/geo/api/spec-source.html#coordinates_interface).

| Callback parameter | Type      | Description                                                            |
|--------------------|-----------|------------------------------------------------------------------------|
| `locationId`       | `Number`  | ID of location as stored in DB (or null)                               |
| `provider`         | `String`  | gps, network, passive or fused                                         |
| `locationProvider` | `Number`  | Location provider                                                      |
| `debug`            | `Boolean` | true if location recorded as part of debug                             |
| `time`             | `Number`  | UTC time of this fix, in milliseconds since January 1, 1970.           |
| `latitude`         | `Number`  | latitude, in degrees.                                                  |
| `longitude`        | `Number`  | longitude, in degrees.                                                 |
| `accuracy`         | `Number`  | estimated accuracy of this location, in meters.                        |
| `speed`            | `Number`  | speed if it is available, in meters/second over ground.                |
| `altitude`         | `Number`  | altitude if available, in meters above the WGS 84 reference ellipsoid. |
| `bearing`          | `Number`  | bearing, in degrees.                                                   |

Note: Android currently returns `time` as type of String (instead of Number) [@see issue #9685](https://github.com/facebook/react-native/issues/9685)

### start()
Platform: iOS, Android

Start background geolocation.

### stop()
Platform: iOS, Android

Stop background geolocation.

### isLocationEnabled(success, fail)
Platform: iOS, Android

One time check for status of location services. In case of error, fail callback will be executed.

| Success callback parameter | Type      | Description                                          |
|----------------------------|-----------|------------------------------------------------------|
| `enabled`                  | `Boolean` | true/false (true when location services are enabled) |

### showAppSettings()
Platform: Android >= 6, iOS >= 8.0

Show app settings to allow change of app location permissions.

### showLocationSettings()
Platform: iOS, Android

Show system settings to allow configuration of current location sources.

### watchLocationMode(success, fail)
Platform: iOS, Android

Method can be used to detect user changes in location services settings.
If user enable or disable location services then success callback will be executed.
In case or error (SettingNotFoundException) fail callback will be executed.

| Success callback parameter | Type      | Description                                          |
|----------------------------|-----------|------------------------------------------------------|
| `enabled`                  | `Boolean` | true/false (true when location services are enabled) |

### stopWatchingLocationMode()
Platform: iOS, Android

Stop watching for location mode changes.

### getLocations(success, fail)
Platform: iOS, Android

Method will return all stored locations.
This method is useful for initial rendering of user location on a map just after application launch.

NOTE: Returned locations does not contain locationId.

| Success callback parameter | Type    | Description                    |
|----------------------------|---------|--------------------------------|
| `locations`                | `Array` | collection of stored locations |

```javascript
backgroundGeolocation.getLocations(
  function (locations) {
    console.log(locations);
  }
);
```
### switchMode(modeId, success, fail)
Platform: iOS

Normally plugin will handle switching between **BACKGROUND** and **FOREGROUND** mode itself.
Calling switchMode you can override plugin behavior and force plugin to switch into other mode.

In **FOREGROUND** mode plugin uses iOS local manager to receive locations and behavior is affected
by `option.desiredAccuracy` and `option.distanceFilter`.

In **BACKGROUND** mode plugin uses significant changes and region monitoring to receive locations
and uses `option.stationaryRadius` only.

```
// switch to FOREGROUND mode
backgroundGeolocation.switchMode(backgroundGeolocation.mode.FOREGROUND);

// switch to BACKGROUND mode
backgroundGeolocation.switchMode(backgroundGeolocation.mode.BACKGROUND);
```

### getLogEntries(limit, success, fail)
Platform: Android

Return all logged events. Useful for plugin debugging.
Parameter `limit` limits number of returned entries.
**@see [Debugging](#debugging)** for more information.

## HTTP locations posting

All locations updates are recorded in local db at all times. When App is in foreground or background in addition to storing location in local db, location callback function is triggered. Number of location stored in db is limited by `option.maxLocations` a never exceeds this number. Instead old locations are replaced by new ones.

When `option.url` is defined, each location is also immediately posted to url defined by `option.url`. If post is successful, the location is marked as deleted in local db. All failed to post locations will be coalesced and send in some time later in one single batch. Batch sync takes place only when number of failed to post locations reaches `option.syncTreshold`.
Optionally different url for batch sync can be defined by `option.syncUrl`. If `option.syncUrl` is not set then `option.url` will be used instead.

When only `option.syncUrl` is defined. Locations are send only in single batch, when number of locations reaches `option.syncTreshold`. (No individual location will be send)

Request body of posted locations is always array, even when only one location is sent.

### Example of express (nodejs) server
```javascript
var express    = require('express');
var bodyParser = require('body-parser');

var app = express();

// parse application/json
app.use(bodyParser.json({ type : '*/*' })); // force json

app.post('/locations', function(request, response){
    console.log('Headers:\n', request.headers);
    console.log('Body:\n', request.body);
    console.log('------------------------------');
    response.sendStatus(200);
});

app.listen(3000);
console.log('Server started...');
```
## Debugging

Plugin logs all activity into database. Logs are retained for 7 days.
You can use following snippets in your app.

Print Android logs:

```
backgroundGeolocation.getLogEntries(100, printAndroidLogs);
```

Print iOS logs:

```
backgroundGeolocation.getLogEntries(100, printIosLogs);
```

```javascript
function padLeft(nr, n, str) {
  return Array(n - String(nr).length + 1).join(str || '0') + nr;
}

function printLogs(logEntries, logFormatter, COLORS, MAX_LINES) {
  MAX_LINES = MAX_LINES || 100; // maximum lines to print per batch
  var batch = Math.ceil(logEntries.length / MAX_LINES);
  var logLines = Array(MAX_LINES); //preallocate memory prevents GC
  var logLinesColor = Array(MAX_LINES * 2);
  for (var i = 0; i < batch; i++) {
    var it = 0;
    var logEntriesPart = logEntries.slice((i * MAX_LINES), (i + 1) * MAX_LINES);
    for (var j = 0; j < logEntriesPart.length; j++) {
      var logEntry = logEntriesPart[j];
      logLines[j] = logFormatter(logEntry);
      logLinesColor[it++] = ('background:white;color:black');
      logLinesColor[it++] = (COLORS[logEntry.level]);      
    }
    if (logEntriesPart.length < MAX_LINES) {
      console.log.apply(console, [logLines.slice(0,logEntriesPart.length).join('\n')]
        .concat(logLinesColor.slice(0,logEntriesPart.length*2)));
    } else {
      console.log.apply(console, [logLines.join('\n')].concat(logLinesColor));
    }
  }
}

function printAndroidLogs(logEntries) {
  var COLORS = Object();
  COLORS['ERROR'] = 'background:white;color:red';
  COLORS['WARN'] = 'background:black;color:yellow';
  COLORS['INFO'] = 'background:white;color:blue';
  COLORS['TRACE'] = 'background:white;color:black';
  COLORS['DEBUG'] = 'background:white;color:black';

  var logFormatter = function(logEntry) {
    var d = new Date(logEntry.timestamp);
    var dateStr = [d.getFullYear(), padLeft(d.getMonth()+1,2), padLeft(d.getDate(),2)].join('/');
    var timeStr = [padLeft(d.getHours(),2), padLeft(d.getMinutes(),2), padLeft(d.getSeconds(),2)].join(':');
    return ['%c[', dateStr, ' ', timeStr, '] %c', logEntry.logger, ':', logEntry.message].join('');
  }

  return printLogs(logEntries, logFormatter, COLORS);
}

function printIosLogs(logEntries) {
  var COLORS = Array();
  COLORS[1] = 'background:white;color:red';
  COLORS[2] = 'background:black;color:yellow';
  COLORS[4] = 'background:white;color:blue';
  COLORS[8] = 'background:white;color:black';
  COLORS[16] = 'background:white;color:black';

  var logFormatter = function(logEntry) {
    var d = new Date(logEntry.timestamp * 1000);
    var dateStr = [d.getFullYear(), padLeft(d.getMonth()+1,2), padLeft(d.getDate(),2)].join('/');
    var timeStr = [padLeft(d.getHours(),2), padLeft(d.getMinutes(),2), padLeft(d.getSeconds(),2)].join(':');
    return ['%c[', dateStr, ' ', timeStr, '] %c', logEntry.logger, ':', logEntry.message].join('');
  }

  return printLogs(logEntries, logFormatter, COLORS);
}
```

### Debugging sounds
| *ios*                               | *android*                         |                         |
|-------------------------------------|-----------------------------------|-------------------------|
| Exit stationary region              | Calendar event notification sound | dialtone beep-beep-beep |
| Geolocation recorded                | SMS sent sound                    | tt short beep           |
| Aggressive geolocation engaged      | SIRI listening sound              |                         |
| Passive geolocation engaged         | SIRI stop listening sound         |                         |
| Acquiring stationary location sound | "tick,tick,tick" sound            |                         |
| Stationary location acquired sound  | "bloom" sound                     | long tt beep            |

**NOTE:** For iOS  in addition, you must manually enable the *Audio and Airplay* background mode in *Background Capabilities* to hear these debugging sounds.

## Geofencing
There is nice cordova plugin [cordova-plugin-geofence](https://github.com/cowbell/cordova-plugin-geofence), which does exactly that. Let's keep this plugin lightweight as much as possible.

## Changelog

See [CHANGES.md](/CHANGES.md)
