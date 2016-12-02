'use strict';

var { DeviceEventEmitter, NativeModules } = require('react-native');
const RNBackgroundGeolocation = NativeModules.BackgroundGeolocation;

function emptyFn() {}

var BackgroundGeolocation = {
  events: [
    'location',
    'stationary',
    'start',
    'stop',
    'error',
    'mode_change',
    'permissions_denied',
    'foreground',
    'background'
  ],

  provider: {
    ANDROID_DISTANCE_FILTER_PROVIDER: 0,
    ANDROID_ACTIVITY_PROVIDER: 1
  },

  mode: {
    BACKGROUND: 0,
    FOREGROUND: 1
  },

  accuracy: {
    HIGH: 0,
    MEDIUM: 100,
    LOW: 1000,
    PASSIVE: 10000
  },

  configure: function(config, successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.configure(config, successFn, errorFn);
  },

  start: function() {
    RNBackgroundGeolocation.start();
  },

  stop: function() {
    RNBackgroundGeolocation.stop();
  },

  // @deprecated
  isLocationEnabled: function(successFn, errorFn) {
    console.log('[WARN]: this method is deprecated. Use checkStatus instead.');
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.isLocationEnabled(successFn, errorFn);
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

  getLogEntries: function(limit, successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.getLogEntries(limit, successFn, errorFn);
  },

  on: function(event, callbackFn) {
    if (typeof callbackFn !== 'function') {
      throw 'RNBackgroundGeolocation: callback function must be provided';
    }
    if (this.events.indexOf(event) < 0) {
      throw 'RNBackgroundGeolocation: Unknown event "' + event + '"';
    }

    return DeviceEventEmitter.addListener(event, callbackFn);
  },

  removeAllListeners: function(event) {
    if (this.events.indexOf(event) < 0) {
      console.log('[WARN] RNBackgroundGeolocation: removeAllListeners for unknown event "' + event + '"');
      return false;
    }

    return DeviceEventEmitter.removeAllListeners(event);
  }
};

module.exports = BackgroundGeolocation;
