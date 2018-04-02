const REQUIRED_BACKGROUND_MODES = ['location'];
const LINK_DEPENDENCIES = [];

const path = require('path');
const fs = require('fs-extra');
const plist = require('plist');

const moduleDir = path.resolve(__dirname, '..');
const moduleName = path.basename(moduleDir);
const appDir = path.resolve(moduleDir, '..', '..');

const manifest = require(path.join(appDir, 'package.json'));

const infoPlistPath = path.join(appDir, 'ios', manifest.name, 'Info.plist');
const infoPlistFile = fs.readFileSync(infoPlistPath, 'utf8');
const infoPlist = plist.parse(infoPlistFile);

console.log('Adding UIBackgroundModes into project...');
const bgModes = infoPlist.UIBackgroundModes || [];
REQUIRED_BACKGROUND_MODES.forEach(function(mode) {
  if (bgModes.indexOf(mode) === -1) {
    bgModes.push(mode);
  }
});
infoPlist.UIBackgroundModes = bgModes;

console.log('Adding permissions to Info.plist...');
if (!infoPlist.NSLocationAlwaysUsageDescription) {
  infoPlist.NSLocationAlwaysUsageDescription = 'App requires background tracking';
}
if (!infoPlist.NSLocationAlwaysAndWhenInUseUsageDescription) {
  infoPlist.NSLocationAlwaysAndWhenInUseUsageDescription = 'App requires background tracking';
}
if (!infoPlist.NSMotionUsageDescription) {
  infoPlist.NSMotionUsageDescription = 'App requires motion tracking';
}
if (!infoPlist.NSLocationWhenInUseUsageDescription) {
  infoPlist.NSLocationWhenInUseUsageDescription = 'App requires background tracking';
}
fs.writeFileSync(infoPlistPath, plist.build(infoPlist));

const exec = require('child_process').execSync;

const cliPath = path.join(appDir, 'node_modules', 'react-native', 'local-cli', 'cli.js');
const command = ['node', cliPath, 'link'].join(' ');

LINK_DEPENDENCIES.forEach((dependency) => {
  console.log('Exec command', command);
  exec(`${command} ${dependency}`);
});
