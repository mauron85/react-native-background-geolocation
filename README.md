# react-native-mauron85-background-geolocation

# Donation

Please support my work and support continuous development by your donation.

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6GW8FPTE6TV5J)

## Description
React Native fork of [cordova-plugin-background-geolocation](https://github.com/mauron85/cordova-plugin-background-geolocation)
with battery-saving "circular region monitoring" and "stop detection".

Plugin can be used for geolocation when app is running in foreground or background.

You can choose from following location providers:
* **DISTANCE_FILTER_PROVIDER**
* **ACTIVITY_PROVIDER**
* **RAW_PROVIDER**

See [Which provider should I use?](/PROVIDERS.md) for more information about providers.

## Breaking changes

### 0.4.x:

* start method doesn't accept callback (use .on("start") event)
* stop method doesn't accept callback (use .on("stop") event)
* for background syncing syncUrl option is required. In version 0.3.x if syncUrl was not set url was used.
* plugin constants are in directly BackgroundGeolocation namespace. (check index.js)
* location property locationId renamed to just id
* iOS pauseLocationUpdates now default to false (becuase iOS docs now states that you need to restart manually if you set it to true)
* iOS no more requires to call finish method. Instead you can optionally start long running task with startTask

## Compatibility

Due to the rapid changes being made in the React Native ecosystem, this module will support
only latest version of React Native. Older versions will only be supported, if they're
compatible with this module.

| Module           | React Native      |
|------------------|-------------------|
| 0.1.0 - 0.2.0    | 0.33              |
| >=0.3.0          | >=0.47            |

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
import { Alert } from 'react-native';
import BackgroundGeolocation from 'react-native-mauron85-background-geolocation';

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
      stopOnTerminate: false,
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
    BackgroundGeolocation.events.forEach(event => BackgroundGeolocation.removeAllListeners(event));
  }
}

export default BgTracking;
```

## Instalation

### Installation

Add package to your project

```
npm install react-native-mauron85-background-geolocation --save
```

### Automatic setup

Link your native dependencies
```
react-native link react-native-mauron85-background-geolocation
```

Note: For iOS you still need to manually add background mode and usage descriptions into your project (@see [iOS setup](#ios-setup))

### Manual setup

#### Android setup

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

Register module (in `MainApplication.java`)

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


#### iOS setup

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. add `./node_modules/react-native-mauron85-background-geolocation/ios/RCTBackgroundGeolocation.xcodeproj`
3. In the XCode project navigator, select your project, select the `Build Phases` tab and in the `Link Binary With Libraries` section add **libRCTBackgroundGeolocation.a**
4. add `UIBackgroundModes` **location** to `Info.plist`
5. add `NSMotionUsageDescription` **App requires motion tracking** to `Info.plist` (required by ACTIVITY_PROVIDER)

For iOS before version 11:

6. add `NSLocationAlwaysUsageDescription` **App requires background tracking** to `Info.plist`

For iOS 11:

6. add `NSLocationWhenInUseUsageDescription` **App requires background tracking** to `Info.plist`
7. add `NSLocationAlwaysAndWhenInUseUsageDescription` **App requires background tracking** to `Info.plist`

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
| `startForeground`         | `Boolean`         | Android      | If false location service will not be started in foreground and no notification will be shown.                                                                                                                                                                                                                                                     | all         | true                       | 
| `interval`                | `Number`          | Android      | The minimum time interval between location updates in milliseconds. **@see** [Android docs](http://developer.android.com/reference/android/location/LocationManager.html#requestLocationUpdates(long,%20float,%20android.location.Criteria,%20android.app.PendingIntent)) for more information.                                                    | all         | 60000                      | 
| `fastestInterval`         | `Number`          | Android      | Fastest rate in milliseconds at which your app can handle location updates. **@see** [Android  docs](https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest.html#getFastestInterval()).                                                                                                                   | ACT         | 120000                     | 
| `activitiesInterval`      | `Number`          | Android      | Rate in milliseconds at which activity recognition occurs. Larger values will result in fewer activity detections while improving battery life.                                                                                                                                                                                                    | ACT         | 10000                      | 
| `stopOnStillActivity`     | `Boolean`         | Android      | @deprecated stop location updates, when the STILL activity is detected                                                                                                                                                                                                                                                                             | ACT         | true                       | 
| `notificationTitle`       | `String` optional | Android      | Custom notification title in the drawer.                                                                                                                                                                                                                                                                                                           | all         | "Background tracking"      | 
| `notificationText`        | `String` optional | Android      | Custom notification text in the drawer.                                                                                                                                                                                                                                                                                                            | all         | "ENABLED"                  | 
| `notificationIconColor`   | `String` optional | Android      | The accent color to use for notification. Eg. **#4CAF50**.                                                                                                                                                                                                                                                                                         | all         |                            | 
| `notificationIconLarge`   | `String` optional | Android      | The filename of a custom notification icon. **@see** Android quirks.                                                                                                                                                                                                                                                                               | all         |                            | 
| `notificationIconSmall`   | `String` optional | Android      | The filename of a custom notification icon. **@see** Android quirks.                                                                                                                                                                                                                                                                               | all         |                            | 
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


Partial reconfiguration is possible be providing only some configuration options:

```
BackgroundGeolocation.configure({
  debug: true
});
```

In this case new configuration options will be merged with stored configuration options and changes will be applied immediately.

### start()
Platform: iOS, Android

Start background geolocation.

### stop()
Platform: iOS, Android

Stop background geolocation.

### isLocationEnabled(success, fail)
Deprecated: This method is deprecated and will be removed in next major version.
Use `checkStatus` as replacement.

Platform: iOS, Android

One time check for status of location services. In case of error, fail callback will be executed.

| Success callback parameter | Type      | Description                                          |
|----------------------------|-----------|------------------------------------------------------|
| `enabled`                  | `Boolean` | true/false (true when location services are enabled) |

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

Note: In Android concept of authorization represent application permissions.

### showAppSettings()
Platform: Android >= 6, iOS >= 8.0

Show app settings to allow change of app location permissions.

### showLocationSettings()
Platform: iOS, Android

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

Method will return locations, which has not been yet posted to server.

| Success callback parameter | Type    | Description                    |
|----------------------------|---------|--------------------------------|
| `locations`                | `Array` | collection of stored locations |

### deleteLocation(locationId, success, fail)
Platform: iOS, Android

Delete location with locationId.

### deleteAllLocations(success, fail)
Note: You don't need to delete all locations. Plugin manages number of locations automatically and location count never exceeds number as defined by `option.maxLocations`.

Platform: iOS, Android

Delete all stored locations.

Note: Locations are not actually deleted from database to avoid gaps in locationId numbering.
Instead locations are marked as deleted. Locations marked as deleted will not appear in output of `BackgroundGeolocation.getValidLocations`.

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
BackgroundGeolocation.switchMode(BackgroundGeolocation.FOREGROUND_MODE);

// switch to BACKGROUND mode
BackgroundGeolocation.switchMode(BackgroundGeolocation.BACKGROUND_MODE);
```

