## Changelog

### [0.4.0-alpha.3] - unreleased
### Fixed
- iOS fix crash when calling getConfig before configure

#### Added
- iOS add checkStatus
- iOS use events instead callbacks for start and stop methods

### [0.4.0-alpha.1] - unreleased
#### Added
- Android android.hardware.location permission
- Android methods: getValidLocations, deleteLocation, deleteAllLocations
- Android method checkStatus check if service is running and more
- Android 6.0 permissions
- Android events (mode_change, permissions_denied ...)

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
