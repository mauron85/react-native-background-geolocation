const path = require('path');
const config = require('./config');
const isInstalled = require('./isInstalled');

if (isInstalled.forAndroid()) {
  const revokePatch = require('react-native/local-cli/link/android/patches/revokePatch');
  const makeSettingsPatch = require('react-native/local-cli/link/android/patches/makeSettingsPatch');
  revokePatch(
    config.settingsGradlePath,
    makeSettingsPatch(
      config.commonModuleName,
      { sourceDir: path.join(config.moduleDir, 'android', config.commonModuleDir) },
      config
    )
  );
}


if (isInstalled.forIos()) {
  // we should remove background modes and usage descriptions here
  // It will destroy all project customizations, so we rather leave it as is.
}
