const COMMON_MODULE_NAME_SUFFIX = 'common';

const path = require('path');

const moduleDir = path.resolve(__dirname, '..');
const modulePkg = require(path.join(moduleDir, 'package.json'));
const moduleName = modulePkg.name.replace('/', '_');
const appDir = path.resolve(moduleDir, '..', '..', '..');
const commonModuleDir = 'common';
const commonModuleName = `${moduleName}-${COMMON_MODULE_NAME_SUFFIX}`;
const settingsGradlePath = path.join(appDir, 'android', 'settings.gradle');

module.exports = {
  appDir,
  moduleDir,
  moduleName,
  commonModuleName,
  commonModuleDir,
  settingsGradlePath
};
module.exports.REQUIRED_BACKGROUND_MODES = ['location'];
module.exports.LINK_DEPENDENCIES = [];
