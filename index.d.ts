// Type definitions for react-native-mauron85-background-geolocation
// Project: https://github.com/mauron85/react-native-background-geolocation
// Definitions by: Mauron85 (@mauron85), Norbert Györög (@djereg)
// Definitions: https://github.com/mauron85/react-native-background-geolocation/blob/master/index.d.ts

type Event = 'location' | 'stationary' | 'activity' | 'start' | 'stop' | 'error' | 'authorization' | 'foreground' | 'background' | 'abort_requested' | 'http_authorization';
type HeadlessTaskEventName = 'location' | 'stationary' | 'activity';
type iOSActivityType = 'AutomotiveNavigation' | 'OtherNavigation' | 'Fitness' | 'Other';
type NativeProvider = 'gps' | 'network' | 'passive' | 'fused';
type ActivityType = 'IN_VEHICLE' | 'ON_BICYCLE' | 'ON_FOOT' | 'RUNNING' | 'STILL' | 'TILTING' | 'UNKNOWN' | 'WALKING';
type LogLevel = 'TRACE' | 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';
type LocationProvider = 0 | 1 | 2;
type AuthorizationStatus = 0 | 1 | 2;
type AccuracyLevel = 0 | 100 | 1000 | 10000 | number;
type LocationErrorCode = 1 | 2 | 3;
type ServiceMode = 0 | 1;

export interface ConfigureOptions {
  /**
   * Set location provider
   *
   * Platform: all
   * Available providers:
   *  DISTANCE_FILTER_PROVIDER,
   *  ACTIVITY_PROVIDER
   *  RAW_PROVIDER
   *
   * @default DISTANCE_FILTER_PROVIDER
   * @example
   * { locationProvider: BackgroundGeolocation.RAW_PROVIDER }
   */
  locationProvider?: LocationProvider;

  /**
   * Desired accuracy in meters.
   *
   * Platform: all
   * Provider: all
   * Possible values:
   *  HIGH_ACCURACY,
   *  MEDIUM_ACCURACY,
   *  LOW_ACCURACY,
   *  PASSIVE_ACCURACY
   * Note: Accuracy has direct effect on power drain. Lower accuracy = lower power drain.
   *
   * @default MEDIUM_ACCURACY
   * @example
   * { desiredAccuracy: BackgroundGeolocation.LOW_ACCURACY }
   */
  desiredAccuracy?: AccuracyLevel;

  /**
   * Stationary radius in meters.
   *
   * When stopped, the minimum distance the device must move beyond the stationary location for aggressive background-tracking to engage.
   * Platform: all
   * Provider: DISTANCE_FILTER
   *
   * @default 50
   */
  stationaryRadius?: number;

  /**
   * When enabled, the plugin will emit sounds for life-cycle events of background-geolocation! See debugging sounds table.
   *
   * Platform: all
   * Provider: all
   *
   * @default false
   */
  debug?: boolean;

  /**
   * The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
   *
   * Platform: all
   * Provider: DISTANCE_FILTER, RAW
   *
   * @default 500
   * @see {@link https://apple.co/2oHo2CV|Apple docs}
   */
  distanceFilter?: number;

  /**
   * Enable this in order to force a stop() when the application terminated.
   * E.g. on iOS, double-tap home button, swipe away the app.
   *
   * Platform: all
   * Provider: all
   *
   * @default true
   */
  stopOnTerminate?: boolean;

  /**
   * Start background service on device boot.
   *
   * Platform: Android
   * Provider: all
   *
   * @default false
   */
  startOnBoot?: boolean;

  /**
   * The minimum time interval between location updates in milliseconds.
   *
   * Platform: Android
   * Provider: all
   *
   * @default 60000
   * @see {@link https://bit.ly/1x00RUu|Android docs}
   */
  interval?: number;

  /**
   * Fastest rate in milliseconds at which your app can handle location updates.
   *
   * Platform: Android
   * Provider: ACTIVITY
   *
   * @default 120000
   * @see {@link https://bit.ly/1x00RUu|Android docs}
   */
  fastestInterval?: number;

