'use strict';

var { DeviceEventEmitter, NativeModules } = require('react-native');
const RNBackgroundGeolocation = NativeModules.BackgroundGeolocation;

function emptyFn() {}

var BackgroundGeolocation = {
  events: ['location', 'error'],

  configure: function(config, successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.configure(config, successFn, errorFn);
  },
  
  start: function(successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.start(successFn, errorFn);
  },
  
  stop: function(successFn, errorFn) {
    successFn = successFn || emptyFn;
    errorFn = errorFn || emptyFn;
    RNBackgroundGeolocation.stop(successFn, errorFn);
  },
  
  on: function(event, callbackFn) {
    if (this.events.indexOf(event) < 0) {
      throw "RNBackgroundGeolocation: Unknown event '" + event + '"';
    }
    return DeviceEventEmitter.addListener(event, callbackFn);
  }  
};

module.exports = BackgroundGeolocation;
