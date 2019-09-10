# @mauron85/react-native-background-geolocation

[![CircleCI](https://circleci.com/gh/mauron85/react-native-background-geolocation/tree/master.svg?style=shield)](https://circleci.com/gh/mauron85/react-native-background-geolocation/tree/master)
[![issuehunt-shield-v1](issuehunt-shield-v1.svg)](https://issuehunt.io/r/mauron85/react-native-background-geolocation/)

## We're moving

Npm package is now [@mauron85/react-native-background-geolocation](https://www.npmjs.com/package/@mauron85/react-native-background-geolocation)!

# Donation

Please support my work and continued development with your donation.

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6GW8FPTE6TV5J)

## Submitting issues

All new issues should follow instructions in [ISSUE_TEMPLATE.md](https://raw.githubusercontent.com/mauron85/react-native-background-geolocation/master/ISSUE_TEMPLATE.md).
A properly filled issue report will significantly reduce number of follow up questions and decrease issue resolving time.
Most issues cannot be resolved without debug logs. Please try to isolate debug lines related to your issue.
Instructions for how to prepare debug logs can be found in section [Debugging](#debugging).
If you're reporting an app crash, debug logs might not contain all the necessary information about the cause of the crash.
In that case, also provide relevant parts of output of `adb logcat` command.

## Issue Hunt

Fund your issues or feature request to drag attraction of developers. Checkout our [issue hunt page](https://issuehunt.io/r/mauron85/react-native-background-geolocation/issues).

# Android background service issues
There are repeatedly reported issues with some android devices not working in the background. Check if your device model is on  [dontkillmyapp list](https://dontkillmyapp.com) before you report new issue. For more information check out [dontkillmyapp.com](https://dontkillmyapp.com/problem).

Another confusing fact about Android services is concept of foreground services. Foreground service in context of Android OS is different thing than background geolocation service of this plugin (they're related thought). **Plugin's background geolocation service** actually **becomes foreground service** when app is in the background. Confusing, right? :D

If service wants to continue to run in the background, it must "promote" itself to `foreground service`. Foreground services must have visible notification, which is the reason, why you can't disable drawer notification.

The notification can only be disabled, when app is running in the foreground, by setting config option `startForeground: false` (this is the default option), but will always be visible in the background (if service was started).

Recommend you to read https://developer.android.com/about/versions/oreo/background

## Description
React Native fork of [cordova-plugin-background-geolocation](https://github.com/mauron85/cordova-plugin-background-geolocation)
with battery-saving "circular region monitoring" and "stop detection".

This plugin can be used for geolocation when the app is running in the foreground or background.

You can choose from following location providers:
* **DISTANCE_FILTER_PROVIDER**
* **ACTIVITY_PROVIDER**
* **RAW_PROVIDER**

See [Which provider should I use?](/PROVIDERS.md) for more information about providers.

## Dependencies

Versions of libraries and sdk versions used to compile this plugin can be overriden in
`android/build.gradle` with ext declaration.

When ext is not provided then following defaults will be used:

```
ext {
  compileSdkVersion = 28
  buildToolsVersion = "28.0.3"
  targetSdkVersion = 28
  minSdkVersion = 16
  supportLibVersion = "28.0.0"
  googlePlayServicesVersion = "11+"
}
```

## Compatibility

Due to the rapid changes being made in the React Native ecosystem, this module will support
only the latest version of React Native. Older versions will only be supported if they're
compatible with this module.

| Module           | React Native      |
|------------------|-------------------|
| 0.1.0 - 0.2.0    | 0.33              |
| >=0.3.0          | >=0.47            |
| >=0.6.0          | >=0.60            |

If you are using an older version of React Native with this module some features may be buggy.

If you are using `react-native-maps` or another lib that requires `Google Play Services` such as `Exponent.js`, then in addition to the instalation steps described here, you must set `Google Play Services` library version to match the version used by those libraries. (in this case `9.8.0`)

Add following to `android/build.gradle`
```
ext {
  googlePlayServicesVersion = "9.8.0"
}
```

## Example Apps

The repository [react-native-background-geolocation-example](https://github.com/mauron85/react-native-background-geolocation-example) hosts an example app for both iOS and Android platform.

## Quick example

```javascript
import React, { Component } from 'react';
import { Alert } from 'react-native';
import BackgroundGeolocation from '@mauron85/react-native-background-geolocation';

class BgTracking extends Component {
  componentDidMount() {
    BackgroundGeolocation.configure({
      desiredAccuracy: BackgroundGeolocation.HIGH_ACCURACY,
      stationaryRadius: 50,
      distanceFilter: 50,
      notificationTitle: 'Background tracking',
      notificationText: 'enabled',
      debug: true,
      startOnBoot: false,
      stopOnTerminate: true,
      locationProvider: BackgroundGeolocation.ACTIVITY_PROVIDER,
      interval: 10000,
      fastestInterval: 5000,
      activitiesInterval: 10000,
      stopOnStillActivity: false,
      url: 'http://192.168.81.15:3000/location',
      httpHeaders: {
        'X-FOO': 'bar'
      },
      // customize post properties
      postTemplate: {
        lat: '@latitude',
        lon: '@longitude',
        foo: 'bar' // you can also add your own properties
      }
    });

    BackgroundGeolocation.on('location', (location) => {
      // handle your locations here
      // to perform long running operation on iOS
      // you need to create background task
      BackgroundGeolocation.startTask(taskKey => {
        // execute long running task
        // eg. ajax post location
        // IMPORTANT: task has to be ended by endTask
        BackgroundGeolocation.endTask(taskKey);
      });
    });

    BackgroundGeolocation.on('stationary', (stationaryLocation) => {
      // handle stationary locations here
      Actions.sendLocation(stationaryLocation);
    });

    BackgroundGeolocation.on('error', (error) => {
      console.log('[ERROR] BackgroundGeolocation error:', error);
    });

    BackgroundGeolocation.on('start', () => {
      console.log('[INFO] BackgroundGeolocation service has been started');
    });

    BackgroundGeolocation.on('stop', () => {
      console.log('[INFO] BackgroundGeolocation service has been stopped');
    });

    BackgroundGeolocation.on('authorization', (status) => {
      console.log('[INFO] BackgroundGeolocation authorization status: ' + status);
      if (status !== BackgroundGeolocation.AUTHORIZED) {
        // we need to set delay or otherwise alert may not be shown
        setTimeout(() =>
          Alert.alert('App requires location tracking permission', 'Would you like to open app settings?', [
            { text: 'Yes', onPress: () => BackgroundGeolocation.showAppSettings() },
            { text: 'No', onPress: () => console.log('No Pressed'), style: 'cancel' }
          ]), 1000);
      }
    });

    BackgroundGeolocation.on('background', () => {
      console.log('[INFO] App is in background');
    });

    BackgroundGeolocation.on('foreground', () => {
      console.log('[INFO] App is in foreground');
    });

    BackgroundGeolocation.on('abort_requested', () => {
      console.log('[INFO] Server responded with 285 Updates Not Required');

      // Here we can decide whether we want stop the updates or not.
      // If you've configured the server to return 285, then it means the server does not require further update.
      // So the normal thing to do here would be to `BackgroundGeolocation.stop()`.
      // But you might be counting on it to receive location updates in the UI, so you could just reconfigure and set `url` to null.
    });

    BackgroundGeolocation.on('http_authorization', () => {
      console.log('[INFO] App needs to authorize the http requests');
    });

    BackgroundGeolocation.checkStatus(status => {
      console.log('[INFO] BackgroundGeolocation service is running', status.isRunning);
      console.log('[INFO] BackgroundGeolocation services enabled', status.locationServicesEnabled);
      console.log('[INFO] BackgroundGeolocation auth status: ' + status.authorization);

      // you don't need to check status before start (this is just the example)
      if (!status.isRunning) {
        BackgroundGeolocation.start(); //triggers start on start event
      }
    });

    // you can also just start without checking for status
    // BackgroundGeolocation.start();
  }

  componentWillUnmount() {
    // unregister all event listeners
    BackgroundGeolocation.removeAllListeners();
  }
}

export default BgTracking;
```

## Instalation

### Installation

Add the package to your project

```
yarn add @mauron85/react-native-background-geolocation
```

### Automatic setup

Since version 0.60 React Native does linking of modules [automatically](https://github.com/react-native-community/cli/blob/master/docs/autolinking.md). However it does it only for single module.
As plugin depends on additional 'common' module, it is required to link it with:

```
node ./node_modules/@mauron85/react-native-background-geolocation/scripts/postlink.js
```

### Manual setup

#### Android setup

In `android/settings.gradle`

```gradle
...
include ':@mauron85_react-native-background-geolocation-common'
project(':@mauron85_react-native-background-geolocation-common').projectDir = new File(rootProject.projectDir, '../node_modules/@mauron85/react-native-background-geolocation/android/common')
include ':@mauron85_react-native-background-geolocation'
project(':@mauron85_react-native-background-geolocation').projectDir = new File(rootProject.projectDir, '../node_modules/@mauron85/react-native-background-geolocation/android/lib')
...
```

In `android/app/build.gradle`

```gradle
dependencies {
    ...
    compile project(':@mauron85_react-native-background-geolocation')
    ...
}
```

Register the module (in `MainApplication.java`)

```java
import com.marianhello.bgloc.react.BackgroundGeolocationPackage;  // <--- Import Package

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

#### iOS setup

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Add `./node_modules/@mauron85/react-native-background-geolocation/ios/RCTBackgroundGeolocation.xcodeproj`
3. In the XCode project navigator, select your project, select the `Build Phases` tab and in the `Link Binary With Libraries` section add **libRCTBackgroundGeolocation.a**
4. Add `UIBackgroundModes` **location** to `Info.plist`
5. Add `NSMotionUsageDescription` **App requires motion tracking** to `Info.plist` (required by ACTIVITY_PROVIDER)

For iOS before version 11:

6. Add `NSLocationAlwaysUsageDescription` **App requires background tracking** to `Info.plist`

For iOS 11:

6. Add `NSLocationWhenInUseUsageDescription` **App requires background tracking** to `Info.plist`
7. Add `NSLocationAlwaysAndWhenInUseUsageDescription` **App requires background tracking** to `Info.plist`

## API

### configure(options, success, fail)

| Parameter | Type          | Platform | Description                                                                     |
|-----------|---------------|----------|---------------------------------------------------------------------------------|
| `options` | `JSON Object` | all      | Configure options                                                               |

Configure options:

| Parameter                 | Type              | Platform     | Description                                                                                                                                                                                                                                                                                                                                        | Provider*   | Default                    | 
|---------------------------|-------------------|--------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|----------------------------|
| `locationProvider`        | `Number`          | all          | Set location provider **@see** [PROVIDERS](/PROVIDERS.md)                                                                                                                                                                                                                                                                                          | N/A         | DISTANCE\_FILTER\_PROVIDER | 
| `desiredAccuracy`         | `Number`          | all          | Desired accuracy in meters. Possible values [HIGH_ACCURACY, MEDIUM_ACCURACY, LOW_ACCURACY, PASSIVE_ACCURACY]. Accuracy has direct effect on power drain. Lower accuracy = lower power drain.                                                                                                                                                       | all         | MEDIUM\_ACCURACY           | 
| `stationaryRadius`        | `Number`          | all          | Stationary radius in meters. When stopped, the minimum distance the device must move beyond the stationary location for aggressive background-tracking to engage.                                                                                                                                                                                  | DIS         | 50                         | 
| `debug`                   | `Boolean`         | all          | When enabled, the plugin will emit sounds for life-cycle events of background-geolocation! See debugging sounds table.                                                                                                                                                                                                                             | all         | false                      | 
| `distanceFilter`          | `Number`          | all          | The minimum distance (measured in meters) a device must move horizontally before an update event is generated. **@see** [Apple docs](https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/CLLocationManager/CLLocationManager.html#//apple_ref/occ/instp/CLLocationManager/distanceFilter).        | DIS,RAW     | 500                        | 
| `stopOnTerminate`         | `Boolean`         | all          | Enable this in order to force a stop() when the application terminated (e.g. on iOS, double-tap home button, swipe away the app).                                                                                                                                                                                                                  | all         | true                       | 
| `startOnBoot`             | `Boolean`         | Android      | Start background service on device boot.                                                                                                                                                                                                                                                                                                           | all         | false                      | 
| `interval`                | `Number`          | Android      | The minimum time interval between location updates in milliseconds. **@see** [Android docs](http://developer.android.com/reference/android/location/LocationManager.html#requestLocationUpdates(long,%20float,%20android.location.Criteria,%20android.app.PendingIntent)) for more information.                                                    | all         | 60000                      | 
| `fastestInterval`         | `Number`          | Android      | Fastest rate in milliseconds at which your app can handle location updates. **@see** [Android  docs](https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest.html#getFastestInterval()).                                                                                                                   | ACT         | 120000                     | 
| `activitiesInterval`      | `Number`          | Android      | Rate in milliseconds at which activity recognition occurs. Larger values will result in fewer activity detections while improving battery life.                                                                                                                                                                                                    | ACT         | 10000                      | 
| `stopOnStillActivity`     | `Boolean`         | Android      | @deprecated stop location updates, when the STILL activity is detected                                                                                                                                                                                                                                                                             | ACT         | true                       | 
| `notificationsEnabled`    | `Boolean`         | Android      | Enable/disable local notifications when tracking and syncing locations                                                                                                                                                                                                                                                                             | all         | true                       |
| `startForeground`         | `Boolean`         | Android      | Allow location sync service to run in foreground state. Foreground state also requires a notification to be presented to the user.                                                                                                                                                                                                                 | all         | false                      |
| `notificationTitle`       | `String` optional | Android      | Custom notification title in the drawer. (goes with `startForeground`)                                                                                                                                                                                                                                                                             | all         | "Background tracking"      | 
| `notificationText`        | `String` optional | Android      | Custom notification text in the drawer. (goes with `startForeground`)                                                                                                                                                                                                                                                                              | all         | "ENABLED"                  | 
| `notificationIconColor`   | `String` optional | Android      | The accent color to use for notification. Eg. **#4CAF50**. (goes with `startForeground`)                                                                                                                                                                                                                                                           | all         |                            | 
| `notificationIconLarge`   | `String` optional | Android      | The filename of a custom notification icon. **@see** Android quirks. (goes with `startForeground`)                                                                                                                                                                                                                                                 | all         |                            | 
| `notificationIconSmall`   | `String` optional | Android      | The filename of a custom notification icon. **@see** Android quirks. (goes with `startForeground`)                                                                                                                                                                                                                                                 | all         |                            | 
| `activityType`            | `String`          | iOS          | [AutomotiveNavigation, OtherNavigation, Fitness, Other] Presumably, this affects iOS GPS algorithm. **@see** [Apple docs](https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/CLLocationManager/CLLocationManager.html#//apple_ref/occ/instp/CLLocationManager/activityType) for more information | all         | "OtherNavigation"          | 
| `pauseLocationUpdates`    | `Boolean`         | iOS          | Pauses location updates when app is paused. **@see* [Apple docs](https://developer.apple.com/documentation/corelocation/cllocationmanager/1620553-pauseslocationupdatesautomatical?language=objc)                                                                                                                                                  | all         | false                      | 
| `saveBatteryOnBackground` | `Boolean`         | iOS          | Switch to less accurate significant changes and region monitory when in background                                                                                                                                                                                                                                                                 | all         | false                      | 
| `url`                     | `String`          | all          | Server url where to send HTTP POST with recorded locations **@see** [HTTP locations posting](#http-locations-posting)                                                                                                                                                                                                                              | all         |                            | 
| `syncUrl`                 | `String`          | all          | Server url where to send fail to post locations **@see** [HTTP locations posting](#http-locations-posting)                                                                                                                                                                                                                                         | all         |                            | 
| `syncThreshold`           | `Number`          | all          | Specifies how many previously failed locations will be sent to server at once                                                                                                                                                                                                                                                                      | all         | 100                        | 
| `httpHeaders`             | `Object`          | all          | Optional HTTP headers sent along in HTTP request                                                                                                                                                                                                                                                                                                   | all         |                            | 
| `maxLocations`            | `Number`          | all          | Limit maximum number of locations stored into db                                                                                                                                                                                                                                                                                                   | all         | 10000                      | 
| `postTemplate`            | `Object\|Array`   | all          | Customization post template **@see** [Custom post template](#custom-post-template)                                                                                                                                                                                                                                                                 | all         |                            | 

\*
DIS = DISTANCE\_FILTER\_PROVIDER
ACT = ACTIVITY\_PROVIDER
RAW = RAW\_PROVIDER


Partial reconfiguration is possible by later providing a subset of the configuration options:

```
BackgroundGeolocation.configure({
  debug: true
});
```

In this case new configuration options will be merged with stored configuration options and changes will be applied immediately.

**Important:** Because configuration options are applied partially, it's not possible to reset option to default value just by omitting it's key name and calling `configure` method. To reset configuration option to the default value, it's key must be set to `null`!

```
// Example: reset postTemplate to default
BackgroundGeolocation.configure({
  postTemplate: null
});
```

### getConfig(success, fail)
Platform: iOS, Android

Get current configuration. Method will return all configuration options and their values in success callback.
Because `configure` method can be called with subset of the configuration options only,
`getConfig` method can be used to check the actual applied configuration.

```
BackgroundGeolocation.getConfig(function(config) {
  console.log(config);
});
```

### start()
Platform: iOS, Android

Start background geolocation.

### stop()
Platform: iOS, Android

Stop background geolocation.

### getCurrentLocation(success, fail, options)
Platform: iOS, Android

One time location check to get current location of the device.

| Option parameter           | Type      | Description                                                                            |
|----------------------------|-----------|----------------------------------------------------------------------------------------|
| `timeout`                  | `Number`  | Maximum time in milliseconds device will wait for location                             |
| `maximumAge`               | `Number`  | Maximum age in milliseconds of a possible cached location that is acceptable to return |
| `enableHighAccuracy`       | `Boolean` | if true and if the device is able to provide a more accurate position, it will do so   |

| Success callback parameter | Type      | Description                                                    |
|----------------------------|-----------|----------------------------------------------------------------|
| `location`                 | `Object`  | location object (@see [Location event](#location-event))       |

| Error callback parameter   | Type      | Description                                                    |
|----------------------------|-----------|----------------------------------------------------------------|
| `code`                     | `Number`  | Reason of an error occurring when using the geolocating device |
| `message`                  | `String`  | Message describing the details of the error                    |

Error codes:

| Value | Associated constant  | Description                                                              |
|-------|----------------------|--------------------------------------------------------------------------|
| 1     | PERMISSION_DENIED    | Request failed due missing permissions                                   |
| 2     | LOCATION_UNAVAILABLE | Internal source of location returned an internal error                   |
| 3     | TIMEOUT              | Timeout defined by `option.timeout was exceeded                          |

### checkStatus(success, fail)

Check status of the service

| Success callback parameter | Type      | Description                                          |
|----------------------------|-----------|------------------------------------------------------|
| `isRunning`                | `Boolean` | true/false (true if service is running)              |
| `locationServicesEnabled`  | `Boolean` | true/false (true if location services are enabled)   |
| `authorization`            | `Number`  | authorization status                                 |

Authorization statuses:

* NOT_AUTHORIZED
* AUTHORIZED - authorization to run in background and foreground
* AUTHORIZED_FOREGROUND iOS only authorization to run in foreground only

Note: In the Android concept of authorization, these represent application permissions.

### showAppSettings()
Platform: Android >= 6, iOS >= 8.0

Show app settings to allow change of app location permissions.

### showLocationSettings()
Platform: Android

Show system settings to allow configuration of current location sources.

### getLocations(success, fail)
Platform: iOS, Android

Method will return all stored locations.
This method is useful for initial rendering of user location on a map just after application launch.

| Success callback parameter | Type    | Description                    |
|----------------------------|---------|--------------------------------|
| `locations`                | `Array` | collection of stored locations |

```javascript
BackgroundGeolocation.getLocations(
  function (locations) {
    console.log(locations);
  }
);
```

### getValidLocations(success, fail)
Platform: iOS, Android

Method will return locations which have not yet been posted to server.

| Success callback parameter | Type    | Description                    |
|----------------------------|---------|--------------------------------|
| `locations`                | `Array` | collection of stored locations |

### deleteLocation(locationId, success, fail)
Platform: iOS, Android

Delete location with locationId.

### deleteAllLocations(success, fail)
Note: You don't need to delete all locations. The plugin manages the number of stored locations automatically and the total count never exceeds the number as defined by `option.maxLocations`.

Platform: iOS, Android

Delete all stored locations.

Note: Locations are not actually deleted from database to avoid gaps in locationId numbering.
Instead locations are marked as deleted. Locations marked as deleted will not appear in output of `BackgroundGeolocation.getValidLocations`.

### switchMode(modeId, success, fail)
Platform: iOS

Normally the plugin will handle switching between **BACKGROUND** and **FOREGROUND** mode itself.
Calling switchMode you can override plugin behavior and force it to switch into other mode.

In **FOREGROUND** mode the plugin uses iOS local manager to receive locations and behavior is affected
by `option.desiredAccuracy` and `option.distanceFilter`.

In **BACKGROUND** mode plugin uses significant changes and region monitoring to receive locations
and uses `option.stationaryRadius` only.

```
// switch to FOREGROUND mode
BackgroundGeolocation.switchMode(BackgroundGeolocation.FOREGROUND_MODE);

// switch to BACKGROUND mode
BackgroundGeolocation.switchMode(BackgroundGeolocation.BACKGROUND_MODE);
```
### forceSync()
Platform: Android, iOS

Force sync of pending locations. Option `syncThreshold` will be ignored and
all pending locations will be immediately posted to `syncUrl` in single batch.

### getLogEntries(limit, fromId, minLevel, success, fail)
Platform: Android, iOS

Return all logged events. Useful for plugin debugging.

| Parameter  | Type          | Description                                                                                       |
|------------|---------------|---------------------------------------------------------------------------------------------------|
| `limit`    | `Number`      | limits number of returned entries                                                                 |
| `fromId`   | `Number`      | return entries after fromId. Useful if you plan to implement infinite log scrolling*              |
| `minLevel` | `String`      | return log entries above level. Available levels: ["TRACE", "DEBUG", "INFO", "WARN", "ERROR]      |
| `success`  | `Function`    | callback function which will be called with log entries                                           |

*[Example of infinite log scrolling](https://github.com/mauron85/react-native-background-geolocation-example/blob/master/src/scenes/Logs.js)

Format of log entry:

| Parameter   | Type          | Description                                                                                       |
|-------------|---------------|---------------------------------------------------------------------------------------------------|
| `id`        | `Number`      | id of log entry as stored in db                                                                   |
| `timestamp` | `Number`      | timestamp in milliseconds since beginning of UNIX epoch                                           |
| `level`     | `String`      | log level                                                                                         |
| `message`   | `String`      | log message                                                                                       |
| `stackTrace`| `String`      | recorded stacktrace (Android only, on iOS part of message)                                        |

### removeAllListeners(event)

Unregister all event listeners for given event. If parameter `event` is not provided then all event listeners will be removed.

## Events

| Name                | Callback param         | Platform     | Provider*   | Description                                      |
|---------------------|------------------------|--------------|-------------|--------------------------------------------------|
| `location`          | `Location`             | all          | all         | on location update                               |
| `stationary`        | `Location`             | all          | DIS,ACT     | on device entered stationary mode                |
| `activity`          | `Activity`             | Android      | ACT         | on activity detection                            |
| `error`             | `{ code, message }`    | all          | all         | on plugin error                                  |
| `authorization`     | `status`               | all          | all         | on user toggle location service                  |
| `start`             |                        | all          | all         | geolocation has been started                     |
| `stop`              |                        | all          | all         | geolocation has been stopped                     |
| `foreground`        |                        | Android      | all         | app entered foreground state (visible)           |
| `background`        |                        | Android      | all         | app entered background state                     |
| `abort_requested`   |                        | all          | all         | server responded with "285 Updates Not Required" |
| `http_authorization`|                        | all          | all         | server responded with "401 Unauthorized"         |

### Location event
| Location parameter     | Type      | Description                                                            |
|------------------------|-----------|------------------------------------------------------------------------|
| `id`                   | `Number`  | ID of location as stored in DB (or null)                               |
| `provider`             | `String`  | gps, network, passive or fused                                         |
| `locationProvider`     | `Number`  | location provider                                                      |
| `time`                 | `Number`  | UTC time of this fix, in milliseconds since January 1, 1970.           |
| `latitude`             | `Number`  | Latitude, in degrees.                                                  |
| `longitude`            | `Number`  | Longitude, in degrees.                                                 |
| `accuracy`             | `Number`  | Estimated accuracy of this location, in meters.                        |
| `speed`                | `Number`  | Speed if it is available, in meters/second over ground.                |
| `altitude`             | `Number`  | Altitude if available, in meters above the WGS 84 reference ellipsoid. |
| `bearing`              | `Number`  | Bearing, in degrees.                                                   |
| `isFromMockProvider`   | `Boolean` | (android only) True if location was recorded by mock provider          |
| `mockLocationsEnabled` | `Boolean` | (android only) True if device has mock locations enabled               |

Locations parameters `isFromMockProvider` and `mockLocationsEnabled` are not posted to `url` or `syncUrl` by default.
Both can be requested via option `postTemplate`.

Note: Do not use location `id` as unique key in your database as ids will be reused when `option.maxLocations` is reached.

Note: Android currently returns `time` as type of String (instead of Number) [@see issue #9685](https://github.com/facebook/react-native/issues/9685)

### Activity event
| Activity parameter | Type      | Description                                                            |
|--------------------|-----------|------------------------------------------------------------------------|
| `confidence`       | `Number`  | Percentage indicating the likelihood user is performing this activity. |
| `type`             | `String`  | "IN_VEHICLE", "ON_BICYCLE", "ON_FOOT", "RUNNING", "STILL",             |
|                    |           | "TILTING", "UNKNOWN", "WALKING"                                        |

Event listeners can registered with:

```
const eventSubscription = BackgroundGeolocation.on('event', callbackFn);
```

And unregistered:

```
eventSubscription.remove();
```

Note: Components should unregister all event listeners in `componentWillUnmount` method,
individually, or with `removeAllListeners`

## HTTP locations posting

All locations updates are recorded in the local db at all times. When the App is in foreground or background, in addition to storing location in local db,
the location callback function is triggered. The number of locations stored in db is limited by `option.maxLocations` and never exceeds this number.
Instead, old locations are replaced by new ones.

When `option.url` is defined, each location is also immediately posted to url defined by `option.url`.
If the post is successful, the location is marked as deleted in local db.

When `option.syncUrl` is defined, all locations that fail to post will be coalesced and sent in some time later in a single batch.
Batch sync takes place only when the number of failed-to-post locations reaches `option.syncTreshold`.
Locations are sent only in single batch when the number of locations reaches `option.syncTreshold`. (No individual locations will be sent)

The request body of posted locations is always an array, even when only one location is sent.

Warning: `option.maxLocations` has to be larger than `option.syncThreshold`. It's recommended to be 2x larger. In any other case the location syncing might not work properly.

## Custom post template

With `option.postTemplate` it is possible to specify which location properties should be posted to `option.url` or `option.syncUrl`. This can be useful to reduce the
number of bytes sent "over the "wire".

All wanted location properties have to be prefixed with `@`. For all available properties check [Location event](#location-event).

Two forms are supported:

**jsonObject**

```
BackgroundGeolocation.configure({
  postTemplate: {
    lat: '@latitude',
    lon: '@longitude',
    foo: 'bar' // you can also add your own properties
  }
});
```

**jsonArray**
```
BackgroundGeolocation.configure({
  postTemplate: ['@latitude', '@longitude', 'foo', 'bar']
});
```

Note: Keep in mind that all locations (even a single one) will be sent as an array of object(s), when postTemplate is `jsonObject` and array of array(s) for `jsonArray`!

### Android Headless Task (Experimental)

A special task that gets executed when the app is terminated, but the plugin was configured to continue running in the background (option `stopOnTerminate: false`). In this scenario the [Activity](https://developer.android.com/reference/android/app/Activity.html)
was killed by the system and all registered event listeners will not be triggered until the app is relaunched.

**Note:** Prefer configuration options `url` and `syncUrl` over headless task. Use it sparingly!

#### Task event
| Parameter          | Type      | Description                                                            |
|--------------------|-----------|------------------------------------------------------------------------|
| `event.name`       | `String`  | Name of the event [ "location", "stationary", "activity" ]             |
| `event.params`     | `Object`  | Event parameters. @see [Events](#events)                               |

Keep in mind that the callback function lives in an isolated scope. Variables from a higher scope cannot be referenced!

Following example requires [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) enabled backend server.

**Warning:** callback function must by `async`!

```
BackgroundGeolocation.headlessTask(async (event) => {
    if (event.name === 'location' ||
      event.name === 'stationary') {
        var xhr = new XMLHttpRequest();
        xhr.open('POST', 'http://192.168.81.14:3000/headless');
        xhr.setRequestHeader('Content-Type', 'application/json');
        xhr.send(JSON.stringify(event.params));
    }
});
```

**Important:**

After application is launched again (main activity becomes visible), it is important to call `start` method to rebind all event listeners.

```
BackgroundGeolocation.checkStatus(({ isRunning }) => {
  if (isRunning) {
    BackgroundGeolocation.start(); // service was running -> rebind all listeners
  }
});
```


### Transforming/filtering locations in native code

In some cases you might want to modify a location before posting, reject a location, or any other logic around incoming locations - in native code. There's an option of doing so with a headless task, but you may want to preserve battery, or do more complex actions that are not available in React.

In those cases you could register a location transform.

Android example:

When the `Application` is initialized (which also happens before services gets started in the background), write some code like this:

```
BackgroundGeolocationFacade.setLocationTransform(new LocationTransform() {
    @Nullable
    @Override
    public BackgroundLocation transformLocationBeforeCommit(@NonNull Context context, @NonNull BackgroundLocation location) {
    // `context` is available too if there's a need to use a value from preferences etc.

    // Modify the location
    location.setLatitude(location.getLatitude() + 0.018);

    // Return modified location
    return location;

    // You could return null to reject the location,
    // or if you did something else with the location and the library should not post or save it.
    }
});
```

iOS example:


In `didFinishLaunchingWithOptions` delegate method, write some code like this:

```
BackgroundGeolocationFacade.locationTransform = ^(MAURLocation * location) {
  // Modify the location
  location.latitude = @(location.latitude.doubleValue + 0.018);
  
  // Return modified location
  return location;
  
  // You could return null to reject the location,
  // or if you did something else with the location and the library should not post or save it.
};
```

### Advanced plugin configuration

#### Change Account Service Name (Android)

Add string resource "account_name" into "android/app/src/main/res/values/strings.xml"

```
<string name="account_name">Sync Locations</string>

```

### Example of backend server

[Background-geolocation-server](https://github.com/mauron85/background-geolocation-server) is a backend server written in nodejs with CORS - Cross-Origin Resource Sharing support.
There are instructions how to run it and simulate locations on Android, iOS Simulator and Genymotion.

## Debugging

## Submit crash log

TODO

## Debugging sounds
| Event                               | *ios*                             | *android*               |
|-------------------------------------|-----------------------------------|-------------------------|
| Exit stationary region              | Calendar event notification sound | dialtone beep-beep-beep |
| Geolocation recorded                | SMS sent sound                    | tt short beep           |
| Aggressive geolocation engaged      | SIRI listening sound              |                         |
| Passive geolocation engaged         | SIRI stop listening sound         |                         |
| Acquiring stationary location sound | "tick,tick,tick" sound            |                         |
| Stationary location acquired sound  | "bloom" sound                     | long tt beep            |

**NOTE:** For iOS  in addition, you must manually enable the *Audio and Airplay* background mode in *Background Capabilities* to hear these debugging sounds.


## Geofencing
Try using [react-native-boundary](https://github.com/eddieowens/react-native-boundary). Let's keep this plugin lightweight as much as possible.

## Changelog

See [CHANGES.md](/CHANGES.md)

See [变更（非官方中文版）](/CHANGES_zh-Hans.md)
