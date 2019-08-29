'use strict';

var { DeviceEventEmitter, NativeModules, AppRegistry } = require('react-native');
var RNBackgroundGeolocation = NativeModules.BackgroundGeolocation;
var TAG = 'RNBackgroundGeolocation';
var TASK_KEY = 'com.marianhello.bgloc.react.headless.Task';

function emptyFn() {}
function defaultErrorHandler(error) {
  var cause = error.cause || {};
  var causeMessage = cause.message;
  throw TAG + ': ' + error.message + (causeMessage ? ': ' + cause.message : '');
}

var BackgroundGeolocation = {
  events: [
    'location',
    'stationary',
    'activity',
    'start',
    'stop',
    'error',
    'authorization',
    'foreground',
    'background',
    'abort_requested',
    'http_authorization'
  ],

  DISTANCE_FILTER_PROVIDER: 0,
  ACTIVITY_PROVIDER: 1,
  RAW_PROVIDER: 2,

  BACKGROUND_MODE: 0,
  FOREGROUND_MODE: 1,

  NOT_AUTHORIZED: 0,
  AUTHORIZED: 1,
  AUTHORIZED_FOREGROUND: 2,

  HIGH_ACCURACY: 0,
  MEDIUM_ACCURACY: 100,
  LOW_ACCURACY: 1000,
  PASSIVE_ACCURACY: 10000,

  LOG_ERROR: 'ERROR',
  LOG_WARN: 'WARN',
  LOG_INFO: 'INFO',
  LOG_DEBUG: 'DEBUG',
  LOG_TRACE: 'TRACE',

  PERMISSION_DENIED: 1,
  LOCATION_UNAVAILABLE: 2,
  TIMEOUT: 3,

  configure: function(config, successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || defaultErrorHandler;
    RNBackgroundGeolocation.configure(config, successFn, errorFn);
  },

  start: function() {
    RNBackgroundGeolocation.start();
  },

  stop: function() {
    RNBackgroundGeolocation.stop();
  },

  checkStatus: function(successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.checkStatus(successFn, errorFn);
  },

  showAppSettings: function() {
    RNBackgroundGeolocation.showAppSettings();
  },

  showLocationSettings: function() {
    RNBackgroundGeolocation.showLocationSettings();
  },

  /**
   * Returns current stationaryLocation if available.  null if not
   */
  getStationaryLocation: function (successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.getStationaryLocation(successFn, errorFn);
  },

  getCurrentLocation: function(successFn, errorFn, options) {
    options = options || {};
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.getCurrentLocation(options, successFn, errorFn);
  },

  getLocations: function(successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.getLocations(successFn, errorFn);
  },

  getValidLocations: function(successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.getValidLocations(successFn, errorFn);
  },

  deleteLocation: function(locationId, successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.deleteLocation(locationId, successFn, errorFn);
  },

  deleteAllLocations: function(successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.deleteAllLocations(successFn, errorFn);
  },

  switchMode: function(modeId, successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.switchMode(modeId, successFn, errorFn);
  },

  getConfig: function(successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.getConfig(successFn, errorFn);
  },

  getLogEntries: function(limit, /* offset = 0, minLevel = "DEBUG", successFn = emptyFn, errorFn = emptyFn */) {
    var acnt = arguments.length;
    var offset, minLevel, successFn, errorFn;

    if (acnt > 1 && typeof arguments[1] == 'function') {
      // backward compatibility
      console.log('[WARN]: Calling deprecated variant of getLogEntries method.');
      offset = 0;
      minLevel = BackgroundGeolocation.LOG_DEBUG;
      successFn = arguments[1] || emptyFn;
      errorFn = arguments[2] || emptyFn;
    } else {
      offset = acnt > 1 && arguments[1] !== undefined ? arguments[1] : 0;
      minLevel = acnt > 2 && arguments[2] !== undefined ? arguments[2] : BackgroundGeolocation.LOG_DEBUG;
      successFn = acnt > 3 && arguments[3] !== undefined ? arguments[3] : emptyFn;
      errorFn = acnt > 4 && arguments[4] !== undefined ? arguments[4] : emptyFn;
    }

    RNBackgroundGeolocation.getLogEntries(limit, offset, minLevel, successFn, errorFn);
  },

  startTask: function(callbackFn) {
    if (typeof callbackFn !== 'function') {
      throw 'RNBackgroundGeolocation: startTask requires callback function';
    }

    if (typeof RNBackgroundGeolocation.startTask === 'function') {
      RNBackgroundGeolocation.startTask(callbackFn);
    } else {
      // android does not need background tasks so we invoke callbackFn directly
      callbackFn(-1);
    }
  },

  endTask: function(taskKey) {
    if (typeof RNBackgroundGeolocation.endTask === 'function') {
      RNBackgroundGeolocation.endTask(taskKey);
    } else {
      // noop
    }
  },

  headlessTask: function(task, successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    AppRegistry.registerHeadlessTask(TASK_KEY, () => task);
    RNBackgroundGeolocation.registerHeadlessTask(successFn, errorFn);
  },

  forceSync: function(successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.forceSync(successFn, errorFn);
  },

  on: function(event, callbackFn) {
    if (typeof callbackFn !== 'function') {
      throw TAG + ': callback function must be provided';
    }
    if (this.events.indexOf(event) < 0) {
      throw TAG + ': Unknown event "' + event + '"';
    }

    return DeviceEventEmitter.addListener(event, callbackFn);
  },

  removeAllListeners: function(event) {
    if (!event) {
      this.events.forEach(function(event) {
        DeviceEventEmitter.removeAllListeners(event);
      });
      return void 0;
    }
    if (this.events.indexOf(event) < 0) {
      console.log('[WARN] ' + TAG + ': removeAllListeners for unknown event "' + event + '"');
      return void 0;
    }

    DeviceEventEmitter.removeAllListeners(event);
    return void 0;
  }
};

module.exports = BackgroundGeolocation;