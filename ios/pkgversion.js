// Print latest available package version that matches criteria
// as specified in package.json.
// Inputs are:
// 1. package name as command line parameter

var semver = require('semver');
var exec = require('child_process').exec;
var packages = require('../package.json');

var searchIn = ['dependencies', 'peerDependencies', 'devDependencies'];
var pkgName = process.argv[2];

if (!pkgName) {
  process.stderr.write('Please provide module name\n');
  process.exit(1);
}

var command = 'npm show ' + pkgName + ' versions --json';
var child = exec(command, function (error, stdout, stderr) {
  var version;

  if (error !== null) {
    process.stderr.write('Exec error: ' + error);
    process.exit(1);
  }

  var versions = JSON.parse(stdout);
  for (var i = 0; i < searchIn.length; i++) {
    var pkgSection = packages[searchIn[i]];
    version = pkgSection && pkgSection[pkgName];
    if (version) {
      process.stdout.write(semver.maxSatisfying(versions, version));
      break;
    }
  }
});