  /**
   * Rate in milliseconds at which activity recognition occurs.
   * Larger values will result in fewer activity detections while improving battery life.
   *
   * Platform: Android
   * Provider: ACTIVITY
   *
   * @default 10000
   */
  activitiesInterval?: number;

  /**
   * @deprecated Stop location updates, when the STILL activity is detected.
   */
  stopOnStillActivity?: boolean;

  /**
   * Enable/disable local notifications when tracking and syncing locations.
   *
   * Platform: Android
   * Provider: all
   *
   * @default true
   */
  notificationsEnabled?: boolean;

  /**
   * Allow location sync service to run in foreground state.
   * Foreground state also requires a notification to be presented to the user.
   *
   * Platform: Android
   * Provider: all
   *
   * @default false
   */
  startForeground?: boolean;

  /**
   * Custom notification title in the drawer.
   *
   * Platform: Android
   * Provider: all

   * @default "Background tracking"
   */
  notificationTitle?: string;

  /**
   * Custom notification text in the drawer.
   *
   * Platform: Android
   * Provider: all
   *
   * @default "ENABLED"
   */
  notificationText?: string;

  /**
   * The accent color (hex triplet) to use for notification.
   * Eg. <code>#4CAF50</code>.
   *
   * Platform: Android
   * Provider: all
   */
  notificationIconColor?: string;

  /**
   * The filename of a custom notification icon.
   *
   * Platform: Android
   * Provider: all
   */
  notificationIconLarge?: string;

  /**
   * The filename of a custom notification icon.
   *
   * Platform: Android
   * Provider: all
   */
  notificationIconSmall?: string;

  /**
   * Activity type.
   * Presumably, this affects iOS GPS algorithm.
   *
   * Possible values:
   * "AutomotiveNavigation", "OtherNavigation", "Fitness", "Other"
   *
   * Platform: iOS
   * Provider: all
   *
   * @default "OtherNavigation"
   * @see {@link https://apple.co/2oHofpH|Apple docs}
   */
  activityType?: iOSActivityType;

  /**
   * Pauses location updates when app is paused.
   *
   * Platform: iOS
   * Provider: all
   *
   * @default false
   * @see {@link https://apple.co/2CbjEW2|Apple docs}
   */
  pauseLocationUpdates?: boolean;

  /**
   * Switch to less accurate significant changes and region monitory when in background.
   *
   * Platform: iOS
   * Provider: all
   *
   * @default false
   */
  saveBatteryOnBackground?: boolean;

  /**
   * Server url where to send HTTP POST with recorded locations
   *
   * Platform: all
   * Provider: all
   */
  url?: string;

  /**
   * Server url where to send fail to post locations
   *
   * Platform: all
   * Provider: all
   */
  syncUrl?: string;

  /**
   * Specifies how many previously failed locations will be sent to server at once.
   *
   * Platform: all
   * Provider: all
   *
   * @default 100
   */
  syncThreshold?: string;

  /**
   * Optional HTTP headers sent along in HTTP request.
   *
   * Platform: all
   * Provider: all
   */
  httpHeaders?: any;

  /**
   * Limit maximum number of locations stored into db.
   *
   * Platform: all
   * Provider: all
   *
   * @default 10000
   */
  maxLocations?: number;

  /**
   * Customization post template.
   *
   * Platform: all
   * Provider: all
   */
  postTemplate?: any;
}

export interface LocationOptions {
  /**
   * Maximum time in milliseconds device will wait for location.
   */
  timeout?: number;

  /**
   * Maximum age in milliseconds of a possible cached location that is acceptable to return.
   */
  maximumAge?: number;

  /**
   * If true and if the device is able to provide a more accurate position, it will do so.
   */
  enableHighAccuracy?: boolean;
}

export interface Location {
  /** ID of location as stored in DB (or null) */
  id: number;

  /**
   * Native provider reponsible for location.
   *
   * Possible values:
   * "gps", "network", "passive" or "fused"
   */
  provider: NativeProvider;

  /** Configured location provider. */
  locationProvider: number;

  /** UTC time of this fix, in milliseconds since January 1, 1970. */
  time: number;

  /** Latitude, in degrees. */
  latitude: number;

  /** Longitude, in degrees. */
  longitude: number;

  /** Estimated accuracy of this location, in meters. */
  accuracy: number;