### getLogEntries(limit, success, fail)
Platform: Android, iOS

Return all logged events. Useful for plugin debugging.
Parameter `limit` limits number of returned entries.
**@see [Debugging](#debugging)** for more information.

### removeAllListeners(event)

Unregister all event listeners for given event

## Events

| Name                | Callback param         | Platform     | Provider*   | Description                            |
|---------------------|------------------------|--------------|-------------|----------------------------------------|
| `location`          | `Location`             | all          | all         | on location update                     |
| `stationary`        | `Location`             | all          | DIS,ACT     | on device entered stationary mode      |
| `activity`          | `Activity`             | Android      | ACT         | on activity detection                  |
| `error`             | `{ code, message }`    | all          | all         | on plugin error                        |
| `authorization`     | `status`               | all          | all         | on user toggle location service        |
| `start`             |                        | all          | all         | geolocation has been started           |
| `stop`              |                        | all          | all         | geolocation has been stopped           |
| `foreground`        |                        | Android      | all         | app entered foreground state (visible) |
| `background`        |                        | Android      | all         | app entered background state           |

### Location event
| Location parameter | Type      | Description                                                            |
|--------------------|-----------|------------------------------------------------------------------------|
| `id`               | `Number`  | ID of location as stored in DB (or null)                               |
| `provider`         | `String`  | gps, network, passive or fused                                         |
| `locationProvider` | `Number`  | location provider                                                      |
| `time`             | `Number`  | UTC time of this fix, in milliseconds since January 1, 1970.           |
| `latitude`         | `Number`  | Latitude, in degrees.                                                  |
| `longitude`        | `Number`  | Longitude, in degrees.                                                 |
| `accuracy`         | `Number`  | Estimated accuracy of this location, in meters.                        |
| `speed`            | `Number`  | Speed if it is available, in meters/second over ground.                |
| `altitude`         | `Number`  | Altitude if available, in meters above the WGS 84 reference ellipsoid. |
| `bearing`          | `Number`  | Bearing, in degrees.                                                   |

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

All locations updates are recorded in local db at all times. When App is in foreground or background in addition to storing location in local db,
location callback function is triggered. Number of location stored in db is limited by `option.maxLocations` a never exceeds this number.
Instead old locations are replaced by new ones.

When `option.url` is defined, each location is also immediately posted to url defined by `option.url`.
If post is successful, the location is marked as deleted in local db.

When `option.syncUrl` is defined all failed to post locations will be coalesced and send in some time later in one single batch.
Batch sync takes place only when number of failed to post locations reaches `option.syncTreshold`.
Locations are send only in single batch, when number of locations reaches `option.syncTreshold`. (No individual location will be send)

Request body of posted locations is always array, even when only one location is sent.

Warning: `option.maxLocations` has to be larger than `option.syncThreshold`. It's recommended to be 2x larger. In other case location syncing might not work properly.

## Custom post template

With `option.postTemplate` is possible to specify which location properties should be posted to `option.url` or `option.syncUrl`. This can be useful to reduce
number of bytes sent over the "wire".

All wanted location properties has to be prefixed with `@`. For all available properties check [Location event](#location-event).

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

Note: only string keys and values are supported.
Note: Keep in mind that all locations (even single one) will be sent as array of object(s), when postTemplate is `jsonObject` and array of array(s) for `jsonArray`!

### Example of backend server

[Background-geolocation-server](https://github.com/mauron85/background-geolocation-server) is a backend server written in nodejs.
There are instructions how to run it and simulate locations on Android, iOS Simulator and Genymotion.

## Debugging

See [DEBUGGING.md](/DEBUGGING.md)

## Geofencing
Try using [react-native-geo-fencing](https://github.com/surialabs/react-native-geo-fencing). Let's keep this plugin lightweight as much as possible.

## Changelog

See [CHANGES.md](/CHANGES.md)
