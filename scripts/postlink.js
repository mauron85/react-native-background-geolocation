const path = require('path');
const fs = require('fs');
const config = require('./config');
const isInstalled = require('./isInstalled');

const appDir = config.appDir;
const manifest = require(path.join(appDir, 'package.json'));

if (!isInstalled.forAndroid()) {
  // Android register common project
  // TODO: it would be nicer if react-native link has support for multi projects itself
  // Please vote:
  // https://react-native.canny.io/feature-requests/p/enable-subprojects-in-native-android-components-to-enable-code-reuse-with-cordov
  const applyPatch = require('@react-native-community/cli-platform-android/build/link/patches/applyPatch').default;
  const makeSettingsPatch = require('@react-native-community/cli-platform-android/build/link/patches/makeSettingsPatch').default;
  applyPatch(
    config.settingsGradlePath,
    makeSettingsPatch(
      config.commonModuleName,
      { sourceDir: path.join(config.moduleDir, 'android', config.commonModuleDir) },
      config
    )
  );
}

if (!isInstalled.forIos()) {
  const plist = require('plist');
  const infoPlistPath = path.join(appDir, 'ios', manifest.name, 'Info.plist');
  const infoPlistFile = fs.readFileSync(infoPlistPath, 'utf8');
  const infoPlist = plist.parse(infoPlistFile);
  const pListChanges = {};

  const existingBgModes = infoPlist.UIBackgroundModes || [];
  const missingBgModes = config.REQUIRED_BACKGROUND_MODES.filter(function(mode) {
    return existingBgModes.indexOf(mode) === -1;
  });

  if (missingBgModes.length > 0)  {
    pListChanges.UIBackgroundModes = missingBgModes;
  }

  if (!infoPlist.NSLocationAlwaysUsageDescription) {
    pListChanges.NSLocationAlwaysUsageDescription = 'App requires background tracking';
  }
  if (!infoPlist.NSLocationAlwaysAndWhenInUseUsageDescription) {
    pListChanges.NSLocationAlwaysAndWhenInUseUsageDescription = 'App requires background tracking';
  }
  if (!infoPlist.NSMotionUsageDescription) {
    pListChanges.NSMotionUsageDescription = 'App requires motion tracking';
  }
  if (!infoPlist.NSLocationWhenInUseUsageDescription) {
    pListChanges.NSLocationWhenInUseUsageDescription = 'App requires background tracking';
  }

  if (Object.keys(pListChanges).length > 0) {
    // only write to plist if there were changes
    Object.assign(infoPlist, pListChanges);
    fs.writeFileSync(infoPlistPath, plist.build(infoPlist));
  }
}

const exec = require('child_process').execSync;

const cliPath = path.join(appDir, 'node_modules', 'react-native', 'local-cli', 'cli.js');
const command = `node ${cliPath} link`;

config.LINK_DEPENDENCIES.forEach((dependency) => {
  console.log('Exec command', command);
  exec(`${command} ${dependency}`);
});