  /**
   * Speed if it is available, in meters/second over ground.
   *
   * Note: Not all providers are capable of providing speed.
   * Typically network providers are not able to do so.
   */
  speed: number;

  /** Altitude if available, in meters above the WGS 84 reference ellipsoid. */
  altitude: number;

  /** Bearing, in degrees. */
  bearing: number;

  /**
   * True if location was recorded by mock provider. (ANDROID ONLY)
   *
   * Note: this property is not enabled by default!
   * You can enable it "postTemplate" configure option.
   */
  isFromMockProvider?: boolean;

  /**
   * True if device has mock locations enabled. (ANDROID ONLY)
   *
   * Note: this property is not enabled by default!
   * You can enable it "postTemplate" configure option.
   */
  mockLocationsEnabled?: boolean;
}

export interface StationaryLocation extends Location {
  radius: number
}

export interface LocationError {
  /**
   * Reason of an error occurring when using the geolocating device.
   *
   * Possible error codes:
   *  1. PERMISSION_DENIED
   *  2. LOCATION_UNAVAILABLE
   *  3. TIMEOUT
   */
  code: LocationErrorCode;

  /** Message describing the details of the error */
  message: string;
}

export interface BackgroundGeolocationError {
  code: number;
  message: string;
}

export interface Activity {
  /** Percentage indicating the likelihood user is performing this activity. */
  confidence: number;

  /**
   * Type of the activity.
   *
   * Possible values:
   * IN_VEHICLE, ON_BICYCLE, ON_FOOT, RUNNING, STILL, TILTING, UNKNOWN, WALKING
   */
  type: ActivityType;
}

export interface ServiceStatus {
  /** TRUE if service is running. */
  isRunning: boolean;

  /** TRUE if location services are enabled */
  locationServicesEnabled: boolean;

  /**
   * Authorization status.
   *
   * Posible values:
   *  NOT_AUTHORIZED, AUTHORIZED, AUTHORIZED_FOREGROUND
   *
   * @example
   * if (authorization == BackgroundGeolocation.NOT_AUTHORIZED) {...}
   */
  authorization: AuthorizationStatus;
}

export interface LogEntry {
  /** ID of log entry as stored in db. */
  id: number;

  /** Timestamp in milliseconds since beginning of UNIX epoch. */
  timestamp: number;

  /** Log level */
  level: LogLevel;

  /** Log message */
  message: string;

  /** Recorded stacktrace. (Android only, on iOS part of message) */
  stackTrace: string;
}

export interface EventSubscription {
  remove(): void;
}

export interface HeadlessTaskEvent {
  /** Name of the event [ "location", "stationary", "activity" ] */
  name: HeadlessTaskEventName;

  /** Event parameters. */
  params: any;
}

export interface BackgroundGeolocationPlugin {

  DISTANCE_FILTER_PROVIDER: LocationProvider;
  ACTIVITY_PROVIDER: LocationProvider;
  RAW_PROVIDER: LocationProvider;

  BACKGROUND_MODE: ServiceMode;
  FOREGROUND_MODE: ServiceMode;

  NOT_AUTHORIZED: AuthorizationStatus;
  AUTHORIZED: AuthorizationStatus;
  AUTHORIZED_FOREGROUND: AuthorizationStatus;

  HIGH_ACCURACY: AccuracyLevel;
  MEDIUM_ACCURACY: AccuracyLevel;
  LOW_ACCURACY: AccuracyLevel;
  PASSIVE_ACCURACY: AccuracyLevel;

  LOG_ERROR: LogLevel;
  LOG_WARN: LogLevel;
  LOG_INFO: LogLevel;
  LOG_DEBUG: LogLevel;
  LOG_TRACE: LogLevel;

  PERMISSION_DENIED: LocationErrorCode;
  LOCATION_UNAVAILABLE: LocationErrorCode;
  TIMEOUT: LocationErrorCode;

  events: Event[];

  /**
   * Configure plugin.
   * Platform: iOS, Android
   *
   * @param options
   * @param success
   * @param fail
   */
  configure(
    options: ConfigureOptions,
    success?: () => void,
    fail?: () => void
  ): void;

