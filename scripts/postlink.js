const COMMON_PROJECT_NAME_SUFFIX = 'common';
const REQUIRED_BACKGROUND_MODES = ['location'];
const LINK_DEPENDENCIES = [];

const path = require('path');
const fs = require('fs-extra');

const moduleDir = path.resolve(__dirname, '..');
const moduleName = path.basename(moduleDir);
const appDir = path.resolve(moduleDir, '..', '..');

const manifest = require(path.join(appDir, 'package.json'));

// Android register common project
// TODO: it would nicer if react-native link has support for multiple projects itself
// Please vote:
// https://react-native.canny.io/feature-requests/p/enable-subprojects-in-native-android-components-to-enable-code-reuse-with-cordov
const applyPatch = require('react-native/local-cli/link/android/patches/applyPatch');
const makeSettingsPatch = require('react-native/local-cli/link/android/patches/makeSettingsPatch');
const projectConfig = { settingsGradlePath: path.join(appDir, 'android', 'settings.gradle') };
applyPatch(
  projectConfig.settingsGradlePath,
  makeSettingsPatch(
    `${moduleName}-${COMMON_PROJECT_NAME_SUFFIX}`,
    { sourceDir: path.join(moduleDir, 'android', 'common') }, projectConfig)
);

// iOS
const plist = require('plist');
const infoPlistPath = path.join(appDir, 'ios', manifest.name, 'Info.plist');
const infoPlistFile = fs.readFileSync(infoPlistPath, 'utf8');
const infoPlist = plist.parse(infoPlistFile);
const pListChanges = {};

const existingBgModes = infoPlist.UIBackgroundModes || [];
const missingBgModes = REQUIRED_BACKGROUND_MODES.filter(function(mode) {
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


const exec = require('child_process').execSync;

const cliPath = path.join(appDir, 'node_modules', 'react-native', 'local-cli', 'cli.js');
const command = `node ${cliPath} link`;

LINK_DEPENDENCIES.forEach((dependency) => {
  console.log('Exec command', command);
  exec(`${command} ${dependency}`);
});
