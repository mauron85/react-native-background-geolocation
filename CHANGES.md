## Changelog

### [0.5.0] - unreleased

This release brings abstractions, allowing code reuse
between ReactNative Cordova plugin variants.
As result enabling faster pace of development and
bug fixing on shared codebase.

### Added
- post/sync attributes customization via `postTemplate` config prop
- iOS ACTIVITY_PROVIDER (experimental)
- enable partial plugin reconfiguration
- on "activity" changed event
- Android Use gradle to choose authority (PR #136) by @jsdario
- iOS configuration persistence

Since alpha.8:
- Android automatic linking with react-native link
- iOS checkStatus returns status of location services (locationServicesEnabled)
- iOS RAW_LOCATION_PROVIDER continue to run on app terminate

Since alpha.10:
- Android checkStatus returns status of location services (locationServicesEnabled)

Since alpha.15:
- Android location parameters isFromMockProvider, mockLocationsEnabled, radius, provider
- Android Headless Task

Since alpha.16:
- iOS add background modes and permissions on postlink
- add crossplatform prepublish script execution (PR #165) by @dobrynia

Since alpha.17:
- Android allow to override version of libraries with ext declaration

Since alpha.19:
- Android Oreo experimental support

Since alpha.20:
- option to get logs by offset and filter by log level
- log uncaught exceptions

Since alpha.22:
- method forceSync

Since alpha.26:
- Android add httpHeaders validation

Sice alpha.28:
- implement getCurrentLocation
- iOS implement getStationaryLocation

Sice alpha.31:
- Android Gradle3 support (experimental)

Sice alpha.37:
- Transforming/filtering locations in native code (by [@danielgindi](https://github.com/danielgindi/))
More info: https://github.com/mauron85/background-geolocation-android/pull/8


### Changed

Since alpha.6:
- iOS saveBatteryOnBackground defaults to false

Since alpha.8:
- shared code base with Cordova

Since alpha.11:
- Android derive sync authority and provider from applicationId
- Android remove android.permission.GET_ACCOUNTS

Since alpha.19:
- Android postlink register project in settings.gradle instead of file copying
(BREAKING CHANGE - read android-setup section)

Since alpha.20:
- iOS use Android log format (BREAKING CHANGE)

Since alpha.22:
- Android remove sync delay when conditions are met
- Android consider HTTP 201 response code as succesful post
- Android obey system sync setting

Since alpha.26:
- Android show service notification only when in background
- Android remove config option startForeground (related to above)
- Android remove wake locks from both Android providers (by @grassick)
- Android remove restriction on postTemplate string only values

Since alpha.28:
- Android bring back startForeground config option (BREAKING CHANGE!)

startForeground has slightly different meaning.

If false (default) then service will create notification and promotes
itself to foreground service, when client unbinds from service.
This typically happens when application is moving to background.
If app is moving back to foreground (becoming visible to user)
service destroys notification and also stop being foreground service.

If true service will create notification and will stay in foreground at all times.

Since alpha.30:
- Android internal changes (permission handling)
- Android gradle build changes

### Fixed

Since alpha.4:
- iOS open location settings on iOS 10 and later (PR #158) by @asafron

Since alpha.8:
- checkStatus authorization
- Android fix for Build Failed: cannot find symbol

Since alpha.9:
- Android fix #118 - NullPointerException LocationService.onTaskRemoved
- Android permission - check and request permissions in runtime

Since alpha.13:
- Android fix allowBackup attribute conflict

Since alpha.14:
- Android fix #166 - Error: more than one library with package name
'com.google.android.gms.license'

Since alpha.15:
- Android only pass valid location parameters
- iOS reset connectivity status on stop
- iOS fix App Store Rejection - Prefs Non-Public URL Scheme

Since alpha.17:
- Android fix service accidently started with default or stored config

Since alpha.21:
- Android uninstall common module on postunlink
- Android prevent multiple registration of common project
- Android fix some nullpointer exceptions 92649c70e0ce0072464f47f1d096bef40047b8a6
- iOS update plist on changes only

Since alpha.22:
- Android add guards to prevent some race conditions
- Android config null handling

Sice alpha.25:
- Android issue #185 - handle invalid configuration

Sice alpha.27:
- iOS fix forceSync params
- fix #183 - Error when adding 'activity' event listener

Sice alpha.28:
- iOS display debug notifications in foreground on iOS >= 10
- iOS fix error message format
- iOS activity provider stationary event

Since alpha.35:
- Android getCurrentLocation runs on background thread (PR #219 by [@djereg](https://github.com/djereg/))
- iOS Fix crash on delete all location ([7392e39](https://github.com/mauron85/background-geolocation-ios/commit/7392e391c3de3ff0d6f5ef2ef19c34aba612bf9b) by [@acerbetti](https://github.com/acerbetti/))

Since alpha.36:
- Android Defer start and configure until service is ready
(PR: [#7](https://github.com/mauron85/background-geolocation-android/pull/7)
Commit: [00e1314](https://github.com/mauron85/background-geolocation-android/commit/00e131478ad4e37576eb85581bb663b65302a4e0) by [@danielgindi](https://github.com/danielgindi/),
fixes #201, #181, #172)

### [0.4.1] - 2017-12-19
#### Changed
- react native peer dependency >0.49.0

### [0.4.0] - 2017-12-13
release

### [0.4.0-rc.3] - 2017-11-23
### Added
- iOS send http headers on background sync

### [0.4.0-rc.2] - 2017-11-13

### Fixed
- Android ConfigMapper mapToConfig missing config props (fixes #122)

### Added
- Android return location id for getLocations

### [0.4.0-rc.1] - 2017-11-10

### Fixed
- iOS fix crash when calling getConfig before configure

#### Added
- checkStatus if service is running
- events [start, stop, authorization, background, foreground]
- implement all methods for both platforms
- new RAW_LOCATION_PROVIDER

#### Changed

- start and stop methods doesn't accept callback (use event listeners instead)
- for background syncing syncUrl option is required
- on Android DISTANCE_FILTER_PROVIDER now accept arbitrary values (before only 10, 100, 1000)
- all plugin constants are in directly BackgroundGeolocation namespace. (check index.js)
- plugin can be started without executing configure (stored settings or defaults will be used)
- location property locationId renamed to just id
- iOS pauseLocationUpdates now default to false (becuase iOS docs now states that you need to restart manually if you set it to true)
- iOS finish method replaced with startTask and endTask

### [0.3.3] - 2017-11-01
#### Fixed
- Android location sync should also be completed on 201 status code (PR #71)

### [0.3.2] - 2017-11-01
#### Fixed
- iOS implementation for isLocationEnabled (PR #92)

### [0.3.1] - 2017-10-04
#### Fixed
- (tpisto) iOS compile error in React Native 0.48.x (fixes #108)

### [0.3.0-alpha.1] - 2017-08-15
#### Fixed
- RN 0.47 compatibility (fixes #95)

### [0.2.0-alpha.7] - 2017-03-21
#### Fixed
- iOS fixing build issue #44

### [0.2.0-alpha.6] - 2017-02-18
#### Fixed
- iOS RN 0.40 compatibility

### [0.2.0-alpha.5] - 2016-09-15
#### Fixed
- Android fix issue #10

### [0.2.0-alpha.4] - 2016-09-10
#### Fixed
- Android fix crash on destroy when plugin was not configured

### [0.2.0-alpha.3] - 2016-09-07
#### Fixed
- fix Android issue #10 - crash on refresh

#### Added
- Android onStationary
- Android getLogEntries

#### Removed
- Android location filtering

#### Changed
- Android project directory structure
(please read updated install instructions)
- Android db logging instead of file

### [0.2.0-alpha.2] - 2016-08-31
#### Fixed
- fix config not persisted
- tmp fix Android time long to int conversion

#### Added
- Android isLocationEnabled
- Android showAppSettings
- Android showLocationSettings
- Android getLocations
- Android getConfig

### [0.2.0-alpha.1] - 2016-08-17
#### Changed
- upgrading plugin to match cordova 2.2.0-alpha.6

### [0.1.1] - 2016-06-08
#### Fixed
- fix iOS crash on stop

### [0.1.0] - 2016-06-07
#### Added
- initial iOS implementation

### [0.0.1] - 2016-06-04
- initial Android implementation
