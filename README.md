# react-native-mauron85-background-geolocation

## Description

Special React Native fork of [cordova-plugin-mauron85-background-geolocation](https://github.com/mauron85/cordova-plugin-background-geolocation).

## Quick example

```javascript
import React, { Component } from 'react';
var BackgroundGeolocation = require('react-native-mauron85-background-geolocation');

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
      locationProvider: 1, // 0 => ANDROID_DISTANCE_FILTER_PROVIDER | 1 => ANDROID_ACTIVITY_PROVIDER
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
project(':react-native-mauron85-background-geolocation').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-mauron85-background-geolocation/android')
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

Register module (in `MainActivity.java`)

```java
import com.marianhello.react.BackgroundGeolocationPackage;  // <--- Import Package

public class MainActivity extends Activity implements DefaultHardwareBackBtnHandler {
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

### iOS setup

Coming soon...