  /**
   * Start background geolocation.
   * Platform: iOS, Android
   */
  start(): void;

  /**
   * Stop background geolocation.
   * Platform: iOS, Android
   */
  stop(): void;

  /**
   * One time location check to get current location of the device.
   *
   * Platform: all
   *
   * @param success
   * @param fail
   * @param options
   */
  getCurrentLocation(
    success: (location: Location) => void,
    fail?: (error: LocationError) => void | null,
    options?: LocationOptions
  ): void;

  /**
   * Returns current stationaryLocation if available. Null if not
   *
   * Platform: all
   *
   * @param success
   * @param fail
   */
  getStationaryLocation(
    success: (location: StationaryLocation | null) => void,
    fail?: (error: BackgroundGeolocationError) => void,
  ): void;

  /**
   * Check status of the service
   *
   * @param success
   * @param fail
   */
  checkStatus(
    success: (status: ServiceStatus) => void,
    fail?: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * Show app settings to allow change of app location permissions.
   *
   * Platform: Android >= 6, iOS >= 8.0
   */
  showAppSettings(): void;

  /**
   * Show system settings to allow configuration of current location sources.
   *
   * Platform: Android
   */
  showLocationSettings(): void;

  /**
   * Return all stored locations.
   * Useful for initial rendering of user location on a map just after application launch.
   *
   * Platform: iOS, Android
   *
   * @param success
   * @param fail
   * @see {@link https://github.com/mauron85/react-native-background-geolocation#getlocationssuccess-fail|Docs}
   */
  getLocations(
    success: (locations: Location[]) => void,
    fail?: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * Method will return locations which have not yet been posted to server.
   * Platform: iOS, Android
   * @param success
   * @param fail
   * @see {@link https://github.com/mauron85/react-native-background-geolocation#getvalidlocationssuccess-fail|Docs}
   */
  getValidLocations(
    success: (location: Location[]) => void,
    fail?: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * Delete location by locationId.
   *
   * Platform: iOS, Android
   *
   * @param locationId
   * @param success
   * @param fail
   */
  deleteLocation(
    locationId: number,
    success?: () => void,
    fail?: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * Delete all stored locations.
   *
   * Platform: iOS, Android
   *
   * Note: You don't need to delete all locations.
   * The plugin manages the number of stored locations automatically and the total count never exceeds the number as defined by <code>option.maxLocations</code>.
   *
   * @param success
   * @param fail
   */
  deleteAllLocations(
    success?: () => void,
    fail?: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * Switch plugin operation mode,
   *
   * Platform: iOS
   *
   * Normally the plugin will handle switching between <b>BACKGROUND</b> and <b>FOREGROUND</b> mode itself.
   * Calling <code>switchMode</code> you can override plugin behavior and force it to switch into other mode.
   *
   * @example
   * // switch to FOREGROUND mode
   * BackgroundGeolocation.switchMode(BackgroundGeolocation.FOREGROUND_MODE);
   *
   * // switch to BACKGROUND mode
   * BackgroundGeolocation.switchMode(BackgroundGeolocation.BACKGROUND_MODE);
   */
  switchMode(
    modeId: ServiceMode,
    success?: () => void,
    fail?: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * Force sync of pending locations.
   * Option <code>syncThreshold</code> will be ignored and all pending locations will be immediately posted to <code>syncUrl</code> in single batch.
   *
   * Platform: Android, iOS
   *
   * @param success
   * @param fail
   */
  forceSync(
    success?: () => void,
    fail?: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * Get stored configuration options.
   *
   * @param success
   * @param fail
   */
  getConfig(
    success: (options: ConfigureOptions) => void,
    fail?: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * Return all logged events. Useful for plugin debugging.
   *
   * Platform: Android, iOS
   *
   * @param limit Limits number of returned entries.
   * @param fromId Return entries after <code>fromId</code>. Useful if you plan to implement infinite log scrolling
   * @param minLevel Available levels: ["TRACE", "DEBUG", "INFO", "WARN", "ERROR"]
   * @param success
   * @param fail
   */
  getLogEntries(
    limit: number,
    fromId: number,
    minLevel: LogLevel,
    success: (entries: LogEntry[]) => void,
    fail?: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * Unregister all event listeners for given event.
   * 
   * If parameter <code>event</code> is not provided then all event listeners will be removed.
   *
   * @param event
   */
  removeAllListeners(event?: Event): void;


  /**
   * Start background task (iOS only)
   *
   * To perform any long running operation on iOS
   * you need to create background task
   * IMPORTANT: task has to be ended by endTask
   *
   * @param success
   * @param fail
   */
  startTask(
    success: (taskKey: number) => void,
    fail?: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * End background task indentified by taskKey (iOS only)
   *
   * @param taskKey
   * @param success
   * @param fail
   */
  endTask(
    taskKey: number,
    success?: () => void,
    fail?: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * A special task that gets executed when the app is terminated, but
   * the plugin was configured to continue running in the background
   * (option <code>stopOnTerminate: false</code>).
   *
   * In this scenario the Activity was killed by the system and all registered
   * event listeners will not be triggered until the app is relaunched.
   *
   * @example
   *  BackgroundGeolocation.headlessTask(function(event) {
   *
   *      if (event.name === 'location' || event.name === 'stationary') {
   *          var xhr = new XMLHttpRequest();
   *          xhr.open('POST', 'http://192.168.81.14:3000/headless');
   *          xhr.setRequestHeader('Content-Type', 'application/json');
   *          xhr.send(JSON.stringify(event.params));
   *      }
   *
   *      return 'Processing event: ' + event.name; // will be logged
   *  });
   */
  headlessTask(
    task: (event: HeadlessTaskEvent) => void
  ): void;

  /**
   * Register location event listener.
   *
   * @param eventName
   * @param callback
   */
  on(
    eventName: 'location',
    callback: (location: Location) => void
  ): void;

  /**
   * Register stationary location event listener.
   *
   * @param eventName
   * @param callback
   */
  on(
    eventName: 'stationary',
    callback: (location: StationaryLocation) => void
  ): void;

  /**
   * Register activity monitoring listener.
   *
   * @param eventName
   * @param callback
   */
  on(
    eventName: 'activity',
    callback: (activity: Activity) => void
  ): void;

  /**
   * Register start event listener.
   *
   * Event is triggered when background service has been started succesfully.
   *
   * @param eventName
   * @param callback
   */
  on(
    eventName: 'start',
    callback: () => void
  ): void;

  /**
   * Register stop event listener.
   *
   * Triggered when background service has been stopped succesfully.
   *
   * @param eventName
   * @param callback
   */
  on(
    eventName: 'stop',
    callback: () => void
  ): void;

  /**
   * Register error listener.
   *
   * @param eventName
   * @param callback
   */
  on(
    eventName: 'error',
    callback: (error: BackgroundGeolocationError) => void
  ): void;

  /**
   * Register authorization listener.
   *
   * Triggered when user changes authorization/permissions for
   * the app or toggles location services.
   *
   * @param eventName
   * @param callback
   */
  on(
    eventName: 'authorization',
    callback: (status: AuthorizationStatus) => void
  ): void;

  /**
   * Register foreground event listener.
   *
   * Triggered when app entered foreground state and (visible to the user).
   *
   * @param eventName
   * @param callback
   */
  on(
    eventName: 'foreground',
    callback: () => void
  ): void;

  /**
   * Register background event listener.
   *
   * Triggered when app entered background state and (not visible to the user).
   *
   * @param eventName
   * @param callback
   */
  on(
    eventName: 'background',
    callback: () => void
  ): void;

  /**
   * Register abort_requested event listener.
   *
   * Triggered when server responded with "<code>285 Updates Not Required</code>" to post/sync request.
   *
   * @param eventName
   * @param callback
   */
  on(
    eventName: 'abort_requested',
    callback: () => void
  ): void;

  /**
   * Register http_authorization event listener.
   *
   * Triggered when server responded with "<code>401 Unauthorized</code>" to post/sync request.
   *
   * @param eventName
   * @param callback
   */
  on(
    eventName: 'http_authorization',
    callback: () => void
  ): void;

}

declare const BackgroundGeolocation: BackgroundGeolocationPlugin;

export default BackgroundGeolocation;
